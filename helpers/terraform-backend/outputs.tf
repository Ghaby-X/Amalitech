# generate outputs
output "s3_bucket_name" {
  value       = aws_s3_bucket.backend.id
  description = "Name of the S3 bucket used for Terraform remote state"
}
