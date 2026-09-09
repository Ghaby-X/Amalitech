output "postgres_file_system_id" {
  value = aws_efs_file_system.postgres.id
}

output "postgres_access_point_id" {
  value = aws_efs_access_point.postgres.id
}
