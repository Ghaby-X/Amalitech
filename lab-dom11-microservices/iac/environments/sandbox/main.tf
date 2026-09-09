terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
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

module "iam" {
  source = "../../modules/iam"

  project_name = var.project_name
}

module "storage" {
  source = "../../modules/storage"

  project_name          = var.project_name
  private_subnet_ids    = module.networking.private_subnet_ids
  efs_security_group_id = module.security.efs_security_group_id
}
