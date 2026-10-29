data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name       = "lab-dom12-${var.environment}"
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.region

  azs = slice(sort(data.aws_availability_zones.available.names), 0, length(var.public_subnet_cidr_blocks))

  cluster_name   = "${local.name}-cluster"
  service_name   = "${local.name}-app"
  container_name = "server-details"
}
