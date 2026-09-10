output "state_bucket_name" {
  description = "S3 bucket that holds Terraform state. Put this in environments/sandbox/backend.tf."
  value       = aws_s3_bucket.state.id
}

output "state_bucket_arn" {
  description = "ARN of the Terraform state bucket."
  value       = aws_s3_bucket.state.arn
}

output "lock_table_name" {
  description = "DynamoDB table for Terraform state locking (optional / legacy - see README)."
  value       = aws_dynamodb_table.lock.name
}

output "aws_region" {
  description = "Region the backend resources live in."
  value       = var.aws_region
}

output "backend_config_snippet" {
  description = "Paste this into environments/sandbox/backend.tf (native S3 locking)."
  value       = <<-EOT
    terraform {
      backend "s3" {
        bucket       = "${aws_s3_bucket.state.id}"
        key          = "okd-sandbox/terraform.tfstate"
        region       = "${var.aws_region}"
        encrypt      = true
        use_lockfile = true
        # dynamodb_table = "${aws_dynamodb_table.lock.name}"  # legacy alternative to use_lockfile
      }
    }
  EOT
}
