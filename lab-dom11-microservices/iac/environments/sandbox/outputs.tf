# networking

output "vpc_id" {
  value = module.networking.vpc_id
}

output "vpc_cidr_block" {
  value = module.networking.vpc_cidr_block
}

output "public_subnet_ids" {
  value = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.networking.private_subnet_ids
}

#  ecr 

output "ecr_repository_urls" {
  value = module.ecr.repository_urls
}

#  security 

output "alb_security_group_id" {
  value = module.security.alb_security_group_id
}

output "frontend_security_group_id" {
  value = module.security.frontend_security_group_id
}

output "backend_security_group_id" {
  value = module.security.backend_security_group_id
}

output "postgres_security_group_id" {
  value = module.security.postgres_security_group_id
}

output "redis_security_group_id" {
  value = module.security.redis_security_group_id
}

output "efs_security_group_id" {
  value = module.security.efs_security_group_id
}

#  secrets 
output "postgres_password_parameter" {
  value = module.secrets.postgres_password_name
}

output "redis_password_parameter" {
  value = module.secrets.redis_password_name
}

output "frontend_secret_key_parameter" {
  value = module.secrets.frontend_secret_key_name
}

#  iam 

output "ecs_task_execution_role_arn" {
  value = module.iam.ecs_task_execution_role_arn
}

#  storage 

output "postgres_efs_file_system_id" {
  value = module.storage.postgres_file_system_id
}

output "postgres_efs_access_point_id" {
  value = module.storage.postgres_access_point_id
}

#  ecs 

output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}

output "service_discovery_namespace" {
  value = "${var.project_name}.local"
}
