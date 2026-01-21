# ==========================================
# 1. ACM Certificate (Manual Validation)
# ==========================================

resource "aws_acm_certificate" "ca_demo_cert" {
  domain_name       = "ca-demo.binaya14.com.np"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# This resource will PAUSE Terraform execution until you add the records in Cloudflare
resource "aws_acm_certificate_validation" "ca_demo_cert" {
  certificate_arn = aws_acm_certificate.ca_demo_cert.arn
}

# ==========================================
# 2. ALB & Listener (Same as before)
# ==========================================

#resource "aws_security_group" "alb_sg" {
#  name        = "${var.project}-alb-sg"
#  description = "Controls access to the Application Load Balancer"
#  vpc_id      = aws_vpc.main.id
#
#  # Inbound: Allow HTTP (80) from anywhere (for redirection)
#  ingress {
#    protocol    = "tcp"
#    from_port   = 80
#    to_port     = 80
#    cidr_blocks = ["0.0.0.0/0"]
#    description = "Allow HTTP traffic from internet"
#  }
#
#  # Inbound: Allow HTTPS (443) from anywhere (actual traffic)
#  ingress {
#    protocol    = "tcp"
#    from_port   = 443
#    to_port     = 443
#    cidr_blocks = ["0.0.0.0/0"]
#    description = "Allow HTTPS traffic from internet"
#  }
#
#  # Outbound: Allow ALB to talk to anything (ECS Nodes)
#  egress {
#    protocol    = "-1"
#    from_port   = 0
#    to_port     = 0
#    cidr_blocks = ["0.0.0.0/0"]
#  }
#
#  tags = {
#    Name = "${var.project}-alb-sg"
#  }
#}
#
## Add Security Rule to Node Security Group
##resource "aws_security_group_rule" "allow_alb_to_nodes" {
##  type        = "ingress"
##  description = "Allow traffic from ALB only"
##  from_port   = 3000 # Your container port
##  to_port     = 3000 # Your container port
##  protocol    = "tcp"
##
##  # The Target SG (Your ECS Nodes)
##  security_group_id = aws_security_group.ecs_nodes.id
##
##  # The Source SG (Only traffic coming FROM the ALB is allowed)
##  source_security_group_id = aws_security_group.alb_sg.id
##}
#
#resource "aws_lb" "main" {
#  name               = "${var.project}-alb"
#  internal           = false
#  load_balancer_type = "application"
#  security_groups    = [aws_security_group.alb_sg.id]
#  subnets            = aws_subnet.public[*].id
#}
#
## HTTP Redirect Listener
#resource "aws_lb_listener" "http" {
#  load_balancer_arn = aws_lb.main.arn
#  port              = "80"
#  protocol          = "HTTP"
#
#  default_action {
#    type = "redirect"
#    redirect {
#      port        = "443"
#      protocol    = "HTTPS"
#      status_code = "HTTP_301"
#    }
#  }
#}
#
## HTTPS Listener
#resource "aws_lb_listener" "https" {
#  load_balancer_arn = aws_lb.main.arn
#  port              = "443"
#  protocol          = "HTTPS"
#  ssl_policy        = "ELBSecurityPolicy-2016-08"
#  certificate_arn   = aws_acm_certificate_validation.ca_demo_cert.certificate_arn
#
#  default_action {
#    type = "fixed-response"
#    fixed_response {
#      content_type = "text/plain"
#      message_body = "Not Found"
#      status_code  = "404"
#    }
#  }
#}
#
## ==========================================
## 3. Target Group & Routing
## ==========================================
#
#resource "aws_lb_target_group" "nextjs" {
#  name        = "${var.app_name}-tg"
#  port        = 3000
#  protocol    = "HTTP"
#  vpc_id      = aws_vpc.main.id
#  target_type = "ip"
#
#  health_check {
#    path    = "/health"
#    matcher = "200"
#  }
#}
#
#resource "aws_lb_listener_rule" "nextjs" {
#  listener_arn = aws_lb_listener.https.arn
#  priority     = 100
#
#  action {
#    type             = "forward"
#    target_group_arn = aws_lb_target_group.nextjs.arn
#  }
#
#  condition {
#    host_header {
#      values = ["ca-demo.binaya14.com.np"]
#    }
#  }
#}
#
## ==========================================
## 4. Outputs (Essential for Cloudflare)
## ==========================================
#
#output "alb_dns_name" {
#  description = "Add this as a CNAME record in Cloudflare for 'ca-demo'"
#  value       = aws_lb.main.dns_name
#}
