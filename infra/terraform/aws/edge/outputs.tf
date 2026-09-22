output "public_address" {
  description = "Temporary public IPv4 address."
  value       = aws_instance.edge.public_ip
}

output "instance_id" {
  description = "Provider-created instance identity."
  value       = aws_instance.edge.id
}

output "region_or_zone" {
  description = "Provider-neutral placement identifier."
  value       = aws_subnet.edge.availability_zone
}

output "vpc_id" {
  description = "AWS VPC identifier for operational use."
  value       = aws_vpc.edge.id
}
