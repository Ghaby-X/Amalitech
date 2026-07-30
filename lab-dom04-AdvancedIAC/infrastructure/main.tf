# key pair is managed separately in helpers/keypair; read its outputs from that state
data "terraform_remote_state" "keypair" {
  backend = "s3"

  config = {
    bucket = "terraform-backend-eu-west-1-55zz0s"
    key    = "helpers/keypair/statefile"
    region = "eu-west-1"
  }
}

module "vpc" {
  source = "../../helpers/terraform-modules//aws_vpc"

  name       = var.vpc_name
  cidr_block = var.vpc_cidr_block
}

module "subnet" {
  source = "../../helpers/terraform-modules//aws_subnet"

  name                    = var.subnet_name
  vpc_id                  = module.vpc.vpc_id
  azs                     = ["${var.region}a"]
  cidr_blocks             = [var.subnet_cidr_block]
  map_public_ip_on_launch = true
}

module "route_table" {
  source = "../../helpers/terraform-modules//aws_route_table"

  name       = var.rt_name
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.subnet.subnet_ids_by_az

  routes = [
    {
      cidr_block = var.rt_association_ipv4_igw_cidr_block
      gateway_id = module.vpc.internet_gateway_id
    }
  ]
}

module "security_group" {
  source = "../../helpers/terraform-modules//aws_security_group"

  name        = var.sg_name
  description = "Allow SSH from and HTTP from anywhere; all outbound traffic allowed"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = {
    ssh = {
      description = "SSH from allowed IP"
      ip_protocol = "tcp"
      from_port   = 22
      to_port     = 22
      cidr_ipv4   = var.ssh_allowed_cidr
    }
    http = {
      description = "HTTP from anywhere"
      ip_protocol = "tcp"
      from_port   = 80
      to_port     = 80
      cidr_ipv4   = var.http_allowed_cidr
    }
  }

  egress_rules = {
    all = {
      description = "allow all outbound"
      ip_protocol = "-1"
      cidr_ipv4   = var.http_allowed_cidr
    }
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

module "ec2" {
  source = "../../helpers/terraform-modules//aws_ec2"

  name                        = var.instance_name
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = module.subnet.subnet_ids[0]
  security_group_ids          = [module.security_group.security_group_id]
  associate_public_ip_address = true
  key_name                    = data.terraform_remote_state.keypair.outputs.key_name
}
