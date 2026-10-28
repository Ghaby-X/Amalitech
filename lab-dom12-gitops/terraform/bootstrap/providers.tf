terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.70"
    }
  }

  # Local state on purpose - this root creates the remote backend everything
  # else uses. Keep terraform.tfstate safe (it is gitignored); losing it only
  # means re-importing the bucket and key, not losing environment state.

  required_version = ">= 1.15.8"
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = "lab-dom12-gitops"
      Component = "terraform-state"
      ManagedBy = "Terraform"
    }
  }
}
