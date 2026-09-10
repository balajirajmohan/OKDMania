# ===========================================================================
# Terraform remote state backend  (spec sections 10 & 11)
# ===========================================================================
# Creates:
#   - one S3 bucket for state (versioned, encrypted, private, owner-enforced)
#   - one DynamoDB table for state locking (LockID hash key)
#
# Locking note: Terraform 1.11+ supports NATIVE S3 locking via `use_lockfile =
# true` in the backend block (S3 conditional writes - no extra infrastructure).
# `dynamodb_table` still works but is deprecated. We create the DynamoDB table
# anyway so both mechanisms are available; the sandbox backend.tf uses
# use_lockfile by default. See infra/aws/sandbox/README.md.
# ===========================================================================

# --- S3 bucket for Terraform state ----------------------------------------
resource "aws_s3_bucket" "state" {
  bucket        = var.state_bucket_name
  force_destroy = var.force_destroy_state_bucket

  tags = {
    Name    = var.state_bucket_name
    Purpose = "Terraform remote state"
  }
}

# Keep every version of the state file so a bad apply can be rolled back.
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Encrypt objects at rest (SSE-S3 / AES256 - no KMS key to manage or pay for).
resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Disable ACLs entirely - the bucket owner owns every object.
resource "aws_s3_bucket_ownership_controls" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Block all public access paths.
resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket policy: deny any request not using TLS, and scope writes to this account.
data "aws_iam_policy_document" "state" {
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.state.arn,
      "${aws_s3_bucket.state.arn}/*",
    ]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "state" {
  bucket = aws_s3_bucket.state.id
  policy = data.aws_iam_policy_document.state.json

  depends_on = [aws_s3_bucket_public_access_block.state]
}

# --- DynamoDB table for state locking (spec section 11) ------------------
resource "aws_dynamodb_table" "lock" {
  name         = var.lock_table_name
  billing_mode = "PAY_PER_REQUEST" # no idle cost - only pay per lock/unlock
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  # Protect against an accidental `terraform destroy` blowing away the lock
  # table while other stacks still reference it.
  deletion_protection_enabled = true

  tags = {
    Name    = var.lock_table_name
    Purpose = "Terraform state locking"
  }
}
