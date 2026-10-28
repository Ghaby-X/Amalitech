terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.70"
    }
  }

  # Bucket created by ../../bootstrap (`terraform output backend_config`).
  backend "s3" {
    bucket       = "lab-dom12-tfstate-447558491229-eu-west-1"
    key          = "lab-dom12/sandbox/statefile"
    region       = "eu-west-1"
    encrypt      = true
    use_lockfile = true
  }

  required_version = ">= 1.15.8"
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = "lab-dom12-gitops"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Repository  = var.github_repository
    }
  }
}
