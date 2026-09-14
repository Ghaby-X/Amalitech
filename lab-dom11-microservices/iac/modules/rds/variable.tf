variable "project_name" {
  description = "Prefix used to name/tag every resource this module creates."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the DB subnet group."
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group to attach to the instance."
  type        = string
}

variable "master_username" {
  description = "Master username."
  type        = string
  default     = "shopnow"
}

variable "master_password" {
  description = "Master password."
  type        = string
  sensitive   = true
}

variable "database_name" {
  description = "Initial database created at launch."
  type        = string
  default     = "shopnow"
}

variable "instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage, in GiB."
  type        = number
  default     = 20
}

variable "engine_version" {
  description = "Postgres major version - minor version floats with auto_minor_version_upgrade."
  type        = string
  default     = "16"
}
