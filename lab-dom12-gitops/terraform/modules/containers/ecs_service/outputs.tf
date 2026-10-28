output "cluster_name" {
  description = "Name of the ECS cluster."
  value       = aws_ecs_cluster.this.name
}

output "cluster_arn" {
  description = "ARN of the ECS cluster."
  value       = aws_ecs_cluster.this.arn
}

output "service_name" {
  description = "Name of the ECS service."
  value       = aws_ecs_service.this.name
}

output "service_arn" {
  description = "ARN of the ECS service."
  value       = aws_ecs_service.this.id
}

output "task_family" {
  description = "Task definition family."
  value       = aws_ecs_task_definition.initial.family
}

output "task_definition_arn_prefix" {
  description = "Task definition ARN without the revision - for IAM policies covering every revision of the family."
  value       = trimsuffix(aws_ecs_task_definition.initial.arn_without_revision, ":")
}

output "container_name" {
  description = "Name of the app container."
  value       = var.container_name
}

output "container_port" {
  description = "Port the app container listens on."
  value       = var.container_port
}

output "execution_role_arn" {
  description = "ARN of the task execution role."
  value       = aws_iam_role.execution.arn
}

output "task_role_arn" {
  description = "ARN of the task role."
  value       = aws_iam_role.task.arn
}

output "log_group_name" {
  description = "Name of the container log group."
  value       = aws_cloudwatch_log_group.app.name
}

output "log_group_arn" {
  description = "ARN of the container log group."
  value       = aws_cloudwatch_log_group.app.arn
}
