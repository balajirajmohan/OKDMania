resource "aws_ssm_parameter" "runner_token" {
  name        = "/okdmania/github-runner/registration-token"
  description = "One-hour GitHub Actions registration token. Instance deletes this after config.sh succeeds."
  type        = "SecureString"
  value       = var.github_runner_token

  lifecycle {
    # Token is burned on first boot. Do not try to keep it in sync.
    ignore_changes = [value]
  }
}
