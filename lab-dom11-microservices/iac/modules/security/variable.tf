variable "project_name" {
  description = "Prefix used to name/tag every resource this module creates."
  type        = string
}

variable "vpc_id" {
  description = "VPC these security groups belong to."
  type        = string
}

variable "eks_cluster_security_group_id" {
  description = "EKS cluster's auto-created security group, granted ingress to postgres/redis."
  type        = string
}
