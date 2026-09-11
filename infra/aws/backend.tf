# ===========================================================================
# Remote state backend
# ===========================================================================
# Run infra/aws/bootstrap first; the bucket name below is its
# `state_bucket_name` output.
#
# Locking: `use_lockfile = true` is Terraform's native S3 locking (1.11+) -
# no DynamoDB table involved.
# ===========================================================================

terraform {
  backend "s3" {
    bucket       = "okd-terraform-state-853973692277" # bootstrap output: state_bucket_name
    key          = "okd/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
