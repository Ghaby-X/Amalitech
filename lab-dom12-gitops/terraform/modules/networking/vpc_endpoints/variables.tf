variable "name" {
  description = "Name prefix applied to all resources."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC."
  type        = string
}

variable "subnet_ids" {
  description = "Subnets the interface endpoints get an ENI in - one per AZ the clients run in."
  type        = list(string)
}

variable "gateway_route_table_ids" {
  description = "Route tables the S3 gateway endpoint is added to."
  type        = list(string)
}

variable "s3_read_bucket_arns" {
  description = "Buckets workloads may read objects from through the S3 gateway endpoint. Everything else is denied by the endpoint policy."
  type        = list(string)

  validation {
    condition     = length(var.s3_read_bucket_arns) > 0
    error_message = "List at least one bucket - an empty list would block all S3 access, including ECR image layers."
  }
}

variable "interface_services" {
  description = "Service name suffixes (after com.amazonaws.<region>.) to create interface endpoints for."
  type        = list(string)
  default     = ["ecr.api", "ecr.dkr", "logs"]
}

variable "security_group_ids" {
  description = "Security groups attached to the interface endpoints' ENIs - they must allow HTTPS in from the clients."
  type        = list(string)
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}
