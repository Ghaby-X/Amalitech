# --- App instance: lets the awslogs Docker log driver ship container logs to CloudWatch ---

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "app_logs_role" {
  name               = "${var.app_instance_name}-logs-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

data "aws_iam_policy_document" "app_write_logs" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
      "logs:DescribeLogGroups",
    ]
    resources = [
      aws_cloudwatch_log_group.app.arn,
      "${aws_cloudwatch_log_group.app.arn}:*",
    ]
  }
}

resource "aws_iam_role_policy" "app_write_logs" {
  name   = "write-app-logs"
  role   = aws_iam_role.app_logs_role.id
  policy = data.aws_iam_policy_document.app_write_logs.json
}

resource "aws_iam_instance_profile" "app_logs_profile" {
  name = "${var.app_instance_name}-logs-profile"
  role = aws_iam_role.app_logs_role.name
}

# --- CloudTrail: lets the trail deliver logs to a CloudWatch Logs group ---

data "aws_iam_policy_document" "cloudtrail_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cloudtrail_cloudwatch_role" {
  name               = "lab-dom08-cloudtrail-cloudwatch-role"
  assume_role_policy = data.aws_iam_policy_document.cloudtrail_assume_role.json
}

data "aws_iam_policy_document" "cloudtrail_write_logs" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["${aws_cloudwatch_log_group.cloudtrail.arn}:*"]
  }
}

resource "aws_iam_role_policy" "cloudtrail_write_logs" {
  name   = "write-cloudtrail-logs"
  role   = aws_iam_role.cloudtrail_cloudwatch_role.id
  policy = data.aws_iam_policy_document.cloudtrail_write_logs.json
}
