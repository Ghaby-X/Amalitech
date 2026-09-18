module "networking" {
  source = "../../modules/networking"

  project_name = var.project_name
}

module "ecr" {
  source = "../../modules/ecr"

  project_name = var.project_name
}

module "eks" {
  source = "../../modules/eks"

  project_name       = var.project_name
  public_subnet_ids  = module.networking.public_subnet_ids
  private_subnet_ids = module.networking.private_subnet_ids
}

module "security" {
  source = "../../modules/security"

  project_name                  = var.project_name
  vpc_id                        = module.networking.vpc_id
  eks_cluster_security_group_id = module.eks.cluster_security_group_id
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

module "rds" {
  source = "../../modules/rds"

  project_name       = var.project_name
  private_subnet_ids = module.networking.private_subnet_ids
  security_group_id  = module.security.postgres_security_group_id
  master_password    = module.secrets.postgres_password
}

module "elasticache" {
  source = "../../modules/elasticache"

  project_name       = var.project_name
  private_subnet_ids = module.networking.private_subnet_ids
  security_group_id  = module.security.redis_security_group_id
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
