variable "name" {
  description = "Name of the IAM role."
  type        = string
}

variable "github_repository" {
  description = "GitHub repository allowed to assume the role, as owner/name."
  type        = string
}

variable "github_environments" {
  description = "GitHub environments whose jobs may assume the role. The workflow's deploy job must declare one of these with `environment:`."
  type        = list(string)
}

variable "region" {
  description = "AWS region the ECS cluster is in."
  type        = string
}

variable "account_id" {
  description = "AWS account ID."
  type        = string
}

variable "ecr_repository_arn" {
  description = "ARN of the ECR repository the pipeline pushes to."
  type        = string
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster."
  type        = string
}

variable "ecs_cluster_arn" {
  description = "ARN of the ECS cluster."
  type        = string
}

variable "ecs_service_arn" {
  description = "ARN of the ECS service the pipeline deploys."
  type        = string
}

variable "pass_role_arns" {
  description = "Task execution and task role ARNs the pipeline's task definitions reference."
  type        = list(string)
}

variable "app_log_group_arn" {
  description = "ARN of the app's CloudWatch Logs group."
  type        = string
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}
