#resource "aws_cloudwatch_log_group" "ecs_logs" {
#  name = "/ecs/${var.project}/${var.env}/${var.app_name}"
#  retention_in_days = 30
#  tags = local.common_tags
#}
#
#output "ecs_logs_arn" {
#value = aws_cloudwatch_log_group.ecs_logs.arn
#}
#
#output "ecs_log_group_name" {
#  value = aws_cloudwatch_log_group.ecs_logs.name
#}
