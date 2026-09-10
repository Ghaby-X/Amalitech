terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = var.region
}

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
