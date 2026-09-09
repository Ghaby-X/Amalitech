output "alb_security_group_id" {
  value = aws_security_group.this["alb"].id
}

output "frontend_security_group_id" {
  value = aws_security_group.this["frontend"].id
}

output "backend_security_group_id" {
  value = aws_security_group.this["backend"].id
}

output "postgres_security_group_id" {
  value = aws_security_group.this["postgres"].id
}

output "redis_security_group_id" {
  value = aws_security_group.this["redis"].id
}

output "efs_security_group_id" {
  value = aws_security_group.this["efs"].id
}
