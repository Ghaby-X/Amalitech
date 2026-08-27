variable "region" {
  type        = string
  default     = "eu-west-1"
  description = "AWS region"
}

# VPC configuration
variable "vpc_cidr_block" {
  type    = string
  default = "10.1.0.0/16"
}

variable "vpc_name" {
  type    = string
  default = "lab-dom08-vpc"
}

# Subnet configuration
variable "subnet_cidr_block" {
  type    = string
  default = "10.1.1.0/24"
}

variable "subnet_name" {
  type    = string
  default = "lab-dom08-public-subnet"
}

# Route table configuration
variable "rt_name" {
  type    = string
  default = "lab-dom08-rt"
}

# Security group configuration
#
# SSH does not take a CIDR at all: both instances only accept port 22 from
# the EC2 Instance Connect Endpoint's security group (see
# instance_connect.tf), so no personal IP is ever opened for SSH. Connect
# with `aws ec2-instance-connect ssh --instance-id <id>` - see README.

variable "admin_allowed_cidr" {
  type        = string
  description = "CIDR allowed to reach the Prometheus (9090) and Grafana (3001) UIs"
}

variable "app_port" {
  type        = number
  default     = 3000
  description = "Port the app listens on"
}

variable "app_allowed_cidr" {
  type        = string
  default     = "0.0.0.0/0"
  description = "CIDR allowed to reach the app directly on app_port, for verifying accessibility"
}

variable "node_exporter_port" {
  type        = number
  default     = 9100
  description = "Port Node Exporter listens on"
}

# EC2 instance configuration
variable "app_instance_type" {
  type        = string
  default     = "t3.micro"
  description = "Instance type for the app host - runs the app container and Node Exporter"
}

variable "monitoring_instance_type" {
  type        = string
  default     = "t3.small"
  description = "Instance type for the monitoring host - runs Prometheus and Grafana"
}

variable "app_instance_name" {
  type    = string
  default = "lab-dom08-app"
}

variable "monitoring_instance_name" {
  type    = string
  default = "lab-dom08-monitoring"
}

# App deployment
variable "app_repo_url" {
  type        = string
  default     = "https://github.com/Ghaby-X/server_details.git"
  description = "Git repository the app instance clones and builds"
}

variable "app_repo_ref" {
  type        = string
  default     = "feature/prometheus-metrics"
  description = "Branch/tag/commit to build - must include the /metrics endpoint. Switch to main once that branch is merged."
}

# CloudWatch Logs
variable "app_log_group_name" {
  type        = string
  default     = "/lab-dom08/app"
  description = "CloudWatch Logs group the app container's logs are streamed to"
}

variable "log_retention_days" {
  type        = number
  default     = 14
  description = "Retention for the app CloudWatch Logs group"
}

# CloudTrail / S3
variable "cloudtrail_log_retention_days" {
  type        = number
  default     = 14
  description = "Retention for the CloudTrail CloudWatch Logs group"
}

variable "cloudtrail_transition_ia_days" {
  type        = number
  default     = 30
  description = "Days before CloudTrail log objects transition to STANDARD_IA"
}

variable "cloudtrail_transition_glacier_days" {
  type        = number
  default     = 90
  description = "Days before CloudTrail log objects transition to GLACIER"
}

variable "cloudtrail_expiration_days" {
  type        = number
  default     = 365
  description = "Days before CloudTrail log objects are permanently deleted"
}

# GuardDuty
variable "enable_guardduty" {
  type        = bool
  default     = true
  description = "Whether to create a GuardDuty detector. Set false if one already exists in this account/region - only one detector is allowed per account per region."
}
