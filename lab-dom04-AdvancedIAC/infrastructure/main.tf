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

  tags = {
    Name = var.sg_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.allow_tls.id
  description       = "SSH from allowed IP"

  cidr_ipv4   = var.ssh_allowed_cidr
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.allow_tls.id
  description       = "HTTP from anywhere"

  cidr_ipv4   = var.http_allowed_cidr
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.allow_tls.id
  description       = "allow all outbound"

  cidr_ipv4   = var.http_allowed_cidr
  ip_protocol = "-1"
}

# creating private key
resource "tls_private_key" "ec2_key_pair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_sensitive_file" "private_key" {
  filename = "${path.module}/${var.private_key_pair_name}"
  content  = tls_private_key.ec2_key_pair.private_key_pem
}

resource "aws_key_pair" "ec2_key_pair" {
  key_name   = var.key_pair_name
  public_key = tls_private_key.ec2_key_pair.public_key_openssh
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
  key_name                    = var.key_pair_name
  depends_on                  = [aws_key_pair.ec2_key_pair]

  tags = {
    Name = var.instance_name
  }
}

