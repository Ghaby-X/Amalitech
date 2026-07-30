terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket       = "terraform-backend-eu-west-1-55zz0s"
    key          = "lab-dom03/statefile"
    region       = "eu-west-1"
    use_lockfile = true
  }

  required_version = "~> 1.15.8"
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = "lab-dom04-IAC"
      Category = "lab"
      ManagedBy = "Terraform"
    }
  }
}
