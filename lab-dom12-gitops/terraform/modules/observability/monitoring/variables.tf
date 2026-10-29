variable "name_prefix" {
  description = "Prefix for alarm, topic, rule and dashboard names."
  type        = string
}

variable "account_id" {
  description = "AWS account ID - scopes the SNS topic policy to alarms from this account."
  type        = string
}

variable "alb_arn_suffix" {
  description = "ARN suffix of the load balancer (the LoadBalancer metric dimension)."
  type        = string
}

variable "target_group_arn_suffix" {
  description = "ARN suffix of the app target group (the TargetGroup metric dimension)."
  type        = string
}

variable "cluster_name" {
  description = "Name of the ECS cluster."
  type        = string
}

variable "service_name" {
  description = "Name of the ECS service."
  type        = string
}

variable "service_arn" {
  description = "ARN of the ECS service - filters deployment events to this service only."
  type        = string
}

variable "app_log_group_name" {
  description = "CloudWatch Logs group the app container writes its JSON access log to."
  type        = string
}

variable "metric_namespace" {
  description = "CloudWatch namespace for metrics derived from the app's logs."
  type        = string
}

variable "alarm_email" {
  description = "Email address subscribed to alarm and deployment notifications. Null for none. The subscription must be confirmed from the inbox."
  type        = string
  default     = null
}

variable "error_rate_threshold_percent" {
  description = "HighErrorRate alarm threshold - percentage of requests returning 5xx."
  type        = number
  default     = 5
}

variable "cpu_threshold_percent" {
  description = "CPU alarm threshold (percent)."
  type        = number
  default     = 80
}

variable "memory_threshold_percent" {
  description = "Memory alarm threshold (percent)."
  type        = number
  default     = 80
}

variable "app_5xx_log_threshold" {
  description = "Number of logged 5xx responses within 5 minutes that triggers the log-based alarm."
  type        = number
  default     = 10
}

variable "log_retention_days" {
  description = "Retention for the deployment events log group."
  type        = number
  default     = 14
}

variable "kms_key_arn" {
  description = "Customer-managed KMS key for the SNS topic and the deployment events log group. Its key policy must let cloudwatch.amazonaws.com and events.amazonaws.com generate data keys, and the CloudWatch Logs service principal use it."
  type        = string
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}
