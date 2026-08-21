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
      cidr_block = "0.0.0.0/0"
      gateway_id = module.vpc.internet_gateway_id
    }
  ]
}
