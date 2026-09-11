output "state_bucket_name" {
  description = "S3 bucket that holds Terraform state. Put this in infra/aws/backend.tf."
  value       = aws_s3_bucket.state.id
}

output "state_bucket_arn" {
  description = "ARN of the Terraform state bucket."
  value       = aws_s3_bucket.state.arn
}

output "aws_region" {
  description = "Region the backend resources live in."
  value       = var.aws_region
}

output "backend_config_snippet" {
  description = "Paste this into infra/aws/backend.tf."
  value       = <<-EOT
    terraform {
      backend "s3" {
        bucket       = "${aws_s3_bucket.state.id}"
        key          = "okd/terraform.tfstate"
        region       = "${var.aws_region}"
        encrypt      = true
        use_lockfile = true
      }
    }
  EOT
}
