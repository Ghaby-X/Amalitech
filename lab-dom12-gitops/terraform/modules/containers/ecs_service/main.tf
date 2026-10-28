data "aws_region" "current" {}

resource "aws_ecs_cluster" "this" {
  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(var.tags, { Name = var.cluster_name })
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name       = aws_ecs_cluster.this.name
  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
  }
}

# Container stdout/stderr lands here via the awslogs log driver.
resource "aws_cloudwatch_log_group" "app" {
  name              = var.log_group_name
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = var.tags
}

# --- IAM ---

data "aws_iam_policy_document" "ecs_tasks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# Execution role: used by the ECS agent to pull the image and ship logs.
# Scoped to this repository and log group rather than the broad
# AmazonECSTaskExecutionRolePolicy.
resource "aws_iam_role" "execution" {
  name               = "${var.service_name}-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json

  tags = var.tags
}

data "aws_iam_policy_document" "execution" {
  statement {
    sid       = "EcrAuth"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid = "EcrPull"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]
    resources = [var.ecr_repository_arn]
  }

  statement {
    sid = "WriteLogs"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["${aws_cloudwatch_log_group.app.arn}:*"]
  }
}

resource "aws_iam_role_policy" "execution" {
  name   = "pull-image-write-logs"
  role   = aws_iam_role.execution.id
  policy = data.aws_iam_policy_document.execution.json
}

# Task role: the identity the app itself runs as. The app makes no AWS calls,
# so it carries no permissions - it exists so the task definition never falls
# back to anything broader.
resource "aws_iam_role" "task" {
  name               = "${var.service_name}-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json

  tags = var.tags
}

# --- Initial task definition ---
#
# An ECS service can't be created without a task definition, so Terraform
# registers revision 1 as a placeholder. Every later revision is rendered from ecs/taskdef.template.json and
# registered by the CI pipeline - see the ignore_changes on the service below.
resource "aws_ecs_task_definition" "initial" {
  family                   = var.task_family
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name                   = var.container_name
      image                  = "${var.ecr_repository_url}:${var.initial_image_tag}"
      essential              = true
      readonlyRootFilesystem = true
      # Runs an init process as PID 1 so SIGTERM from a rolling stop reaches
      # node and exits cleanly instead of being killed after the stop timeout.
      linuxParameters = {
        initProcessEnabled = true
      }
      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "PORT", value = tostring(var.container_port) },
        { name = "NODE_ENV", value = "production" },
      ]
      healthCheck = {
        command     = ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://127.0.0.1:${var.container_port}${var.health_check_path} || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 10
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.app.name
          awslogs-region        = data.aws_region.current.region
          awslogs-stream-prefix = var.container_name
        }
      }
    }
  ])

  tags = var.tags
}

# --- Service ---

resource "aws_ecs_service" "this" {
  name            = var.service_name
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.initial.arn
  desired_count   = var.initial_desired_count

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
  }

  availability_zone_rebalancing = "ENABLED"

  # Rolling update: start the new task before stopping the old one.
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  health_check_grace_period_seconds  = 30

  deployment_controller {
    type = "ECS"
  }

  deployment_configuration {
    strategy = "ROLLING"
  }

  # Roll back if the new revision's tasks never become healthy...
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  # ...or if they do start but trip a monitoring alarm during the deployment.
  dynamic "alarms" {
    for_each = length(var.deployment_alarm_names) > 0 ? [1] : []
    content {
      alarm_names = var.deployment_alarm_names
      enable      = true
      rollback    = true
    }
  }

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  enable_ecs_managed_tags = true
  propagate_tags          = "SERVICE"

  # The pipeline owns the running revision and task count from here on
  # (register-task-definition + update-service). Without this, every
  # `terraform apply` would roll the service back to the initial revision.
  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  tags = merge(var.tags, { Name = var.service_name })

  depends_on = [aws_iam_role_policy.execution]
}
