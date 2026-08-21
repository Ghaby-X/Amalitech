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
  default = "lab-dom07-vpc"
}

# Subnet configuration
variable "subnet_cidr_block" {
  type    = string
  default = "10.0.1.0/24"
}

variable "subnet_name" {
  type    = string
  default = "lab-dom07-public-subnet"
}

# Route table configuration
variable "rt_name" {
  type    = string
  default = "lab-dom07-rt"
}

# Security group configuration
variable "ssh_allowed_cidr" {
  type        = string
  description = "CIDR allowed to SSH into either instance"
}

variable "jenkins_ui_allowed_cidr" {
  type        = string
  default     = null
  description = "CIDR allowed to reach the Jenkins web UI on port 8080. Defaults to ssh_allowed_cidr if unset."
}

variable "app_port" {
  type        = number
  default     = 3000
  description = "Port the app listens on, exposed on the deploy target"
}

variable "app_allowed_cidr" {
  type        = string
  default     = "0.0.0.0/0"
  description = "CIDR allowed to reach the app on app_port"
}

# EC2 instance configuration
variable "jenkins_instance_type" {
  type        = string
  default     = "t3.medium"
  description = "Instance type for the Jenkins host - t3.medium so Jenkins itself and image builds have headroom. Org SCP (LimitEC2InstanceTypes) only allows t3.micro/small/medium, t2.* is denied"
}

variable "deploy_instance_type" {
  type        = string
  default     = "t3.micro"
  description = "Instance type for the deploy target - just runs one lightweight stateless container"
}

variable "jenkins_instance_name" {
  type    = string
  default = "lab-dom07-jenkins"
}

variable "deploy_instance_name" {
  type    = string
  default = "lab-dom07-deploy-target"
}
