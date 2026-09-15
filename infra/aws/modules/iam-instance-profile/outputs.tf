output "instance_profile_name" {
  description = "Instance profile name to pass to the ec2 module (null when disabled)."
  value       = try(aws_iam_instance_profile.this[0].name, null)
}

output "role_arn" {
  description = "ARN of the IAM role (null when disabled)."
  value       = try(aws_iam_role.this[0].arn, null)
}
