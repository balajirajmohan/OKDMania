output "key_name" {
  description = "Name of the EC2 key pair (pass to aws_instance.key_name)."
  value       = data.aws_key_pair.this.key_name
}

output "key_pair_id" {
  description = "ID of the EC2 key pair."
  value       = data.aws_key_pair.this.key_pair_id
}

output "fingerprint" {
  description = "Fingerprint of the key pair's public key."
  value       = data.aws_key_pair.this.fingerprint
}
