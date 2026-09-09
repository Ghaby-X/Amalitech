# Six groups, one per network boundary: alb -> frontend -> backend ->
# postgres/redis -> efs.

locals {
  security_groups = {
    alb      = "ALB - public HTTP in, forwards to frontend only"
    frontend = "Frontend ECS tasks - reachable only from the ALB"
    backend  = "Backend ECS tasks - reachable only from the frontend"
    postgres = "Postgres ECS task - reachable only from the backend"
    redis    = "Redis ECS task - reachable only from the backend"
    efs      = "EFS mount targets - reachable only from the postgres task"
  }

  # target_type "sg" -> target names another key in security_groups
  # above; "cidr" -> target is a literal CIDR block.
  security_group_rules = {
    alb_http_from_internet = {
      sg = "alb", direction = "ingress", target_type = "cidr", target = "0.0.0.0/0"
      from_port = 80, to_port = 80
      description = "HTTP from anywhere - this is the public entry point"
    }
    alb_to_frontend = {
      sg = "alb", direction = "egress", target_type = "sg", target = "frontend"
      from_port = 3000, to_port = 3000
      description = "Forward to frontend tasks"
    }

    frontend_from_alb = {
      sg = "frontend", direction = "ingress", target_type = "sg", target = "alb"
      from_port = 3000, to_port = 3000
      description = "Only the ALB reaches the frontend directly"
    }
    frontend_to_backend = {
      sg = "frontend", direction = "egress", target_type = "sg", target = "backend"
      from_port = 8000, to_port = 8000
      description = "Server-side calls to the backend (service discovery target)"
    }
    frontend_to_internet_https = {
      sg = "frontend", direction = "egress", target_type = "cidr", target = "0.0.0.0/0"
      from_port = 443, to_port = 443
      description = "ECR/CloudWatch Logs - Fargate tasks pull images and ship logs over their own ENI, no separate host involved"
    }

    backend_from_frontend = {
      sg = "backend", direction = "ingress", target_type = "sg", target = "frontend"
      from_port = 8000, to_port = 8000
      description = "Only the frontend reaches the backend"
    }
    backend_to_postgres = {
      sg = "backend", direction = "egress", target_type = "sg", target = "postgres"
      from_port = 5432, to_port = 5432
      description = "Postgres access"
    }
    backend_to_redis = {
      sg = "backend", direction = "egress", target_type = "sg", target = "redis"
      from_port = 6379, to_port = 6379
      description = "Redis access"
    }
    backend_to_internet_https = {
      sg = "backend", direction = "egress", target_type = "cidr", target = "0.0.0.0/0"
      from_port = 443, to_port = 443
      description = "ECR/CloudWatch Logs"
    }

    postgres_from_backend = {
      sg = "postgres", direction = "ingress", target_type = "sg", target = "backend"
      from_port = 5432, to_port = 5432
      description = "Only the backend reaches postgres"
    }
    postgres_to_efs = {
      sg = "postgres", direction = "egress", target_type = "sg", target = "efs"
      from_port = 2049, to_port = 2049
      description = "Mount the EFS-backed data volume"
    }
    postgres_to_internet_https = {
      sg = "postgres", direction = "egress", target_type = "cidr", target = "0.0.0.0/0"
      from_port = 443, to_port = 443
      description = "ECR/CloudWatch Logs"
    }

    redis_from_backend = {
      sg = "redis", direction = "ingress", target_type = "sg", target = "backend"
      from_port = 6379, to_port = 6379
      description = "Only the backend reaches redis"
    }
    redis_to_internet_https = {
      sg = "redis", direction = "egress", target_type = "cidr", target = "0.0.0.0/0"
      from_port = 443, to_port = 443
      description = "ECR/CloudWatch Logs"
    }

    # efs has no egress rules at all - mount targets never initiate
    # outbound connections, so there's nothing to allow out.
    efs_from_postgres = {
      sg = "efs", direction = "ingress", target_type = "sg", target = "postgres"
      from_port = 2049, to_port = 2049
      description = "Only the postgres task mounts this filesystem"
    }
  }

  ingress_rules = { for k, v in local.security_group_rules : k => v if v.direction == "ingress" }
  egress_rules  = { for k, v in local.security_group_rules : k => v if v.direction == "egress" }
}

resource "aws_security_group" "this" {
  for_each = local.security_groups

  name        = "${var.project_name}-${each.key}"
  description = each.value
  vpc_id      = var.vpc_id

  tags = { Name = "${var.project_name}-${each.key}" }
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = local.ingress_rules

  security_group_id = aws_security_group.this[each.value.sg].id
  description        = each.value.description
  ip_protocol        = "tcp"
  from_port          = each.value.from_port
  to_port            = each.value.to_port

  cidr_ipv4                     = each.value.target_type == "cidr" ? each.value.target : null
  referenced_security_group_id = each.value.target_type == "sg" ? aws_security_group.this[each.value.target].id : null
}

resource "aws_vpc_security_group_egress_rule" "this" {
  for_each = local.egress_rules

  security_group_id = aws_security_group.this[each.value.sg].id
  description        = each.value.description
  ip_protocol        = "tcp"
  from_port          = each.value.from_port
  to_port            = each.value.to_port

  cidr_ipv4                     = each.value.target_type == "cidr" ? each.value.target : null
  referenced_security_group_id = each.value.target_type == "sg" ? aws_security_group.this[each.value.target].id : null
}
