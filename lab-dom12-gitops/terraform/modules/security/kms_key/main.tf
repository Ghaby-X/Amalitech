data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.region
}

data "aws_iam_policy_document" "this" {
  # Delegate key access to IAM in this account - without this statement the
  # key would only be usable by principals named in the key policy itself.
  statement {
    sid       = "EnableIAMPolicies"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_id}:root"]
    }
  }

  # CloudWatch Logs encrypting log groups - only log groups in this account
  # and region.
  dynamic "statement" {
    for_each = var.allow_cloudwatch_logs ? [1] : []
    content {
      sid = "CloudWatchLogs"
      actions = [
        "kms:Decrypt*",
        "kms:Describe*",
        "kms:Encrypt*",
        "kms:GenerateDataKey*",
        "kms:ReEncrypt*",
      ]
      resources = ["*"]
      principals {
        type        = "Service"
        identifiers = ["logs.${local.region}.amazonaws.com"]
      }
      condition {
        test     = "ArnLike"
        variable = "kms:EncryptionContext:aws:logs:arn"
        values   = ["arn:aws:logs:${local.region}:${local.account_id}:log-group:*"]
      }
    }
  }

  # Services publishing to an SNS topic encrypted with this key (e.g.
  # CloudWatch alarms, EventBridge) need to generate data keys with it.
  dynamic "statement" {
    for_each = length(var.sns_publisher_service_principals) > 0 ? [1] : []
    content {
      sid = "PublishToEncryptedTopics"
      actions = [
        "kms:Decrypt",
        "kms:GenerateDataKey*",
      ]
      resources = ["*"]
      principals {
        type        = "Service"
        identifiers = var.sns_publisher_service_principals
      }
      condition {
        test     = "StringEquals"
        variable = "aws:SourceAccount"
        values   = [local.account_id]
      }
    }
  }
}

resource "aws_kms_key" "this" {
  description             = var.description
  enable_key_rotation     = true
  deletion_window_in_days = var.deletion_window_in_days
  policy                  = data.aws_iam_policy_document.this.json

  tags = var.tags
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.alias}"
  target_key_id = aws_kms_key.this.key_id
}
