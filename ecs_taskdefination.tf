module "ecs_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "7.1.0"

  name        = "${var.app_name}-service"
  cluster_arn = module.ecs.cluster_arn

  # Initial desired tasks
  desired_count = 2

  # EC2 capacity provider (ASG-backed)
  capacity_provider_strategy = {
    ec2 = {
      weight = 1
    }
  }

  # Task-level resources
  cpu    = 512
  memory = 1024

  # --- Task Definition (bootstrap only) ---
  container_definitions = {
    nextjs = {
      image     = "${module.ecr.repository_url}:latest"
      cpu       = 512
      memory    = 1024
      essential = true

      portMappings = [
        {
          containerPort = 3000
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "NODE_ENV"
          value = "production"
        }
      ]

      enable_cloudwatch_logging = true
    }
  }

  # Networking (awsvpc mode)
  subnet_ids = module.vpc.private_subnets

  security_group_ingress_rules = {
    alb = {
      from_port                    = 3000
      to_port                      = 3000
      ip_protocol                  = "tcp"
      referenced_security_group_id = aws_security_group.alb.id
    }
  }

  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  tags                           = local.common_tags
  ignore_task_definition_changes = true
}

