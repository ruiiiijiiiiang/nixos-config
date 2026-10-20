variable "aws_account_id" {
  type        = string
  description = "AWS account containing the GitHub Actions plan roles."
}

variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare zone ID used by the DNS plan workflow."
}

variable "tf_state_bucket" {
  type        = string
  description = "S3 bucket containing the Terraform state used by the plan workflows."
}

variable "tf_state_region" {
  type        = string
  description = "AWS region of the Terraform state bucket used by the plan workflows."
}
