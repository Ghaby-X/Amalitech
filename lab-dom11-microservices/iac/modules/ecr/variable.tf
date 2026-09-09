variable "project_name" {
  description = "Prefix used to name/tag every resource this module creates."
  type        = string
}

variable "repository_names" {
  description = "Names of the ECR repositories to create - one per custom-built image (postgres/redis pull straight from Docker Hub, so they don't need one)."
  type        = list(string)
  default     = ["backend", "frontend"]
}

variable "untagged_image_expiry_days" {
  description = "Untagged images older than this get expired by the lifecycle policy - keeps the registry from accumulating orphaned layers from every build."
  type        = number
  default     = 3
}

variable "max_tagged_images" {
  description = "How many tagged images to keep per repository, newest first - older ones get expired."
  type        = number
  default     = 3
}
