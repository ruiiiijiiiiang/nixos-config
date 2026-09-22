data "aws_ami" "nixos" {
  most_recent = true
  owners      = ["427812963091"]

  filter {
    name   = "name"
    values = [var.nixos_ami_name_pattern]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ec2_instance_type_offerings" "edge" {
  location_type = "availability-zone"

  filter {
    name   = "instance-type"
    values = ["t3.micro"]
  }
}

locals {
  instance_type_availability_zones = sort(data.aws_ec2_instance_type_offerings.edge.locations)
  edge_availability_zone = var.availability_zone != null ? var.availability_zone : try(
    local.instance_type_availability_zones[0],
    null,
  )
}

resource "aws_key_pair" "bootstrap" {
  key_name   = "edge-production-bootstrap"
  public_key = var.bootstrap_ssh_public_key

  tags = {
    Name = "edge-production-bootstrap"
  }
}

resource "aws_instance" "edge" {
  ami                         = data.aws_ami.nixos.id
  instance_type               = "t3.micro"
  key_name                    = aws_key_pair.bootstrap.key_name
  subnet_id                   = aws_subnet.edge.id
  vpc_security_group_ids      = [aws_security_group.edge.id]
  associate_public_ip_address = true

  credit_specification {
    cpu_credits = "standard"
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "disabled"
  }

  root_block_device {
    encrypted             = true
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true

    tags = {
      Name = "edge-production-root"
    }
  }

  lifecycle {
    precondition {
      condition     = !var.bootstrap_ssh_enabled || var.bootstrap_operator_cidr != null
      error_message = "Bootstrap SSH requires bootstrap_operator_cidr."
    }
  }

  tags = {
    Name = "edge-production"
  }
}
