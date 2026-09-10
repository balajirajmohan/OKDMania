variable "aws_region" {
  description = "AWS region for the Terraform state bucket and lock table."
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_name" {
  description = <<-EOT
    Globally unique S3 bucket name for Terraform state.
    Convention: okd-test-terraform-state-<unique-suffix> (e.g. your AWS account
    id or initials). S3 bucket names are global, so pick something unlikely to
    collide.
  EOT
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.state_bucket_name))
    error_message = "state_bucket_name must be a valid S3 bucket name (lowercase, 3-63 chars)."
  }
}

variable "lock_table_name" {
  description = "DynamoDB table name for Terraform state locking (legacy mechanism - see README)."
  type        = string
  default     = "okd-terraform-lock"
}

variable "force_destroy_state_bucket" {
  description = <<-EOT
    Allow `terraform destroy` to delete the state bucket even if it still holds
    state file versions. Keep false in normal use; set true only when you are
    deliberately tearing the whole project down.
  EOT
  type        = bool
  default     = false
}
