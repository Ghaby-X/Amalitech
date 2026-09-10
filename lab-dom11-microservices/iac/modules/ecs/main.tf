# cluster
resource "aws_ecs_cluster" "this" {
  name = var.project_name

  tags = { Name = var.project_name }
}

# logging module
# One shared group, per-service streams via each task definition's
# awslogs-stream-prefix.

resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = var.log_retention_days

  tags = { Name = "${var.project_name}-ecs-logs" }
}

# service discovery
# Cloud Map private DNS namespace
resource "aws_service_discovery_private_dns_namespace" "this" {
  name        = "${var.project_name}.local"
  description = "Service discovery for ${var.project_name} ECS services"
  vpc         = var.vpc_id

  tags = { Name = "${var.project_name}-namespace" }
}
