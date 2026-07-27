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
