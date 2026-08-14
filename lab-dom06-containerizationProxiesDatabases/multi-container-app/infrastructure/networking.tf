module "vpc" {
  source = "../../../helpers/terraform-modules//aws_vpc"

  name       = var.vpc_name
  cidr_block = var.vpc_cidr_block
}

module "subnet" {
  source = "../../../helpers/terraform-modules//aws_subnet"

  name                    = var.subnet_name
  vpc_id                  = module.vpc.vpc_id
  azs                     = ["${var.region}a"]
  cidr_blocks             = [var.subnet_cidr_block]
  map_public_ip_on_launch = true
}

module "route_table" {
  source = "../../../helpers/terraform-modules//aws_route_table"

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
  source = "../../../helpers/terraform-modules//aws_security_group"

  name        = var.sg_name
  description = "Allow SSH and nginx (the only public entry point to the app)"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = {
    ssh = {
      description = "SSH from allowed IP"
      ip_protocol = "tcp"
      from_port   = 22
      to_port     = 22
      cidr_ipv4   = var.ssh_allowed_cidr
    }
    app = {
      description = "nginx (reverse-proxies to the app internally)"
      ip_protocol = "tcp"
      from_port   = var.app_port
      to_port     = var.app_port
      cidr_ipv4   = var.app_allowed_cidr
    }
  }

  egress_rules = {
    all = {
      description = "allow all outbound"
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
}

