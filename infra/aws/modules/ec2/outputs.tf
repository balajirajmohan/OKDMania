output "instance_id" {
  description = "EC2 instance ID."
  value       = aws_instance.this.id
}

output "public_ip" {
  description = "Public IPv4 address (null if none assigned)."
  value       = aws_instance.this.public_ip
}

output "private_ip" {
  description = "Private IPv4 address."
  value       = aws_instance.this.private_ip
}

output "private_dns" {
  description = "Private DNS name."
  value       = aws_instance.this.private_dns
}

output "public_dns" {
  description = "Public DNS name (empty if no public IP)."
  value       = aws_instance.this.public_dns
}

output "availability_zone" {
  description = "AZ the instance landed in."
  value       = aws_instance.this.availability_zone
}
