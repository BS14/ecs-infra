#output "cluster_name" {
#  value = aws_ecs_cluster.main.name
#}
#
#output "service_security_group_id" {
#  value = aws_security_group.ecs_nodes.id
#}
#
#output "private_subnet_ids" {
#  value = aws_subnet.private[*].id
#}
#
#output "execution_role_arn" {
#  value = aws_iam_role.ecs_task_execution_role.arn
#}
#
#output "task_role_arn" {
#  value = aws_iam_role.ecs_task_role.arn
#}
#
#output "capacity_provider_name" {
#  value = aws_ecs_capacity_provider.main.name
#}
#
#output "ecr_nextjs" {
#  value = aws_ecr_repository.ecr.repository_url
#}
#
#
