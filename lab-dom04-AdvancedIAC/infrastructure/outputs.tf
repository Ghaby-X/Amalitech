output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "ID of the VPC"
}

output "public_subnet_id" {
  value       = module.subnet.subnet_ids[0]
  description = "ID of the public subnet"
}

output "security_group_id" {
  value       = module.security_group.security_group_id
  description = "ID of the security group attached to the instance"
}

output "instance_id" {
  value       = module.ec2.instance_id
  description = "ID of the EC2 instance"
}

output "instance_public_ip" {
  value       = module.ec2.public_ip
  description = "Public IP of the EC2 instance"
}

output "instance_public_dns" {
  value       = module.ec2.public_dns
  description = "Public DNS name of the EC2 instance"
}

output "ssh_user" {
  value       = "ec2-user"
  description = "SSH user for connecting to the EC2 instance (Amazon Linux default)"
}

output "key_pair_name" {
  value       = data.terraform_remote_state.keypair.outputs.key_name
  description = "Name of the AWS key pair associated with the instance (managed in helpers/keypair)"
}

output "private_key_path" {
  value       = data.terraform_remote_state.keypair.outputs.private_key_path
  description = "Local path to the generated private key file (managed in helpers/keypair)"
}
