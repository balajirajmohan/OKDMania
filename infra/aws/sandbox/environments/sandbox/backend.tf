# ===========================================================================
# Remote state backend  (spec sections 10 & 11)
# ===========================================================================
# Run infra/aws/sandbox/bootstrap first, then replace the bucket name below
# with its `state_bucket_name` output (or pass -backend-config at init time).
#
# Locking: `use_lockfile = true` is Terraform's native S3 locking (1.11+) - it
# needs no DynamoDB table. The bootstrap stack still creates the
# `okd-terraform-lock` table; to use it instead, comment `use_lockfile` and
# uncomment `dynamodb_table`, then `terraform init -reconfigure`.
# ===========================================================================

terraform {
  backend "s3" {
    bucket       = "okd-test-terraform-state-853973692277" # bootstrap output: state_bucket_name
    key          = "okd-sandbox/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
    # dynamodb_table = "okd-terraform-lock"   # legacy locking alternative
  }
}
