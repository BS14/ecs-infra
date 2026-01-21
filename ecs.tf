#resource "aws_ecs_cluster" "main" {
#  name = "${var.project}-${var.env}-cluster"
#
#  setting {
#    name  = "containerInsights"
#    value = "enabled"
#  }
#
#  tags = local.common_tags
#}
