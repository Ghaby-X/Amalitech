# --- Security ---

# One customer-managed key for the environment's data at rest: ECR images,
# every log group, and the SNS alarm topic.
module "kms_key" {
  source = "../../modules/security/kms_key"

  alias                   = local.name
  description             = "${local.name} - ECR, CloudWatch Logs and SNS encryption"
  deletion_window_in_days = 7
  allow_cloudwatch_logs   = true
  # CloudWatch alarms and EventBridge publish to the encrypted SNS topic.
  sns_publisher_service_principals = ["cloudwatch.amazonaws.com", "events.amazonaws.com"]
}

# --- Networking ---

module "vpc" {
  source = "../../modules/networking/vpc"

  name                       = local.name
  cidr_block                 = var.vpc_cidr_block
  azs                        = local.azs
  public_subnet_cidr_blocks  = var.public_subnet_cidr_blocks
  private_subnet_cidr_blocks = var.private_subnet_cidr_blocks

  flow_logs_log_group_name = "/lab-dom12/${var.environment}/vpc-flow-logs"
  flow_logs_retention_days = var.log_retention_days
  kms_key_arn              = module.kms_key.arn
}

module "security_groups" {
  source = "../../modules/networking/security_groups"

  name             = local.name
  vpc_id           = module.vpc.vpc_id
  app_port         = var.app_port
  alb_ingress_cidr = var.alb_ingress_cidr
}

# Private subnets have no internet route - the tasks reach ECR and
# CloudWatch Logs only through these.
module "vpc_endpoints" {
  source = "../../modules/networking/vpc_endpoints"

  name                    = local.name
  vpc_id                  = module.vpc.vpc_id
  subnet_ids              = module.vpc.private_subnet_ids
  gateway_route_table_ids = [module.vpc.private_route_table_id]
  security_group_ids      = [module.security_groups.vpc_endpoints_security_group_id]
}

module "alb" {
  source = "../../modules/networking/alb"

  name               = "${local.name}-alb"
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [module.security_groups.alb_security_group_id]
  target_port        = var.app_port
  health_check_path  = var.health_check_path
}

# --- Containers ---

module "ecr" {
  source = "../../modules/containers/ecr"

  name             = "lab-dom12/server-details"
  keep_image_count = var.ecr_keep_image_count
  kms_key_arn      = module.kms_key.arn
  # Sandbox: let `terraform destroy` remove the repo along with its images.
  force_delete = true
}

module "ecs_service" {
  source = "../../modules/containers/ecs_service"

  cluster_name      = local.cluster_name
  service_name      = local.service_name
  task_family       = local.service_name
  container_name    = local.container_name
  container_port    = var.app_port
  health_check_path = var.health_check_path
  task_cpu          = var.task_cpu
  task_memory       = var.task_memory

  ecr_repository_url = module.ecr.repository_url
  ecr_repository_arn = module.ecr.repository_arn

  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.security_groups.app_security_group_id]
  # Only exposed by the alb module once a listener forwards to it.
  target_group_arn = module.alb.target_group_arn

  log_group_name     = "/lab-dom12/${var.environment}/app"
  log_retention_days = var.log_retention_days
  kms_key_arn        = module.kms_key.arn

  deployment_alarm_names = module.monitoring.deployment_alarm_names

  # Tasks can't pull their image until the endpoints exist.
  depends_on = [module.vpc_endpoints]
}

# --- Observability ---

module "monitoring" {
  source = "../../modules/observability/monitoring"

  name_prefix = local.name
  account_id  = local.account_id

  alb_arn_suffix          = module.alb.arn_suffix
  target_group_arn_suffix = module.alb.target_group_arn_suffix

  # Names come from locals, not module.ecs_service outputs: the service takes
  # this module's alarm names as deployment alarms, so referencing its outputs
  # here too would be a cycle.
  cluster_name = local.cluster_name
  service_name = local.service_name
  service_arn  = "arn:aws:ecs:${local.region}:${local.account_id}:service/${local.cluster_name}/${local.service_name}"

  # Referenced (not retyped) so the log metric filter waits for the group.
  app_log_group_name = module.ecs_service.log_group_name
  metric_namespace   = "lab-dom12/${var.environment}"
  alarm_email        = var.alarm_email
  kms_key_arn        = module.kms_key.arn
  log_retention_days = var.log_retention_days
}

# --- CI ---

module "github_deploy_role" {
  source = "../../modules/security/github_deploy_role"

  name                = "${local.name}-github-deploy"
  github_repository   = var.github_repository
  github_environments = [var.environment]
  region              = local.region
  account_id          = local.account_id

  ecr_repository_arn = module.ecr.repository_arn
  ecs_cluster_name   = module.ecs_service.cluster_name
  ecs_cluster_arn    = module.ecs_service.cluster_arn
  ecs_service_arn    = module.ecs_service.service_arn
  pass_role_arns = [
    module.ecs_service.execution_role_arn,
    module.ecs_service.task_role_arn,
  ]
  app_log_group_arn = module.ecs_service.log_group_arn
}
