output "role_arn" {
  description = "ARN of the role - set as the AWS_ROLE_ARN variable on the GitHub environment."
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "Name of the role."
  value       = aws_iam_role.this.name
}
