locals {
  cloud_observe_alarm_name        = "cloud-observe-public-endpoint-unhealthy"
  cloud_observe_alarm_arn         = "arn:${data.aws_partition.current.partition}:cloudwatch:${var.aws_region}:${data.aws_caller_identity.current.account_id}:alarm:${local.cloud_observe_alarm_name}"
  cloud_observe_alerts_topic_name = "cloud-observe-alerts"
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

resource "aws_route53_health_check" "cloud_observe" {
  fqdn              = "ntfy.ruijiang.me"
  port              = 443
  type              = "HTTPS"
  resource_path     = "/v1/health"
  failure_threshold = 3
  request_interval  = 30
  enable_sni        = true
  measure_latency   = false

  tags = {
    Name = "cloud-observe-public-endpoint"
  }
}

resource "aws_sns_topic" "cloud_observe_alerts" {
  name = local.cloud_observe_alerts_topic_name
}

data "aws_iam_policy_document" "cloud_observe_alerts" {
  statement {
    sid    = "AllowAccountOwner"
    effect = "Allow"
    actions = [
      "SNS:GetTopicAttributes",
      "SNS:SetTopicAttributes",
      "SNS:AddPermission",
      "SNS:RemovePermission",
      "SNS:DeleteTopic",
      "SNS:Subscribe",
      "SNS:ListSubscriptionsByTopic",
      "SNS:Publish",
    ]
    resources = [aws_sns_topic.cloud_observe_alerts.arn]

    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid       = "AllowCloudWatchAlarm"
    effect    = "Allow"
    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.cloud_observe_alerts.arn]

    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [local.cloud_observe_alarm_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_sns_topic_policy" "cloud_observe_alerts" {
  arn    = aws_sns_topic.cloud_observe_alerts.arn
  policy = data.aws_iam_policy_document.cloud_observe_alerts.json
}

resource "aws_sns_topic_subscription" "cloud_observe_email" {
  topic_arn = aws_sns_topic.cloud_observe_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_metric_alarm" "cloud_observe_unhealthy" {
  alarm_name          = local.cloud_observe_alarm_name
  alarm_description   = "The public cloud-observe Ntfy health endpoint is unavailable."
  namespace           = "AWS/Route53"
  metric_name         = "HealthCheckStatus"
  dimensions          = { HealthCheckId = aws_route53_health_check.cloud_observe.id }
  statistic           = "Minimum"
  period              = 60
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  threshold           = 1
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "breaching"
  alarm_actions       = [aws_sns_topic.cloud_observe_alerts.arn]
  ok_actions          = [aws_sns_topic.cloud_observe_alerts.arn]

  depends_on = [aws_sns_topic_policy.cloud_observe_alerts]
}
