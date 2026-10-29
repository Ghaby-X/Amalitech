output "vpc_id" {
  description = "ID of the VPC."
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC."
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = module.public_subnets.subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = module.private_subnets.subnet_ids
}

output "private_route_table_id" {
  description = "ID of the private subnets' route table - for gateway VPC endpoints."
  value       = module.private_route_table.route_table_id
}

output "flow_logs_log_group_name" {
  description = "CloudWatch Logs group holding the VPC flow logs."
  value       = aws_cloudwatch_log_group.flow_logs.name
}
