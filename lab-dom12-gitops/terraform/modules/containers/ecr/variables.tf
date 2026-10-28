variable "name" {
  description = "Name of the ECR repository."
  type        = string
}

variable "keep_image_count" {
  description = "Number of most recent images the lifecycle policy keeps; older ones are expired."
  type        = number
  default     = 10
}

variable "untagged_expiry_days" {
  description = "Days after which untagged images are expired."
  type        = number
  default     = 1
}

variable "force_delete" {
  description = "Allow the repository to be destroyed while it still contains images."
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "Customer-managed KMS key encrypting the repository's images. Null uses the AWS-managed aws/ecr key. Changing it replaces the repository."
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}
