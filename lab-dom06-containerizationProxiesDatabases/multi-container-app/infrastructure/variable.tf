variable "region" {
  type        = string
  default     = "eu-west-1"
  description = "AWS region"
}

# VPC configuration
variable "vpc_cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

variable "vpc_name" {
  type    = string
  default = "lab-dom06-vpc"
}

# Subnet configuration
variable "subnet_cidr_block" {
  type    = string
  default = "10.0.1.0/24"
}

variable "subnet_name" {
  type    = string
  default = "lab-dom06-public-subnet"
}

# Route table configuration
variable "rt_name" {
  type    = string
  default = "lab-dom06-rt"
}

variable "rt_association_ipv4_igw_cidr_block" {
  type    = string
  default = "0.0.0.0/0"
}

# Security group configuration
variable "sg_name" {
  type    = string
  default = "lab-dom06-sg"
}

variable "ssh_allowed_cidr" {
  type        = string
  description = "CIDR allowed to SSH into the instance on port 22"
}

variable "app_port" {
  type        = number
  default     = 80
  description = "Port nginx listens on externally - proxies internally to the app; the app's own port is never exposed to the security group"
}

variable "app_allowed_cidr" {
  type        = string
  default     = "0.0.0.0/0"
  description = "CIDR allowed to reach nginx on app_port"
}

# EC2 instance configuration
variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "EC2 instance type - org SCP (LimitEC2InstanceTypes) only allows t3.micro/small/medium, t2.* is denied"
}

variable "instance_name" {
  type    = string
  default = "lab-dom06-web"
}

# Secrets Manager configuration
variable "secret_name" {
  type        = string
  default     = "lab-dom06/db-credentials"
  description = "Name of the Secrets Manager secret holding DB credentials"
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "db_user" {
  type    = string
  default = "appuser"
}
