output "repository_urls" {
  description = "Map of repository name (e.g. \"backend\") to its full ECR URL, for task definitions to reference."
  value       = { for name, repo in aws_ecr_repository.this : name => repo.repository_url }
}

output "repository_arns" {
  value = { for name, repo in aws_ecr_repository.this : name => repo.arn }
}
