variable "aws_account_id" {
  type        = string
  description = "AWS account containing the GitHub Actions plan roles."
}

variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare zone ID used by the DNS plan workflow."
}
