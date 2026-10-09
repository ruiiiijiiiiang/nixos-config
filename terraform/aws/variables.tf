variable "aws_region" {
  type        = string
  description = "AWS region in which to create the edge host."
}

variable "availability_zone" {
  type        = string
  description = "Optional availability zone for the public subnet and instance. Terraform selects the first zone offering t3.micro when null."
}

variable "vpc_cidr" {
  type        = string
  description = "IPv4 CIDR for the dedicated edge VPC."
}

variable "nixos_ami_name_pattern" {
  type        = string
  description = "Name filter for the official x86_64 NixOS AMI. Review the selected AMI in every Terraform plan."
}

variable "alert_email" {
  type        = string
  description = "Email address for cloud-observe outage and recovery alerts. The SNS subscription must be confirmed from this inbox."
}

variable "bootstrap_ssh_public_key" {
  type        = string
  default     = null
  sensitive   = true
  description = "Optional operator SSH public key for bootstrapping a new edge instance."

  validation {
    condition     = var.bootstrap_ssh_public_key == null ? true : length(trimspace(var.bootstrap_ssh_public_key)) > 0
    error_message = "bootstrap_ssh_public_key must be a non-empty public key when set."
  }
}

variable "bootstrap_operator_cidr" {
  type        = string
  description = "Optional operator IPv4 CIDR permitted to SSH during bootstrap, for example 203.0.113.10/32. Required for IPv4 bootstrap."
}

variable "bootstrap_ssh_enabled" {
  type        = bool
  description = "Whether to create the temporary TCP/22 bootstrap ingress rule during host enrolment."
}
