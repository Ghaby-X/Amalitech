terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
  required_version = "~> 1.15.8"
}

# creating providers
provider "aws" {
  region = var.region
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

locals {
  bucket_name = format("%s-%s-%s", var.bucket-prefix, var.region, random_string.suffix.result)
}

# -------------------------------------------
# create s3 bucket
# -------------------------------------------
resource "aws_s3_bucket" "backend" {
  bucket = local.bucket_name
}

resource "aws_s3_bucket_versioning" "backend" {
  bucket = aws_s3_bucket.backend.id
  versioning_configuration {
    status = "Enabled"
  }
}

# encrypt state file
resource "aws_s3_bucket_server_side_encryption_configuration" "backend" {
  bucket = aws_s3_bucket.backend.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "backend" {
  bucket = aws_s3_bucket.backend.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true 
  restrict_public_buckets = true
}

# -------------------------------------------
# create dynamodb
# -------------------------------------------
resource "aws_dynamodb_table" "terraform_locks" {
  name         = var.dynamodb-name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
