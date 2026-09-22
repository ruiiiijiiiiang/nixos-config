locals {
  egress_rules = {
    dns_udp = {
      description = "DNS resolution"
      from_port   = 53
      protocol    = "udp"
      to_port     = 53
      cidr_blocks = [
        "0.0.0.0/0",
      ]
    }
    dns_tcp = {
      description = "DNS resolution fallback"
      from_port   = 53
      protocol    = "tcp"
      to_port     = 53
      cidr_blocks = [
        "0.0.0.0/0",
      ]
    }
    ntp = {
      description = "Time synchronization"
      from_port   = 123
      protocol    = "udp"
      to_port     = 123
      cidr_blocks = [
        "0.0.0.0/0",
      ]
    }
    https = {
      description = "Cloudflare Tunnel, Nix caches, encrypted backups, and external probes"
      from_port   = 443
      protocol    = "tcp"
      to_port     = 443
      cidr_blocks = [
        "0.0.0.0/0",
      ]
    }
    cloudflare_tunnel_tcp = {
      description = "Cloudflare Tunnel fallback transport"
      from_port   = 7844
      protocol    = "tcp"
      to_port     = 7844
      cidr_blocks = [
        "0.0.0.0/0",
      ]
    }
    cloudflare_tunnel_udp = {
      description = "Cloudflare Tunnel QUIC transport"
      from_port   = 7844
      protocol    = "udp"
      to_port     = 7844
      cidr_blocks = [
        "0.0.0.0/0",
      ]
    }
    wireguard = {
      description = "Home WireGuard endpoint (dynamic address)"
      from_port   = 51820
      protocol    = "udp"
      to_port     = 51820
      cidr_blocks = [
        "0.0.0.0/0",
      ]
    }
  }

}

resource "aws_security_group" "edge" {
  name        = "edge-production-edge"
  description = "Edge host: temporary bootstrap SSH only; all services use outbound-initiated tunnels."
  vpc_id      = aws_vpc.edge.id

  dynamic "ingress" {
    for_each = var.bootstrap_ssh_enabled && var.bootstrap_operator_cidr != null ? {
      bootstrap_ssh = {
        cidr_blocks = [var.bootstrap_operator_cidr]
      }
    } : {}

    content {
      description = "Temporary restricted bootstrap SSH; remove after WireGuard enrolment."
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  dynamic "egress" {
    for_each = local.egress_rules

    content {
      description = egress.value.description
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = try(egress.value.cidr_blocks, [])
    }
  }

  tags = {
    Name = "edge-production-edge"
  }
}
