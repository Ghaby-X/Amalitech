output "sns_topic_arn" {
  description = "ARN of the alarm/deployment notification topic."
  value       = aws_sns_topic.alarms.arn
}

output "alarm_names" {
  description = "Names of every alarm this module creates."
  value = [
    aws_cloudwatch_metric_alarm.high_error_rate.alarm_name,
    aws_cloudwatch_metric_alarm.app_target_down.alarm_name,
    aws_cloudwatch_metric_alarm.app_5xx_logged.alarm_name,
    aws_cloudwatch_metric_alarm.cpu_high.alarm_name,
    aws_cloudwatch_metric_alarm.memory_high.alarm_name,
  ]
}

output "deployment_alarm_names" {
  description = "Alarms suited to gating ECS deployments - ones that reflect the new revision's behaviour, not alarms already firing before it starts (e.g. AppTargetDown on a first deploy from zero tasks)."
  value       = [aws_cloudwatch_metric_alarm.high_error_rate.alarm_name]
}

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard."
  value       = aws_cloudwatch_dashboard.this.dashboard_name
}

output "deployment_events_log_group_name" {
  description = "Log group holding ECS deployment state change events."
  value       = aws_cloudwatch_log_group.deployment_events.name
}
