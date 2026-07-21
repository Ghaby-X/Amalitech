variable "region" {
  type        = string
  default     = "eu-west-1"
  description = "default region for deploying aws resource"
}

# VPC configuration variables
variable "vpc_cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

variable "vpc_name" {
  type    = string
  default = "lab-dom03-vpc"
}

# Subnet variables
variable "subnet_name" {
  type    = string
  default = "lab-dom03-public-subnet"
}

variable "subnet_cidr_block" {
  type    = string
  default = "10.0.1.0/24"
}

# Internet gateway variables
variable "igw_name" {
  type    = string
  default = "lab-dom03-igw"
}

# Route table configuration
variable "rt_name" {
  type    = string
  default = "lab-dom03-rt"
}

variable "rt_association_ipv4_igw_cidr_block" {
  type    = string
  default = "0.0.0.0/0"
}

variable "rt_association_ipv6_igw_cidr_block" {
  type    = string
  default = "::/0"
}

# Security group configuration
variable "sg_name" {
  type = string
  description = "security group name"
  default = "allow_tls_ssh"
}

variable "ssh_allowed_cidr" {
  type        = string
  description = "CIDR allowed to SSH into the instance on port 22"
  default     = "0.0.0.0/0"
}

variable "http_allowed_cidr" {
  type        = string
  description = "CIDR allowed to http into the instance on port 22"
  default     = "0.0.0.0/0"
}

# EC2 instance configuration
variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "EC2 instance type"
}

variable "instance_name" {
  type    = string
  default = "lab-dom03-web"
}

