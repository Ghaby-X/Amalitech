terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Backend config can't reference variables. Values match the
  # defaults in variable.tf and the bucket/table created by
  # ../helpers/terraform-backend.
  backend "s3" {
    bucket         = "terraform-backend-eu-west-1-55zz0s"
    key            = "lab-dom03/statefile"
    region         = "eu-west-1"
    dynamodb_table = "terraform-locks"
  }

  required_version = "~> 1.15.8"
}

# creating providers
provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = "lab-dom03-IAC"
      ManagedBy = "Terraform"
    }
  }
}

# create VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = var.vpc_name
  }
}

# create public subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr_block
  map_public_ip_on_launch = true

  tags = {
    Name = var.subnet_name
  }
}

# create internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = var.igw_name
  }
}

# create route table
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = var.rt_association_ipv4_igw_cidr_block
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block = var.rt_association_ipv6_igw_cidr_block
    gateway_id      = aws_internet_gateway.gw.id
  }

  tags = {
    Name = var.rt_name
  }
}

# associate route table with subnet
resource "aws_route_table_association" "rt_association" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.rt.id
}

# create security group
resource "aws_security_group" "allow_tls" {
  name        = var.sg_name
  description = "Allow SSH from and HTTP from anywhere; all outbound traffic allowed"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from allowed IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  egress {
    description = "allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.http_allowed_cidr]
  }

  tags = {
    Name = var.sg_name
  }
}

# find the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# create EC2 instance
resource "aws_instance" "web" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.allow_tls.id]
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    dnf install -y httpd
    systemctl enable httpd
    systemctl start httpd
    echo "<h1>Welcome to lab-dom03: Infrastructure as Code with Terraform</h1>" > /var/www/html/index.html
  EOF

  tags = {
    Name = var.instance_name
  }
}

