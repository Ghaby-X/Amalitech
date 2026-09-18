variable "project_name" {
  description = "Prefix used to name/tag every resource this module creates."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs, passed to the cluster's vpc_config alongside the private ones."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs, used for both the cluster's vpc_config and the node group."
  type        = list(string)
}

variable "node_instance_types" {
  description = "Instance types for the managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Desired number of worker nodes."
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes."
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of worker nodes."
  type        = number
  default     = 3
}
