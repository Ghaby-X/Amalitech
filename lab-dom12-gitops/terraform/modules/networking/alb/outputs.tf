output "dns_name" {
  description = "Public DNS name of the load balancer."
  value       = aws_lb.this.dns_name
}

output "arn" {
  description = "ARN of the load balancer."
  value       = aws_lb.this.arn
}

output "arn_suffix" {
  description = "ARN suffix of the load balancer - the LoadBalancer dimension for AWS/ApplicationELB metrics."
  value       = aws_lb.this.arn_suffix
}

output "target_group_arn" {
  description = "ARN of the target group. Only available once a listener forwards to it - ECS refuses to register a service with a target group that isn't attached to a load balancer yet."
  value       = aws_lb_target_group.this.arn

  depends_on = [aws_lb_listener.http]
}

output "target_group_arn_suffix" {
  description = "ARN suffix of the target group - the TargetGroup dimension for AWS/ApplicationELB metrics."
  value       = aws_lb_target_group.this.arn_suffix
}

output "listener_arn" {
  description = "ARN of the HTTP listener."
  value       = aws_lb_listener.http.arn
}

output "url" {
  description = "Base URL of the app through the load balancer."
  value       = "http://${aws_lb.this.dns_name}"
}
