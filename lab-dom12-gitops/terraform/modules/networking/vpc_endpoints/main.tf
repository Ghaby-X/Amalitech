# Private access to AWS services for workloads in subnets with no internet
# route. For Fargate pulling from ECR and logging with awslogs:
#
#   ecr.api + ecr.dkr  (interface)  image manifest/auth and registry API
#   s3                 (gateway)    image layers - ECR serves them from S3
#   logs               (interface)  awslogs driver shipping container output

data "aws_region" "current" {}

locals {
  region = data.aws_region.current.region
}

resource "aws_vpc_endpoint" "interface" {
  for_each = toset(var.interface_services)

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${local.region}.${each.key}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = var.security_group_ids
  private_dns_enabled = true

  tags = merge(var.tags, { Name = "${var.name}-${each.key}" })
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${local.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.gateway_route_table_ids

  tags = merge(var.tags, { Name = "${var.name}-s3" })
}
