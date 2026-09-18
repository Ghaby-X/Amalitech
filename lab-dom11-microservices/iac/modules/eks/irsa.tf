# IRSA role for the AWS Load Balancer Controller, trusted via the cluster's OIDC provider.
data "aws_iam_policy_document" "lb_controller_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lb_controller" {
  name               = "${var.project_name}-eks-lb-controller"
  assume_role_policy = data.aws_iam_policy_document.lb_controller_assume_role.json

  tags = { Name = "${var.project_name}-eks-lb-controller" }
}

# official policy from kubernetes-sigs/aws-load-balancer-controller docs/install/iam_policy.json
resource "aws_iam_policy" "lb_controller" {
  name   = "${var.project_name}-eks-lb-controller"
  policy = file("${path.module}/lb_controller_iam_policy.json")
}

resource "aws_iam_role_policy_attachment" "lb_controller" {
  role       = aws_iam_role.lb_controller.name
  policy_arn = aws_iam_policy.lb_controller.arn
}
