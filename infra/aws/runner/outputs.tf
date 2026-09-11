output "instance_id" {
  value       = aws_instance.runner.id
  description = "SSM target: aws ssm start-session --target <this>"
}

output "public_ip" {
  value       = aws_instance.runner.public_ip
  description = "Public IP for outbound identity only. No inbound ports are open."
}

output "iam_role_name" {
  value = aws_iam_role.runner.name
}

output "runs_on" {
  value       = "[self-hosted, linux, x64, aws, okdmania]"
  description = "Copy into workflow jobs after the runner shows Idle in GitHub."
}

output "ssm_connect" {
  value = "aws ssm start-session --target ${aws_instance.runner.id} --region ${var.aws_region}"
}
