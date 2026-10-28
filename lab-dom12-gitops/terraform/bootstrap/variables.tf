variable "region" {
  type        = string
  default     = "eu-west-1"
  description = "AWS region for the state bucket"
}

variable "bucket_prefix" {
  type        = string
  default     = "lab-dom12-tfstate"
  description = "Prefix for the state bucket name (suffixed with account ID and region) and the KMS key alias"
}

variable "noncurrent_versions_to_keep" {
  type        = number
  default     = 5
  description = "Previous state versions kept per object for recovery"
}

variable "noncurrent_version_retention_days" {
  type        = number
  default     = 30
  description = "Days before previous state versions beyond noncurrent_versions_to_keep are deleted"
}
