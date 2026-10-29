variable "region" {
  type        = string
  default     = "eu-west-1"
  description = "AWS region"
}

variable "environment" {
  type        = string
  default     = "sandbox"
  description = "Environment name - prefixes resource names and matches the GitHub environment the deploy job runs in"
}

# Networking
variable "vpc_cidr_block" {
  type    = string
  default = "10.12.0.0/16"
}

variable "public_subnet_cidr_blocks" {
  type        = list(string)
  default     = ["10.12.0.0/24", "10.12.1.0/24"]
  description = "Public subnets (ALB, NAT gateway), one per AZ - the ALB needs at least two AZs"
}

variable "private_subnet_cidr_blocks" {
  type        = list(string)
  default     = ["10.12.10.0/24", "10.12.11.0/24"]
  description = "Private subnets for the Fargate tasks, one per AZ"
}

variable "alb_ingress_cidr" {
  type        = string
  default     = "0.0.0.0/0"
  description = "CIDR allowed to reach the app through the ALB"
}

# App / ECS
variable "app_port" {
  type        = number
  default     = 3000
  description = "Port the app container listens on"
}

variable "health_check_path" {
  type        = string
  default     = "/api/server-info"
  description = "Path used by the ALB target group and container health checks"
}

variable "task_cpu" {
  type        = number
  default     = 256
  description = "Fargate task CPU units"
}

variable "task_memory" {
  type        = number
  default     = 512
  description = "Fargate task memory (MiB)"
}

variable "ecr_keep_image_count" {
  type        = number
  default     = 10
  description = "Images the ECR lifecycle policy keeps"
}

variable "log_retention_days" {
  type        = number
  default     = 14
  description = "Retention for the app and deployment-event log groups"
}

# Monitoring
variable "alarm_email" {
  type        = string
  default     = null
  description = "Email subscribed to alarm and deployment notifications (confirm the subscription from the inbox). Null for none."
}

# CI
variable "github_repository" {
  type        = string
  default     = "Ghaby-X/Amalitech"
  description = "GitHub repository (owner/name) whose Actions workflow deploys this stack"
}
