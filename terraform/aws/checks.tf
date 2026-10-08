check "edge_running" {
  data "aws_instance" "edge_live" {
    instance_tags = {
      Name        = "edge-production"
      Project     = "edge"
      Environment = "production"
      ManagedBy   = "terraform"
    }

    filter {
      name   = "instance-state-name"
      values = ["pending", "running", "stopping", "stopped"]
    }
  }

  assert {
    condition     = data.aws_instance.edge_live.instance_state == "running"
    error_message = "The deployed edge EC2 instance is not running."
  }
}

check "ntfy_health" {
  data "http" "ntfy_health" {
    url                = "https://${aws_route53_health_check.cloud_observe.fqdn}${aws_route53_health_check.cloud_observe.resource_path}"
    request_timeout_ms = 10000

    retry {
      attempts     = 2
      min_delay_ms = 1000
      max_delay_ms = 3000
    }
  }

  assert {
    condition     = data.http.ntfy_health.status_code == 200
    error_message = "The public Ntfy health endpoint did not return HTTP 200."
  }
}
