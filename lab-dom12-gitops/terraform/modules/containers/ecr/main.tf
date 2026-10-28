resource "aws_ecr_repository" "this" {
  name = var.name

  # Every pipeline run pushes a unique <sha>-<run> tag, so a tag can never be
  # silently repointed at a different image after it has been scanned.
  image_tag_mutability = "IMMUTABLE"
  force_delete         = var.force_delete

  image_scanning_configuration {
    scan_on_push = true
  }

  # KMS rather than the default AES256, so key use is logged in CloudTrail.
  # A null kms_key_arn falls back to the AWS-managed aws/ecr key.
  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = var.kms_key_arn
  }

  tags = merge(var.tags, { Name = var.name })
}

resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images (failed/superseded pushes)"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.untagged_expiry_days
        }
        action = { type = "expire" }
      },
      {
        # tagStatus "any" must carry the highest rulePriority in the policy.
        rulePriority = 2
        description  = "Keep only the most recent ${var.keep_image_count} images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.keep_image_count
        }
        action = { type = "expire" }
      },
    ]
  })
}
