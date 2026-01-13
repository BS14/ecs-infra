# 1. OIDC Provider (Standard)
module "iam_github_oidc_provider" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-provider"
  version = "6.3.0"
  tags    = local.common_tags
}

# 2. OIDC Role (Standard)
module "iam_github_oidc_role" {
  source   = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  version  = "5.39.0"
  name     = "${var.project}-github-actions-role"
  subjects = ["BS14/nextjs-ecs:*"] # specific repo only

  policies = {
    GithubDeployPolicy = aws_iam_policy.github_deploy.arn
  }
  tags = local.common_tags
}

resource "aws_iam_policy" "github_deploy" {
  name        = "${var.project}-github-deploy-policy"
  description = "Scoped policy for GitHub Actions to push to specific ECR and update specific ECS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "GetAuthorizationToken"
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*" 
      },
      {
        Sid    = "AllowPushToSpecificRepo"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = module.ecr.repository_arn
      },
      {
        Sid    = "RegisterTaskDefinition"
        Effect = "Allow"
        Action = [
          "ecs:RegisterTaskDefinition",
          "ecs:DescribeTaskDefinition"
        ]
        Resource = "*" 
      },
      {
        Sid    = "UpdateSpecificService"
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices"
        ]
        Resource = [
          "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:service/${module.ecs.cluster_name}/${var.app_name}-service"
        ]
      },
      {
        Sid    = "PassRoleToECS"
        Effect = "Allow"
        Action = "iam:PassRole"
        Resource = [
module.ecs_service.task_exec_iam_role_arn,
module.ecs_service.tasks_iam_role_arn
        ]
        Condition = {
          StringLike = {
            "iam:PassedToService": "ecs-tasks.amazonaws.com"
          }
        }
      }
    ]
  })
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
