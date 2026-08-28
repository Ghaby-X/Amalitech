output "app_public_ip" {
  value       = module.app.public_ip
  description = "Public IP of the app host"
}

output "app_url" {
  value       = "http://${module.app.public_dns}:${var.app_port}"
  description = "URL to browse the app dashboard"
}

output "app_metrics_url" {
  value       = "http://${module.app.public_dns}:${var.app_port}/metrics"
  description = "URL to view the raw Prometheus scrape output"
}

output "app_fail_url" {
  value       = "http://${module.app.public_dns}:${var.app_port}/api/fail"
  description = "Always-500 endpoint - curl this repeatedly to generate error traffic for the error-rate dashboard/alert"
}

output "app_private_ip" {
  value       = module.app.private_ip
  description = "Private IP of the app host (what Prometheus scrapes)"
}

output "monitoring_public_ip" {
  value       = module.monitoring.public_ip
  description = "Public IP of the monitoring host"
}

output "prometheus_url" {
  value       = "http://${module.monitoring.public_dns}:9090"
  description = "Prometheus web UI"
}

output "grafana_url" {
  value       = "http://${module.monitoring.public_dns}:3001"
  description = "Grafana web UI (login admin/admin by default - see README to change it)"
}

output "grafana_alerts_url" {
  value       = "http://${module.monitoring.public_dns}:3001/alerting/list"
  description = "Grafana Alerting - configure the error-rate alert rule (and a Slack contact point, if wanted) here directly in the console"
}

output "app_instance_id" {
  value       = module.app.instance_id
  description = "Instance ID for `aws ec2-instance-connect ssh --instance-id ...`"
}

output "monitoring_instance_id" {
  value       = module.monitoring.instance_id
  description = "Instance ID for `aws ec2-instance-connect ssh --instance-id ...`"
}

output "ssh_app" {
  value       = "aws ec2-instance-connect ssh --instance-id ${module.app.instance_id} --os-user ec2-user --connection-type eice"
  description = "Full command to SSH into the app host - no key pair or open CIDR needed. --connection-type eice is required: both instances have public IPs, and the CLI's default 'auto' mode prefers a direct internet SSH attempt whenever one exists, which the security groups block."
}

output "ssh_monitoring" {
  value       = "aws ec2-instance-connect ssh --instance-id ${module.monitoring.instance_id} --os-user ec2-user --connection-type eice"
  description = "Full command to SSH into the monitoring host - no key pair or open CIDR needed. --connection-type eice is required: both instances have public IPs, and the CLI's default 'auto' mode prefers a direct internet SSH attempt whenever one exists, which the security groups block."
}

output "cloudtrail_bucket" {
  value       = aws_s3_bucket.cloudtrail.id
  description = "S3 bucket holding CloudTrail logs"
}

output "cloudtrail_log_group" {
  value       = aws_cloudwatch_log_group.cloudtrail.name
  description = "CloudWatch Logs group CloudTrail streams to"
}

output "app_log_group" {
  value       = aws_cloudwatch_log_group.app.name
  description = "CloudWatch Logs group the app container streams to"
}

output "guardduty_detector_id" {
  value       = var.enable_guardduty ? aws_guardduty_detector.this[0].id : null
  description = "GuardDuty detector ID, if created by this stack"
}
