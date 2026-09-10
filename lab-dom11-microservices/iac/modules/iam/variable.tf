variable "project_name" {
  description = "Prefix used to name/tag every resource this module creates."
  type        = string
}

variable "ssm_parameter_arns" {
  description = "SSM SecureString parameter ARNs the execution role needs read access to (from the secrets module)"
  type        = list(string)
  default     = []
}
