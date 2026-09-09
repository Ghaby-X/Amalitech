variable "project_name" {
  description = "Prefix used to name/tag every resource this module creates."
  type        = string
}

variable "vpc_id" {
  description = "VPC these security groups belong to."
  type        = string
}
