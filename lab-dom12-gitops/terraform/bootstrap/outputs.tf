output "state_bucket_name" {
  description = "State bucket - the `bucket` in each environment's backend block"
  value       = aws_s3_bucket.state.id
}

output "state_kms_key_arn" {
  description = "KMS key encrypting the state bucket"
  value       = module.state_kms_key.arn
}

output "backend_config" {
  description = "Backend settings for an environment root"
  value       = <<-EOT
    bucket       = "${aws_s3_bucket.state.id}"
    region       = "${data.aws_region.current.region}"
    encrypt      = true
    use_lockfile = true
  EOT
}
