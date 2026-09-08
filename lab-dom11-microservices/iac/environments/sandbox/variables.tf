variable "region" {
  description = "AWS region for this environment."
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Prefix used to name/tag every resource in this environment."
  type        = string
  default     = "lab-dom11-shopnow"
}
