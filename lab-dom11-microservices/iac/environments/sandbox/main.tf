module "networking" {
  source = "../../modules/networking"

  project_name = var.project_name
}

module "ecr" {
  source = "../../modules/ecr"

  project_name = var.project_name
}

module "security" {
  source = "../../modules/security"

  project_name = var.project_name
  vpc_id       = module.networking.vpc_id
}

module "secrets" {
  source = "../../modules/secrets"

  project_name = var.project_name
}

module "iam" {
  source = "../../modules/iam"

  project_name = var.project_name
  ssm_parameter_arns = [
    module.secrets.postgres_password_arn,
    module.secrets.redis_password_arn,
    module.secrets.frontend_secret_key_arn,
  ]
}

module "storage" {
  source = "../../modules/storage"

  project_name          = var.project_name
  private_subnet_ids    = module.networking.private_subnet_ids
  efs_security_group_id = module.security.efs_security_group_id
}

module "ecs" {
  source = "../../modules/ecs"

  project_name               = var.project_name
  vpc_id                     = module.networking.vpc_id
  public_subnet_ids          = module.networking.public_subnet_ids
  private_subnet_ids         = module.networking.private_subnet_ids
  alb_security_group_id      = module.security.alb_security_group_id
  frontend_security_group_id = module.security.frontend_security_group_id
  backend_security_group_id  = module.security.backend_security_group_id
  postgres_security_group_id = module.security.postgres_security_group_id
  redis_security_group_id    = module.security.redis_security_group_id
}
