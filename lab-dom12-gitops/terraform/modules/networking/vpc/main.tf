# VPC with public and private subnets, built from the shared helper modules
# (github.com/Ghaby-X/terraform-modules) pinned to a full commit SHA, plus
# VPC flow logs.
#
# Private subnets get a route table with no default route: anything running
# there reaches AWS services only through VPC endpoints (see the
# vpc_endpoints module), never the internet.

data "aws_caller_identity" "current" {}

module "vpc" {
  source = "git::https://github.com/Ghaby-X/terraform-modules.git//aws_vpc?ref=ec92f5169b14c3338036d4e70853947a71c1be63"

  name       = "${var.name}-vpc"
  cidr_block = var.cidr_block
  tags       = var.tags
}

module "public_subnets" {
  source = "git::https://github.com/Ghaby-X/terraform-modules.git//aws_subnet?ref=ec92f5169b14c3338036d4e70853947a71c1be63"

  name        = "${var.name}-public"
  vpc_id      = module.vpc.vpc_id
  azs         = var.azs
  cidr_blocks = var.public_subnet_cidr_blocks
  tags        = var.tags
}

module "private_subnets" {
  source = "git::https://github.com/Ghaby-X/terraform-modules.git//aws_subnet?ref=ec92f5169b14c3338036d4e70853947a71c1be63"

  name        = "${var.name}-private"
  vpc_id      = module.vpc.vpc_id
  azs         = var.azs
  cidr_blocks = var.private_subnet_cidr_blocks
  tags        = var.tags
}

module "public_route_table" {
  source = "git::https://github.com/Ghaby-X/terraform-modules.git//aws_route_table?ref=ec92f5169b14c3338036d4e70853947a71c1be63"

  name       = "${var.name}-public-rt"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.public_subnets.subnet_ids_by_az
  routes = [
    { cidr_block = "0.0.0.0/0", gateway_id = module.vpc.internet_gateway_id },
  ]
  tags = var.tags
}

module "private_route_table" {
  source = "git::https://github.com/Ghaby-X/terraform-modules.git//aws_route_table?ref=ec92f5169b14c3338036d4e70853947a71c1be63"

  name       = "${var.name}-private-rt"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.private_subnets.subnet_ids_by_az
  tags       = var.tags
}

# --- VPC flow logs ---

resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = var.flow_logs_log_group_name
  retention_in_days = var.flow_logs_retention_days
  kms_key_id        = var.kms_key_arn

  tags = var.tags
}

data "aws_iam_policy_document" "flow_logs_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role" "flow_logs" {
  name               = "${var.name}-vpc-flow-logs"
  assume_role_policy = data.aws_iam_policy_document.flow_logs_assume_role.json

  tags = var.tags
}

data "aws_iam_policy_document" "flow_logs_write" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
    ]
    resources = ["${aws_cloudwatch_log_group.flow_logs.arn}:*"]
  }
}

resource "aws_iam_role_policy" "flow_logs_write" {
  name   = "write-flow-logs"
  role   = aws_iam_role.flow_logs.id
  policy = data.aws_iam_policy_document.flow_logs_write.json
}

resource "aws_flow_log" "this" {
  vpc_id                   = module.vpc.vpc_id
  traffic_type             = var.flow_logs_traffic_type
  log_destination_type     = "cloud-watch-logs"
  log_destination          = aws_cloudwatch_log_group.flow_logs.arn
  iam_role_arn             = aws_iam_role.flow_logs.arn
  max_aggregation_interval = 60

  tags = merge(var.tags, { Name = "${var.name}-vpc-flow-logs" })
}
