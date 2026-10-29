# Bootstrap: the S3 bucket (and its KMS key) that holds the remote state for
# every environment under ../environments. This root's own state is local -
# it is applied once, before anything else, and rarely touched again.
#
# Locking uses S3-native lock files (use_lockfile = true in each backend
# block), so no DynamoDB table is needed.

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  # Account ID + region keeps the name globally unique without a random suffix,
  # so the environments' backend blocks can name it deterministically.
  bucket_name = "${var.bucket_prefix}-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}"
}

# --- KMS key for state encryption ---

# The longest recovery window: a key deleted by mistake stays restorable for
# 30 days, and without it every environment's state is unreadable.
module "state_kms_key" {
  source = "../modules/security/kms_key"

  alias                   = var.bucket_prefix
  description             = "Encrypts Terraform state for ${var.bucket_prefix}"
  deletion_window_in_days = 30
}

# --- State bucket ---

#trivy:ignore:AWS-0089 Access logging would need a second bucket just for logs; CloudTrail data events cover state access auditing if needed.
resource "aws_s3_bucket" "state" {
  bucket = local.bucket_name

  # Losing this bucket loses every environment's state.
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_ownership_controls" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = module.state_kms_key.arn
    }
    # S3 Bucket Keys cut KMS request volume (and cost) for every state read/write.
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    id     = "limit-state-history"
    status = "Enabled"

    filter {}

    # Keep a short history of previous state versions for recovery.
    noncurrent_version_expiration {
      noncurrent_days           = var.noncurrent_version_retention_days
      newer_noncurrent_versions = var.noncurrent_versions_to_keep
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }

  depends_on = [aws_s3_bucket_versioning.state]
}

data "aws_iam_policy_document" "state_bucket" {
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    resources = [
      aws_s3_bucket.state.arn,
      "${aws_s3_bucket.state.arn}/*",
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "state" {
  bucket = aws_s3_bucket.state.id
  policy = data.aws_iam_policy_document.state_bucket.json

  depends_on = [aws_s3_bucket_public_access_block.state]
}
