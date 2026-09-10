variable "project_name" {
  description = "Prefix used to name/tag every resource this module creates."
  type        = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  description = "Where the ALB lives."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Where every task (postgres/redis/backend/frontend) lives - none of them are public-facing directly."
  type        = list(string)
}

variable "alb_security_group_id" {
  type = string
}

variable "frontend_security_group_id" {
  type = string
}

variable "backend_security_group_id" {
  type = string
}

variable "postgres_security_group_id" {
  type = string
}

variable "redis_security_group_id" {
  type = string
}

variable "log_retention_days" {
  type    = number
  default = 7
}
