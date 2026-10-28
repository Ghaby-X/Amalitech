variable "cluster_name" {
  description = "Name of the ECS cluster."
  type        = string
}

variable "service_name" {
  description = "Name of the ECS service. Also prefixes the IAM role names."
  type        = string
}

variable "task_family" {
  description = "Task definition family. The pipeline registers new revisions under this same family."
  type        = string
}

variable "container_name" {
  description = "Name of the app container in the task definition (referenced by the load balancer)."
  type        = string
}

variable "container_port" {
  description = "Port the app container listens on."
  type        = number
}

variable "health_check_path" {
  description = "Path the container health check requests."
  type        = string
}

variable "task_cpu" {
  description = "Fargate task CPU units (256 = 0.25 vCPU)."
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Fargate task memory in MiB."
  type        = number
  default     = 512
}

variable "ecr_repository_url" {
  description = "URL of the ECR repository the app image is pulled from."
  type        = string
}

variable "ecr_repository_arn" {
  description = "ARN of the ECR repository - scopes the execution role's pull permissions."
  type        = string
}

variable "initial_image_tag" {
  description = "Image tag in the initial placeholder task definition. Never actually run, since the service starts at initial_desired_count."
  type        = string
  default     = "initial"
}

variable "initial_desired_count" {
  description = "Task count the service is created with. 0 because ECR is empty until the first pipeline run; the pipeline sets the real count on deploy."
  type        = number
  default     = 0
}

variable "subnet_ids" {
  description = "Private subnets the tasks run in. Tasks get no public IP, so these need a NAT gateway route to reach ECR and CloudWatch Logs."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security groups attached to each task's ENI."
  type        = list(string)
}

variable "deployment_alarm_names" {
  description = "CloudWatch alarms ECS watches during a deployment - if any goes into ALARM, the deployment is rolled back. Passed as names (not references) so the alarms can depend on this service without a cycle."
  type        = list(string)
  default     = []
}

variable "target_group_arn" {
  description = "Load balancer target group the service registers tasks with."
  type        = string
}

variable "log_group_name" {
  description = "CloudWatch Logs group for the container's logs."
  type        = string
}

variable "log_retention_days" {
  description = "Retention for the container log group."
  type        = number
  default     = 14
}

variable "kms_key_arn" {
  description = "Customer-managed KMS key encrypting the container log group. Its key policy must allow the CloudWatch Logs service principal."
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}
