module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "7.1.0"

  cluster_name = "${var.project}-${var.env}-cluster"

  cluster_setting = [
    {
      "name"  = "containerInsights",
      "value" = "enabled"
    }
  ]

  # EC2 capacity provider
  capacity_providers = {
    ec2 = {
      auto_scaling_group_provider = {
        auto_scaling_group_arn         = module.ecs_asg.autoscaling_group_arn
        managed_termination_protection = "ENABLED"

        managed_scaling = {
          status                    = "ENABLED"
          target_capacity           = 80
          minimum_scaling_step_size = 1
          maximum_scaling_step_size = 2
        }
      }
    }
  }

  default_capacity_provider_strategy = {
    ec2 = {
      weight = 1
    }
  }

  tags = local.common_tags
}

