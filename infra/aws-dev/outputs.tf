output "instance_id" {
  value = aws_instance.dev.id
}

output "availability_zone" {
  value = aws_instance.dev.availability_zone
}

output "public_ip" {
  description = "Changes on every start; only for the bootstrap SSH. Day to day: ssh aws-dev over Tailscale."
  value       = aws_instance.dev.public_ip
}
