# IAM role GitHub Actions assumes via OIDC to push images and deploy to ECS -
# short-lived credentials per job, nothing stored in GitHub secrets.

# The account's GitHub OIDC provider is shared across repos/labs, so it is
# looked up rather than owned by this stack.
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

data "aws_iam_policy_document" "trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Exact match, no wildcards: only jobs running in the listed GitHub
    # environments of this repo can assume the role - not other branches'
    # workflows, PRs from forks, or other repos in the account.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [for env in var.github_environments : "repo:${var.github_repository}:environment:${env}"]
    }
  }
}

resource "aws_iam_role" "this" {
  name                 = var.name
  description          = "Assumed by GitHub Actions (${var.github_repository}) via OIDC to push to ECR and deploy to ECS"
  assume_role_policy   = data.aws_iam_policy_document.trust.json
  max_session_duration = 3600

  tags = var.tags
}

data "aws_iam_policy_document" "deploy" {
  statement {
    sid       = "EcrAuth"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid = "EcrPushToAppRepo"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImageScanFindings",
      "ecr:DescribeImages",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:ListImages",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
    resources = [var.ecr_repository_arn]
  }

  # Task-definition actions are granted on "*": register/describe/list don't
  # take a family-scoped ARN, and the pipeline's revision cleanup
  # (deregister/delete) runs alongside them.
  statement {
    sid = "TaskDefinitions"
    actions = [
      "ecs:DeleteTaskDefinitions",
      "ecs:DeregisterTaskDefinition",
      "ecs:DescribeTaskDefinition",
      "ecs:ListTaskDefinitions",
      "ecs:RegisterTaskDefinition",
    ]
    resources = ["*"]
  }

  statement {
    sid = "DeployAppService"
    actions = [
      "ecs:DescribeServices",
      "ecs:UpdateService",
    ]
    resources = [var.ecs_service_arn]
  }

  statement {
    sid       = "InspectAppTasks"
    actions   = ["ecs:DescribeTasks"]
    resources = ["arn:aws:ecs:${var.region}:${var.account_id}:task/${var.ecs_cluster_name}/*"]
  }

  statement {
    sid       = "ListAppTasks"
    actions   = ["ecs:ListTasks"]
    resources = ["*"]
    condition {
      test     = "ArnEquals"
      variable = "ecs:cluster"
      values   = [var.ecs_cluster_arn]
    }
  }

  # Registering a task definition that names these roles requires passing
  # them - only to ECS tasks, and only these two.
  statement {
    sid       = "PassTaskRoles"
    actions   = ["iam:PassRole"]
    resources = var.pass_role_arns
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }

  # Read-only, for the pipeline's post-deploy verification and evidence.
  statement {
    sid = "VerifyDeployment"
    actions = [
      "cloudwatch:DescribeAlarms",
      "elasticloadbalancing:DescribeTargetHealth",
    ]
    resources = ["*"]
  }

  statement {
    sid = "ReadAppLogs"
    actions = [
      "logs:FilterLogEvents",
      "logs:GetLogEvents",
    ]
    resources = [
      var.app_log_group_arn,
      "${var.app_log_group_arn}:*",
    ]
  }
}

resource "aws_iam_role_policy" "deploy" {
  name   = "ecr-push-ecs-deploy"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.deploy.json
}
