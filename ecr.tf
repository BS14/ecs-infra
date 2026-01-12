module "ecr" {
  source          = "terraform-aws-modules/ecr/aws"
  version         = "3.2.0"
  repository_name = "${var.app_name}-ecr"
  repository_type = "private"
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 30 images",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["v"],
          countType     = "imageCountMoreThan",
          countNumber   = 30
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
  tags = local.common_tags
}
