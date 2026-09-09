# Output both name and ARN of each parameter
output "postgres_password_name" {
  value = aws_ssm_parameter.postgres_password.name
}

output "postgres_password_arn" {
  value = aws_ssm_parameter.postgres_password.arn
}

output "redis_password_name" {
  value = aws_ssm_parameter.redis_password.name
}

output "redis_password_arn" {
  value = aws_ssm_parameter.redis_password.arn
}

output "frontend_secret_key_name" {
  value = aws_ssm_parameter.frontend_secret_key.name
}

output "frontend_secret_key_arn" {
  value = aws_ssm_parameter.frontend_secret_key.arn
}
