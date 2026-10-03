resource "aws_iam_role" "edge" {
  name = "edge-production-ssm"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "edge-production-ssm"
  }
}

resource "aws_iam_role_policy_attachment" "edge_ssm" {
  role       = aws_iam_role.edge.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "edge" {
  name = "edge-production-ssm"
  role = aws_iam_role.edge.name

  tags = {
    Name = "edge-production-ssm"
  }
}

locals {
  github_edge_plan_name          = "github-edge-terraform-plan"
  github_edge_plan_role_arn      = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${local.github_edge_plan_name}"
  github_edge_plan_policy_arn    = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:policy/${local.github_edge_plan_name}"
  cloud_observe_alerts_topic_arn = "arn:${data.aws_partition.current.partition}:sns:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${local.cloud_observe_alerts_topic_name}"
}

resource "aws_iam_role" "github_edge_plan" {
  name                 = local.github_edge_plan_name
  path                 = "/"
  max_session_duration = 3600

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:sub" = "repo:ruiiiijiiiiang/nixos-config:ref:refs/heads/master"
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  lifecycle {
    prevent_destroy = true
  }
}

data "aws_iam_policy_document" "github_edge_plan" {
  statement {
    sid       = "ListTerraformStateBucket"
    actions   = ["s3:ListBucket"]
    resources = ["arn:${data.aws_partition.current.partition}:s3:::rui-terraform-state-997229934634-us-east-1"]
  }

  statement {
    sid = "AccessTerraformState"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:s3:::rui-terraform-state-997229934634-us-east-1/edge/aws/terraform.tfstate"]
  }

  statement {
    sid = "UseTerraformStateLock"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:s3:::rui-terraform-state-997229934634-us-east-1/edge/aws/terraform.tfstate.tflock"]
  }

  statement {
    sid       = "DescribeEdgeEC2Resources"
    actions   = ["ec2:Describe*"]
    resources = ["*"]
  }

  statement {
    sid = "ReadEdgeIAMResources"
    actions = [
      "iam:Get*",
      "iam:List*",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/edge-production-ssm",
      "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:instance-profile/edge-production-ssm",
      local.github_edge_plan_role_arn,
      local.github_edge_plan_policy_arn,
    ]
  }

  statement {
    sid = "ReadCloudObserveHealthChecks"
    actions = [
      "route53:Get*",
      "route53:List*",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:route53:::healthcheck/*"]
  }

  statement {
    sid = "ReadCloudWatch"
    actions = [
      "cloudwatch:Describe*",
      "cloudwatch:List*",
    ]
    resources = ["*"]
  }

  statement {
    sid = "ReadCloudObserveSNSTopic"
    actions = [
      "sns:Get*",
      "sns:List*",
    ]
    resources = [local.cloud_observe_alerts_topic_arn]
  }
}

resource "aws_iam_policy" "github_edge_plan" {
  name   = local.github_edge_plan_name
  path   = "/"
  policy = data.aws_iam_policy_document.github_edge_plan.json

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "github_edge_plan" {
  role       = aws_iam_role.github_edge_plan.name
  policy_arn = aws_iam_policy.github_edge_plan.arn
}
