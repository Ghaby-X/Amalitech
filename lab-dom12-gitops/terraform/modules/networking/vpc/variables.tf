variable "name" {
  description = "Name prefix applied to all resources."
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "azs" {
  description = "Availability zones, one per subnet CIDR in each of the subnet lists (same order)."
  type        = list(string)
}

variable "public_subnet_cidr_blocks" {
  description = "CIDR block for each public subnet, one per AZ."
  type        = list(string)
}

variable "private_subnet_cidr_blocks" {
  description = "CIDR block for each private subnet, one per AZ."
  type        = list(string)
}

variable "flow_logs_log_group_name" {
  description = "CloudWatch Logs group VPC flow logs are delivered to."
  type        = string
}

variable "flow_logs_traffic_type" {
  description = "Traffic captured by the flow log: ACCEPT, REJECT or ALL."
  type        = string
  default     = "ALL"
}

variable "flow_logs_retention_days" {
  description = "Retention for the flow logs log group."
  type        = number
  default     = 14
}

variable "kms_key_arn" {
  description = "KMS key encrypting the flow logs log group. Its key policy must allow the CloudWatch Logs service principal."
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}
