# Every security group in the stack, in one place, so the whole traffic flow
# can be reviewed together:
#
#   internet ----80----> ALB --app_port--> app tasks --443--> VPC endpoints
#                                                    \--443--> S3 (gateway endpoint prefix list)
#
# Groups are built with the shared helper module, whose aws_security_group
# drops AWS's default allow-all egress - so each group's egress is exactly
# what is declared here, and the VPC endpoints group has none at all.

data "aws_region" "current" {}

# AWS-managed prefix list of S3's IP ranges in this region - lets the app
# tasks reach the S3 gateway endpoint without a 0.0.0.0/0 rule.
data "aws_ec2_managed_prefix_list" "s3" {
  name = "com.amazonaws.${data.aws_region.current.region}.s3"
}

module "alb" {
  source = "git::https://github.com/Ghaby-X/terraform-modules.git//aws_security_group?ref=ec92f5169b14c3338036d4e70853947a71c1be63"

  name        = "${var.name}-alb-sg"
  description = "ALB - HTTP in from alb_ingress_cidr, out to the app tasks only"
  vpc_id      = var.vpc_id

  ingress_rules = {
    http = {
      description = "HTTP from alb_ingress_cidr"
      ip_protocol = "tcp"
      from_port   = 80
      to_port     = 80
      cidr_ipv4   = var.alb_ingress_cidr
    }
  }

  egress_rules = {
    to_app = {
      description                  = "Forward to the app tasks (also covers target health checks)"
      ip_protocol                  = "tcp"
      from_port                    = var.app_port
      to_port                      = var.app_port
      referenced_security_group_id = module.app.security_group_id
    }
  }

  tags = var.tags
}

module "app" {
  source = "git::https://github.com/Ghaby-X/terraform-modules.git//aws_security_group?ref=ec92f5169b14c3338036d4e70853947a71c1be63"

  name        = "${var.name}-app-sg"
  description = "App tasks - app port from the ALB only, HTTPS out to VPC endpoints only"
  vpc_id      = var.vpc_id

  ingress_rules = {
    from_alb = {
      description                  = "App port from the ALB"
      ip_protocol                  = "tcp"
      from_port                    = var.app_port
      to_port                      = var.app_port
      referenced_security_group_id = module.alb.security_group_id
    }
  }

  egress_rules = {
    https_to_endpoints = {
      description                  = "HTTPS to the interface endpoints (ECR API/registry, CloudWatch Logs)"
      ip_protocol                  = "tcp"
      from_port                    = 443
      to_port                      = 443
      referenced_security_group_id = module.vpc_endpoints.security_group_id
    }
    https_to_s3 = {
      description    = "HTTPS to S3 via the gateway endpoint (ECR image layers)"
      ip_protocol    = "tcp"
      from_port      = 443
      to_port        = 443
      prefix_list_id = data.aws_ec2_managed_prefix_list.s3.id
    }
  }

  tags = var.tags
}

module "vpc_endpoints" {
  source = "git::https://github.com/Ghaby-X/terraform-modules.git//aws_security_group?ref=ec92f5169b14c3338036d4e70853947a71c1be63"

  name        = "${var.name}-endpoints-sg"
  description = "Interface VPC endpoints - HTTPS from the app tasks only"
  vpc_id      = var.vpc_id

  ingress_rules = {
    https_from_app = {
      description                  = "HTTPS from the app tasks"
      ip_protocol                  = "tcp"
      from_port                    = 443
      to_port                      = 443
      referenced_security_group_id = module.app.security_group_id
    }
  }

  tags = var.tags
}
