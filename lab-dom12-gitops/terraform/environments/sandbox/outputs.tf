output "app_url" {
  description = "App URL through the ALB"
  value       = module.alb.url
}

output "ecr_repository_url" {
  description = "ECR repository the pipeline pushes to"
  value       = module.ecr.repository_url
}

output "ecs_cluster_name" {
  value = module.ecs_service.cluster_name
}

output "ecs_service_name" {
  value = module.ecs_service.service_name
}

output "task_family" {
  value = module.ecs_service.task_family
}

output "log_group_name" {
  description = "CloudWatch Logs group for the app container"
  value       = module.ecs_service.log_group_name
}

output "github_deploy_role_arn" {
  description = "Role the GitHub Actions deploy job assumes via OIDC"
  value       = module.github_deploy_role.role_arn
}

output "dashboard_url" {
  value = "https://${data.aws_region.current.region}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.region}#dashboards/dashboard/${module.monitoring.dashboard_name}"
}

output "alarm_names" {
  value = module.monitoring.alarm_names
}

# Everything the pipeline needs, as one map - set these as variables on the
# GitHub "sandbox" environment (see README), or read them with
# `terraform output -json pipeline_config`.
output "pipeline_config" {
  description = "Values the CI pipeline needs to render the task definition and deploy"
  value = {
    AWS_REGION         = data.aws_region.current.region
    AWS_ROLE_ARN       = module.github_deploy_role.role_arn
    ECR_REPOSITORY_URL = module.ecr.repository_url
    ECS_CLUSTER        = module.ecs_service.cluster_name
    ECS_SERVICE        = module.ecs_service.service_name
    TASK_FAMILY        = module.ecs_service.task_family
    CONTAINER_NAME     = module.ecs_service.container_name
    CONTAINER_PORT     = tostring(module.ecs_service.container_port)
    EXECUTION_ROLE_ARN = module.ecs_service.execution_role_arn
    TASK_ROLE_ARN      = module.ecs_service.task_role_arn
    LOG_GROUP          = module.ecs_service.log_group_name
    TASK_CPU           = tostring(var.task_cpu)
    TASK_MEMORY        = tostring(var.task_memory)
    HEALTH_CHECK_PATH  = var.health_check_path
    APP_URL            = module.alb.url
  }
}
