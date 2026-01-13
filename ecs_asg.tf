data "aws_ami" "ecs" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}

module "ecs_asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "9.1.0"

  name = "${var.project}-${var.env}-ecs-asg"

  min_size         = 1
  max_size         = 4
  desired_capacity = 1

  vpc_zone_identifier = module.vpc.private_subnets

  instance_type = "t3.medium"

  image_id = data.aws_ami.ecs.id

  user_data = base64encode(<<EOF
#!/bin/bash
echo ECS_CLUSTER=${var.project}-${var.env}-cluster >> /etc/ecs/ecs.config
EOF
  )

  iam_instance_profile_name = aws_iam_instance_profile.ecs.name

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project}-${var.env}-ecs-node"
    }
  )
}

resource "aws_iam_role" "ecs_instance" {
  name = "${var.project}-${var.env}-ecs-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_instance" {
  role       = aws_iam_role.ecs_instance.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs" {
  name = "${var.project}-${var.env}-ecs-profile"
  role = aws_iam_role.ecs_instance.name
}
