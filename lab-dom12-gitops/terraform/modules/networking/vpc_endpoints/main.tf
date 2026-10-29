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

# Without a policy a gateway endpoint allows every S3 request - including
# writes to any bucket in the region, an exfiltration path the security group
# can't close (it only sees S3's IP ranges, not bucket names). Limit it to
# reading objects from the listed buckets.
data "aws_iam_policy_document" "s3_endpoint" {
  statement {
    sid       = "ReadAllowedBuckets"
    actions   = ["s3:GetObject"]
    resources = [for arn in var.s3_read_bucket_arns : "${arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${local.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.gateway_route_table_ids
  policy            = data.aws_iam_policy_document.s3_endpoint.json

  tags = merge(var.tags, { Name = "${var.name}-s3" })
}
