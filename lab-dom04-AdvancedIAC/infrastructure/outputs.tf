output "vpc_id" {
  value       = aws_vpc.main.id
  description = "ID of the VPC"
}

output "public_subnet_id" {
  value       = aws_subnet.public.id
  description = "ID of the public subnet"
}

output "security_group_id" {
  value       = aws_security_group.allow_tls.id
  description = "ID of the security group attached to the instance"
}

output "instance_id" {
  value       = aws_instance.web.id
  description = "ID of the EC2 instance"
}

output "instance_public_ip" {
  value       = aws_instance.web.public_ip
  description = "Public IP of the EC2 instance"
}

output "instance_public_dns" {
  value       = aws_instance.web.public_dns
  description = "Public DNS name of the EC2 instance"
}

output "ssh_user" {
  value       = "ec2-user"
  description = "SSH user for connecting to the EC2 instance (Amazon Linux default)"
}

output "key_pair_name" {
  value       = aws_key_pair.ec2_key_pair.key_name
  description = "Name of the AWS key pair associated with the instance"
}

output "private_key_path" {
  value       = local_sensitive_file.private_key.filename
  description = "Local path to the generated private key file"
}
