output "alb_security_group_id" {
  description = "Security group for the ALB."
  value       = module.alb.security_group_id
}

output "app_security_group_id" {
  description = "Security group for the app tasks."
  value       = module.app.security_group_id
}

output "vpc_endpoints_security_group_id" {
  description = "Security group for the interface VPC endpoints."
  value       = module.vpc_endpoints.security_group_id
}
