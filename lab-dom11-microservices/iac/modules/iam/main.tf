# One shared execution role for all four task definitions.
data "aws_iam_policy_document" "ecs_tasks_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution" {
  name               = "${var.project_name}-ecs-task-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json

  tags = { Name = "${var.project_name}-ecs-task-execution" }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Add ssm read parameters and kms decrypt to pull and decrypt image 
# from secret manager.
data "aws_kms_alias" "ssm" {
  count = length(var.ssm_parameter_arns) > 0 ? 1 : 0
  name  = "alias/aws/ssm"
}

data "aws_iam_policy_document" "read_ssm_parameters" {
  count = length(var.ssm_parameter_arns) > 0 ? 1 : 0

  statement {
    effect    = "Allow"
    actions   = ["ssm:GetParameters"]
    resources = var.ssm_parameter_arns
  }

  statement {
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [data.aws_kms_alias.ssm[0].target_key_arn]
  }
}

resource "aws_iam_role_policy" "read_ssm_parameters" {
  count = length(var.ssm_parameter_arns) > 0 ? 1 : 0

  name   = "${var.project_name}-read-ssm-parameters"
  role   = aws_iam_role.ecs_task_execution.id
  policy = data.aws_iam_policy_document.read_ssm_parameters[0].json
}
