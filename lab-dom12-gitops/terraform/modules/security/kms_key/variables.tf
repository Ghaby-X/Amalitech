variable "alias" {
  description = "Alias for the key, without the \"alias/\" prefix."
  type        = string
}

variable "description" {
  description = "Description of the key."
  type        = string
}

variable "deletion_window_in_days" {
  description = "Days a key scheduled for deletion stays recoverable (7-30). Data encrypted with it is unreadable once it is gone, so longer is safer for keys protecting state."
  type        = number
  default     = 30
}

variable "allow_cloudwatch_logs" {
  description = "Let CloudWatch Logs use the key to encrypt log groups in this account and region."
  type        = bool
  default     = false
}

variable "sns_publisher_service_principals" {
  description = "Service principals allowed to publish to SNS topics encrypted with this key, e.g. cloudwatch.amazonaws.com, events.amazonaws.com."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}
