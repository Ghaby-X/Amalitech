output "key_name" {
  value       = module.keypair.key_name
  description = "Name of the AWS key pair"
}

output "private_key_path" {
  value       = module.keypair.private_key_path
  description = "Local path to the generated private key file"
}

output "public_key_openssh" {
  value       = module.keypair.public_key_openssh
  description = "Public key in OpenSSH authorized_keys format"
}

output "fingerprint" {
  value       = module.keypair.fingerprint
  description = "Fingerprint of the key pair"
}
