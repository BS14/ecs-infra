data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# The GitHub OIDC Provider
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"] # Standard GitHub thumbprint
}

# 1. The Trust Policy
data "aws_iam_policy_document" "github_allow" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      # IMPORTANT: Replace with your actual Org/Repo name
      values = ["repo:BS14/nextjs-ecs:*"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

# 2. The Role
resource "aws_iam_role" "github_actions_role" {
  name               = "github-actions-ecs-deployer"
  assume_role_policy = data.aws_iam_policy_document.github_allow.json
}

resource "aws_iam_role_policy" "ecs_deploy_policy" {
  name = "ecs-deploy-permissions"
  role = aws_iam_role.github_actions_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken" # This one must be "*" as it's a global call
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = [aws_ecr_repository.ecr.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices",
          "ecs:DescribeTasks"
        ]
        Resource = [
          "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:service/${aws_ecs_cluster.main.name}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:RegisterTaskDefinition",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeClusters",
          "ecs:CreateService",
          "ecs:TagResource",
          "ecs:ListServiceDeployments",
          "ecs:DescribeServiceDeployments"
        ]
      Resource = ["*"] },
      {
        Effect = "Allow"
        Action = "iam:PassRole"
        Resource = [
          aws_iam_role.ecs_task_execution_role.arn,
          aws_iam_role.ecs_task_role.arn
        ]
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "ecs-tasks.amazonaws.com"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "application-autoscaling:RegisterScalableTarget",
          "application-autoscaling:PutScalingPolicy",
          "application-autoscaling:DescribeScalableTargets"
        ]
        Resource = "*"

      },
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket", "s3:GetObject"]
        Resource = ["arn:aws:s3:::tf-state-ecs-demo-bucket", "arn:aws:s3:::tf-state-ecs-demo-bucket/*"]
      },
      {
        Sid    = "AllowEcspressoVerifyLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = [
          "${aws_cloudwatch_log_group.ecs_logs.arn}:*"
        ]
      },
      {
        Sid      = "AllowCreateSLR"
        Effect   = "Allow"
        Action   = "iam:CreateServiceLinkedRole"
        Resource = "arn:aws:iam::*:role/aws-service-role/ecs.application-autoscaling.amazonaws.com/AWSServiceRoleForApplicationAutoScaling_ECSService"
        Condition = {
          StringLike = {
            "iam:AWSServiceName" : "ecs.application-autoscaling.amazonaws.com"
          }
        }
      }
    ]
  })
}
