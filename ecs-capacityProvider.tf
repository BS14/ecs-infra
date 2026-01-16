# Instance Profile
resource "aws_iam_role" "ecs_node_role" {
  name = "${var.project}-${var.env}-ecs-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# Attach ECS Worker Policy
resource "aws_iam_role_policy_attachment" "ecs_node_role_policy" {
  role       = aws_iam_role.ecs_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# Attach SSM Policy
resource "aws_iam_role_policy_attachment" "ssm_core_policy" {
  role       = aws_iam_role.ecs_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ecs_node_profile" {
  name = "${var.project}-${var.env}-ecs-node-profile"
  role = aws_iam_role.ecs_node_role.name
}

# Security Group for EC2 Nodes
resource "aws_security_group" "ecs_nodes" {
  name        = "${var.project}-${var.env}-ecs-nodes-sg"
  description = "Security group for ECS EC2 instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow internal VPC traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.cidr]
  }

  # Egress: Allow all outbound (needed for pulling Docker images)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

# 3. Launch Template
# Fetch the latest Amazon Linux 2 ECS Optimized AMI
data "aws_ssm_parameter" "ecs_optimized_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

resource "aws_launch_template" "ecs_lt" {
  name   = "${var.project}-${var.env}-ecs-lt"
  image_id      = data.aws_ssm_parameter.ecs_optimized_ami.value
  instance_type = "t3.medium"

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_node_profile.name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.ecs_nodes.id]
  }

  # User Data: This registers the instance to YOUR specific ECS cluster
  user_data = base64encode(<<-EOF
              #!/bin/bash
              echo "ECS_CLUSTER=${aws_ecs_cluster.main.name}" >> /etc/ecs/ecs.config
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name = "${var.project}-${var.env}-ecs-node"
    })
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "ecs_asg" {
  name                = "${var.project}-${var.env}-ecs-asg"
  vpc_zone_identifier = aws_subnet.private[*].id
  
  min_size            = 0
  max_size            = 5
  desired_capacity    = 0 

  launch_template {
    id      = aws_launch_template.ecs_lt.id
    version = "$Latest"
  }

  protect_from_scale_in = true 

  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }
  
  lifecycle {
    ignore_changes = [desired_capacity]
  }
}

# Capacity Provider
resource "aws_ecs_capacity_provider" "main" {
  name = "${var.project}-${var.env}-cp"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecs_asg.arn

    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 90
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 5
    }

    managed_termination_protection = "ENABLED"
  }
}

# Attach Provider to Cluster
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = [aws_ecs_capacity_provider.main.name]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = aws_ecs_capacity_provider.main.name
  }
}
