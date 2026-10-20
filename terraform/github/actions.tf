locals {
  repository = "nixos-config"
}

resource "github_actions_variable" "tf_state_bucket" {
  repository    = local.repository
  variable_name = "TF_STATE_BUCKET"
  value         = var.tf_state_bucket
}

resource "github_actions_variable" "tf_state_region" {
  repository    = local.repository
  variable_name = "TF_STATE_REGION"
  value         = var.tf_state_region
}

resource "github_actions_variable" "edge_plan_role_arn" {
  repository    = local.repository
  variable_name = "EDGE_TERRAFORM_PLAN_ROLE_ARN"
  value         = "arn:aws:iam::${var.aws_account_id}:role/github-edge-terraform-plan"
}

resource "github_actions_variable" "cloudflare_dns_plan_role_arn" {
  repository    = local.repository
  variable_name = "CLOUDFLARE_DNS_TERRAFORM_PLAN_ROLE_ARN"
  value         = "arn:aws:iam::${var.aws_account_id}:role/github-cloudflare-dns-terraform-plan"
}

resource "github_actions_variable" "cloudflare_zone_id" {
  repository    = local.repository
  variable_name = "CLOUDFLARE_DNS_ZONE_ID"
  value         = var.cloudflare_zone_id
}
