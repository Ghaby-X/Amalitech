variable "project_name" {
  description = "Prefix used to name/tag every resource this module creates."
  type        = string
}

variable "private_subnet_ids" {
  description = "One mount target gets created per subnet here - matches the private subnets from the networking module."
  type        = list(string)
}

variable "efs_security_group_id" {
  description = "Security group to attach to the mount targets (allows NFS from the postgres task only - see the security module)."
  type        = string
}
