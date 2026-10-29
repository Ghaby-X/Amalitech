data "aws_region" "current" {}

locals {
  alb_dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  target_group_dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }

  service_dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.service_name
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
}

# --- Notifications ---
#
# Encrypted with a customer-managed key: CloudWatch alarms and EventBridge
# can't publish to a topic encrypted with the AWS-managed aws/sns key, so the
# key's policy has to grant them kms:GenerateDataKey*/Decrypt itself.
resource "aws_sns_topic" "alarms" {
  name              = "${var.name_prefix}-alarms"
  kms_master_key_id = var.kms_key_arn

  tags = var.tags
}

resource "aws_sns_topic_subscription" "email" {
  for_each = var.alarm_email == null ? toset([]) : toset([var.alarm_email])

  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = each.value
}

data "aws_iam_policy_document" "alarms_topic" {
  statement {
    sid     = "AllowCloudWatchAlarms"
    actions = ["sns:Publish"]
    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }
    resources = [aws_sns_topic.alarms.arn]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.account_id]
    }
  }

  statement {
    sid     = "AllowDeploymentEvents"
    actions = ["sns:Publish"]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    resources = [aws_sns_topic.alarms.arn]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudwatch_event_rule.ecs_deployments.arn]
    }
  }
}

resource "aws_sns_topic_policy" "alarms" {
  arn    = aws_sns_topic.alarms.arn
  policy = data.aws_iam_policy_document.alarms_topic.json
}

# --- Alarms: lab-dom08 Prometheus rules, carried over to CloudWatch ---

# HighErrorRate: 5xx responses above 5% of traffic over a 2-minute window.
# Also wired into the ECS service as a deployment alarm, so a revision that
# starts throwing errors is rolled back automatically.
resource "aws_cloudwatch_metric_alarm" "high_error_rate" {
  alarm_name          = "${var.name_prefix}-high-error-rate"
  alarm_description   = "Target 5xx responses above ${var.error_rate_threshold_percent}% of requests over 2 minutes (lab-dom08 HighErrorRate parity)."
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.error_rate_threshold_percent
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "error_rate"
    expression  = "IF(requests > 0, 100 * errors / requests, 0)"
    label       = "5xx error rate (%)"
    return_data = true
  }

  metric_query {
    id = "errors"
    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "HTTPCode_Target_5XX_Count"
      dimensions  = local.alb_dimensions
      period      = 60
      stat        = "Sum"
    }
  }

  metric_query {
    id = "requests"
    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "RequestCount"
      dimensions  = local.alb_dimensions
      period      = 60
      stat        = "Sum"
    }
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions

  tags = var.tags
}

# AppTargetDown: no healthy task behind the load balancer.
resource "aws_cloudwatch_metric_alarm" "app_target_down" {
  alarm_name          = "${var.name_prefix}-app-target-down"
  alarm_description   = "No healthy targets in the app target group for 2 minutes (lab-dom08 AppTargetDown parity)."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HealthyHostCount"
  dimensions          = local.target_group_dimensions
  statistic           = "Minimum"
  period              = 60
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  comparison_operator = "LessThanThreshold"
  threshold           = 1
  treat_missing_data  = "breaching"

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.name_prefix}-cpu-high"
  alarm_description   = "ECS service average CPU above ${var.cpu_threshold_percent}% for 3 minutes."
  namespace           = "AWS/ECS"
  metric_name         = "CPUUtilization"
  dimensions          = local.service_dimensions
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 3
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.cpu_threshold_percent
  treat_missing_data  = "notBreaching"

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "memory_high" {
  alarm_name          = "${var.name_prefix}-memory-high"
  alarm_description   = "ECS service average memory above ${var.memory_threshold_percent}% for 3 minutes."
  namespace           = "AWS/ECS"
  metric_name         = "MemoryUtilization"
  dimensions          = local.service_dimensions
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 3
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.memory_threshold_percent
  treat_missing_data  = "notBreaching"

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions

  tags = var.tags
}

# --- Log-based metric: 5xx responses counted from the app's own JSON access log ---
#
# Independent of the ALB metrics above - proves the awslogs pipeline is
# delivering, and keeps counting even for requests that bypass the ALB.
resource "aws_cloudwatch_log_metric_filter" "app_5xx" {
  name           = "${var.name_prefix}-app-5xx"
  log_group_name = var.app_log_group_name
  pattern        = "{ $.status >= 500 }"

  metric_transformation {
    namespace     = var.metric_namespace
    name          = "App5xxCount"
    value         = "1"
    default_value = "0"
    unit          = "Count"
  }
}

resource "aws_cloudwatch_metric_alarm" "app_5xx_logged" {
  alarm_name          = "${var.name_prefix}-app-5xx-logged"
  alarm_description   = "${var.app_5xx_log_threshold}+ 5xx responses in the app's CloudWatch access logs within 5 minutes."
  namespace           = var.metric_namespace
  metric_name         = aws_cloudwatch_log_metric_filter.app_5xx.metric_transformation[0].name
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = var.app_5xx_log_threshold
  treat_missing_data  = "notBreaching"

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions

  tags = var.tags
}

# --- Deployment events: every ECS deployment start/finish/failure for this
# service, kept in a log group (shown on the dashboard) and sent to SNS ---

resource "aws_cloudwatch_event_rule" "ecs_deployments" {
  name        = "${var.name_prefix}-ecs-deployments"
  description = "ECS deployment state changes for ${var.service_name}"

  event_pattern = jsonencode({
    source      = ["aws.ecs"]
    detail-type = ["ECS Deployment State Change"]
    resources   = [var.service_arn]
  })

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "deployment_events" {
  # EventBridge can only target log groups under /aws/events/.
  name              = "/aws/events/${var.name_prefix}-ecs-deployments"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = var.tags
}

data "aws_iam_policy_document" "deployment_events_logs" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com", "delivery.logs.amazonaws.com"]
    }
    resources = ["${aws_cloudwatch_log_group.deployment_events.arn}:*"]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudwatch_event_rule.ecs_deployments.arn]
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "deployment_events" {
  policy_name     = "${var.name_prefix}-ecs-deployment-events"
  policy_document = data.aws_iam_policy_document.deployment_events_logs.json
}

resource "aws_cloudwatch_event_target" "deployment_events_logs" {
  rule = aws_cloudwatch_event_rule.ecs_deployments.name
  arn  = aws_cloudwatch_log_group.deployment_events.arn

  depends_on = [aws_cloudwatch_log_resource_policy.deployment_events]
}

resource "aws_cloudwatch_event_target" "deployment_events_sns" {
  rule = aws_cloudwatch_event_rule.ecs_deployments.name
  arn  = aws_sns_topic.alarms.arn

  depends_on = [aws_sns_topic_policy.alarms]
}

# --- Dashboard ---

resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = var.name_prefix

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "alarm"
        x      = 0
        y      = 0
        width  = 24
        height = 3
        properties = {
          title = "Alarm status"
          alarms = [
            aws_cloudwatch_metric_alarm.high_error_rate.arn,
            aws_cloudwatch_metric_alarm.app_target_down.arn,
            aws_cloudwatch_metric_alarm.app_5xx_logged.arn,
            aws_cloudwatch_metric_alarm.cpu_high.arn,
            aws_cloudwatch_metric_alarm.memory_high.arn,
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 3
        width  = 12
        height = 6
        properties = {
          title  = "Requests and 5xx (ALB)"
          region = data.aws_region.current.region
          stat   = "Sum"
          period = 60
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix, { label = "Requests" }],
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", var.alb_arn_suffix, { label = "Target 5xx", color = "#d62728" }],
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 3
        width  = 12
        height = 6
        properties = {
          title  = "Latency (target response time)"
          region = data.aws_region.current.region
          period = 60
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix, { stat = "p50", label = "p50" }],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix, { stat = "p95", label = "p95" }],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix, { stat = "p99", label = "p99" }],
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 9
        width  = 12
        height = 6
        properties = {
          title  = "Tasks (running vs desired) and healthy targets"
          region = data.aws_region.current.region
          period = 60
          metrics = [
            ["ECS/ContainerInsights", "RunningTaskCount", "ClusterName", var.cluster_name, "ServiceName", var.service_name, { stat = "Average", label = "Running" }],
            ["ECS/ContainerInsights", "DesiredTaskCount", "ClusterName", var.cluster_name, "ServiceName", var.service_name, { stat = "Average", label = "Desired" }],
            ["AWS/ApplicationELB", "HealthyHostCount", "TargetGroup", var.target_group_arn_suffix, "LoadBalancer", var.alb_arn_suffix, { stat = "Minimum", label = "Healthy targets" }],
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 9
        width  = 12
        height = 6
        properties = {
          title  = "ECS service CPU / memory (%)"
          region = data.aws_region.current.region
          stat   = "Average"
          period = 60
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", var.cluster_name, "ServiceName", var.service_name, { label = "CPU" }],
            ["AWS/ECS", "MemoryUtilization", "ClusterName", var.cluster_name, "ServiceName", var.service_name, { label = "Memory" }],
          ]
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 15
        width  = 24
        height = 6
        properties = {
          title  = "ECS deployments"
          region = data.aws_region.current.region
          view   = "table"
          query  = "SOURCE '${aws_cloudwatch_log_group.deployment_events.name}' | fields @timestamp, detail.eventName as event, detail.deploymentId as deployment, detail.reason as reason | sort @timestamp desc | limit 20"
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 21
        width  = 24
        height = 6
        properties = {
          title  = "Recent 5xx responses (app access log)"
          region = data.aws_region.current.region
          view   = "table"
          query  = "SOURCE '${var.app_log_group_name}' | fields @timestamp, method, path, status, durationMs, @logStream | filter status >= 500 | sort @timestamp desc | limit 20"
        }
      },
    ]
  })
}
