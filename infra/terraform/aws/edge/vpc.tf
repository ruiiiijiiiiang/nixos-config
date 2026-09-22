locals {
  public_subnet_cidr = cidrsubnet(var.vpc_cidr, 4, 0)
}

resource "aws_vpc" "edge" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "edge-production"
  }
}

resource "aws_internet_gateway" "edge" {
  vpc_id = aws_vpc.edge.id

  tags = {
    Name = "edge-production"
  }
}

resource "aws_subnet" "edge" {
  vpc_id                  = aws_vpc.edge.id
  cidr_block              = local.public_subnet_cidr
  availability_zone       = local.edge_availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "edge-production-public"
  }

  lifecycle {
    precondition {
      condition     = local.edge_availability_zone != null
      error_message = "No availability zone offers the selected instance type in this region."
    }
    precondition {
      condition     = contains(local.instance_type_availability_zones, local.edge_availability_zone)
      error_message = "The selected instance type is not offered in the requested availability zone."
    }
  }
}

resource "aws_route_table" "edge" {
  vpc_id = aws_vpc.edge.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.edge.id
  }

  tags = {
    Name = "edge-production-public"
  }
}

resource "aws_route_table_association" "edge" {
  subnet_id      = aws_subnet.edge.id
  route_table_id = aws_route_table.edge.id
}
