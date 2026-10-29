variable "name" {
  description = "Name of the load balancer (max 28 characters, so the \"-tg\" target group name fits AWS's 32-character limit)."
  type        = string

  validation {
    condition     = length(var.name) <= 28
    error_message = "name must be 28 characters or fewer."
  }
}

variable "vpc_id" {
  description = "ID of the VPC the target group lives in."
  type        = string
}

variable "subnet_ids" {
  description = "Public subnet IDs for the load balancer - at least two, in different AZs."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security groups attached to the load balancer."
  type        = list(string)
}

variable "target_port" {
  description = "Port the targets (containers) listen on."
  type        = number
}

variable "health_check_path" {
  description = "Path the target group health check requests."
  type        = string
}

variable "deregistration_delay" {
  description = "Seconds to drain in-flight requests from a deregistering target."
  type        = number
  default     = 30
}

variable "enable_deletion_protection" {
  description = "Prevent the load balancer from being deleted."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}
