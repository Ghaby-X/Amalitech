# Five groups, one per network boundary

locals {
  security_groups = {
    alb      = "ALB - public HTTP in, forwards to frontend only"
    frontend = "Frontend ECS tasks - reachable only from the ALB"
    backend  = "Backend ECS tasks - reachable only from the frontend"
    postgres = "RDS Postgres - reachable from the ECS backend task and EKS pods"
    redis    = "ElastiCache Redis - reachable from the ECS backend task and EKS pods"
  }

  # target_type "sg" -> target names another key in security_groups above;
  # "external_sg" -> target names a key in local.external_security_groups;
  external_security_groups = {
    eks_cluster = var.eks_cluster_security_group_id
  }
  security_group_rules = {
    alb_http_from_internet = {
      sg          = "alb", direction = "ingress", target_type = "cidr", target = "0.0.0.0/0"
      from_port   = 80, to_port = 80
      description = "HTTP from anywhere - this is the public entry point"
    }
    alb_to_frontend = {
      sg          = "alb", direction = "egress", target_type = "sg", target = "frontend"
      from_port   = 3000, to_port = 3000
      description = "Forward to frontend tasks"
    }

    frontend_from_alb = {
      sg          = "frontend", direction = "ingress", target_type = "sg", target = "alb"
      from_port   = 3000, to_port = 3000
      description = "Only the ALB reaches the frontend directly"
    }
    frontend_to_backend = {
      sg          = "frontend", direction = "egress", target_type = "sg", target = "backend"
      from_port   = 8000, to_port = 8000
      description = "Server-side calls to the backend (service discovery target)"
    }
    frontend_to_internet_https = {
      sg          = "frontend", direction = "egress", target_type = "cidr", target = "0.0.0.0/0"
      from_port   = 443, to_port = 443
      description = "ECR/CloudWatch Logs - Fargate tasks pull images and ship logs over their own ENI, no separate host involved"
    }

    backend_from_frontend = {
      sg          = "backend", direction = "ingress", target_type = "sg", target = "frontend"
      from_port   = 8000, to_port = 8000
      description = "Only the frontend reaches the backend"
    }
    backend_to_postgres = {
      sg          = "backend", direction = "egress", target_type = "sg", target = "postgres"
      from_port   = 5432, to_port = 5432
      description = "Postgres access"
    }
    backend_to_redis = {
      sg          = "backend", direction = "egress", target_type = "sg", target = "redis"
      from_port   = 6379, to_port = 6379
      description = "Redis access"
    }
    backend_to_internet_https = {
      sg          = "backend", direction = "egress", target_type = "cidr", target = "0.0.0.0/0"
      from_port   = 443, to_port = 443
      description = "ECR/CloudWatch Logs"
    }

    postgres_from_backend = {
      sg          = "postgres", direction = "ingress", target_type = "sg", target = "backend"
      from_port   = 5432, to_port = 5432
      description = "ECS backend task reaches postgres"
    }
    postgres_from_eks = {
      sg          = "postgres", direction = "ingress", target_type = "external_sg", target = "eks_cluster"
      from_port   = 5432, to_port = 5432
      description = "EKS pods reach postgres"
    }

    redis_from_backend = {
      sg          = "redis", direction = "ingress", target_type = "sg", target = "backend"
      from_port   = 6379, to_port = 6379
      description = "ECS backend task reaches redis"
    }
    redis_from_eks = {
      sg          = "redis", direction = "ingress", target_type = "external_sg", target = "eks_cluster"
      from_port   = 6379, to_port = 6379
      description = "EKS pods reach redis"
    }

    # postgres/redis are managed services (RDS/ElastiCache) - they never
    # initiate outbound connections, so there are no egress rules for them.
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

locals {
  # resolve each rule's target to an actual security group ID, for "sg"
  # (internal) and "external_sg" target types
  resolved_sg_target = {
    for k, v in local.security_group_rules : k => (
      v.target_type == "sg" ? aws_security_group.this[v.target].id :
      v.target_type == "external_sg" ? local.external_security_groups[v.target] :
      null
    )
  }
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = local.ingress_rules

  security_group_id = aws_security_group.this[each.value.sg].id
  description       = each.value.description
  ip_protocol       = "tcp"
  from_port         = each.value.from_port
  to_port           = each.value.to_port

  cidr_ipv4                    = each.value.target_type == "cidr" ? each.value.target : null
  referenced_security_group_id = each.value.target_type != "cidr" ? local.resolved_sg_target[each.key] : null
}

resource "aws_vpc_security_group_egress_rule" "this" {
  for_each = local.egress_rules

  security_group_id = aws_security_group.this[each.value.sg].id
  description       = each.value.description
  ip_protocol       = "tcp"
  from_port         = each.value.from_port
  to_port           = each.value.to_port

  cidr_ipv4                    = each.value.target_type == "cidr" ? each.value.target : null
  referenced_security_group_id = each.value.target_type != "cidr" ? local.resolved_sg_target[each.key] : null
}
