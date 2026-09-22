variable "aws_region" {
  type        = string
  description = "AWS region in which to create the edge host."
}

variable "availability_zone" {
  type        = string
  default     = null
  description = "Optional availability zone for the public subnet and instance. Terraform selects the first zone offering t3.micro when null."
}

variable "vpc_cidr" {
  type        = string
  default     = "10.42.0.0/20"
  description = "IPv4 CIDR for the dedicated edge VPC."
}

variable "nixos_ami_name_pattern" {
  type        = string
  default     = "nixos/25.11*"
  description = "Name filter for the official x86_64 NixOS AMI. Review the selected AMI in every Terraform plan."
}

variable "bootstrap_ssh_public_key" {
  type        = string
  sensitive   = true
  description = "Temporary operator SSH public key used only during host enrolment."
}

variable "bootstrap_operator_cidr" {
  type        = string
  default     = null
  description = "Optional operator IPv4 CIDR permitted to SSH during bootstrap, for example 203.0.113.10/32. Required for IPv4 bootstrap."
}

variable "bootstrap_ssh_enabled" {
  type        = bool
  default     = true
  description = "Whether to create the temporary TCP/22 bootstrap ingress rule. Set false after WireGuard enrolment succeeds."
}
