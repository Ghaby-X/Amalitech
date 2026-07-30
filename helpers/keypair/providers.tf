terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }

  backend "s3" {
    bucket       = "terraform-backend-eu-west-1-55zz0s"
    key          = "helpers/keypair/statefile"
    region       = "eu-west-1"
    use_lockfile = true
  }

  required_version = "~> 1.15.8"
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = "terraform"
      ManagedBy = "Terraform"
      Category  = "lab"
    }
  }
}
