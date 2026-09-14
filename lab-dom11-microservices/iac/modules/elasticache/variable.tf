variable "project_name" {
  description = "Prefix used to name/tag every resource this module creates."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the cache endpoint."
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group to attach to the cache endpoint."
  type        = string
}

variable "data_storage_max_gb" {
  description = "Upper bound on data storage, in GB."
  type        = number
  default     = 5
}

variable "ecpu_per_second_max" {
  description = "Upper bound on ElastiCache Processing Units per second."
  type        = number
  default     = 5000
}
