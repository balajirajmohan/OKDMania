provider "aws" {
  region = var.aws_region

  # Applied to every taggable resource automatically (spec section 9).
  default_tags {
    tags = local.common_tags
  }
}

locals {
  common_tags = {
    Project     = "OKD-Test"
    Environment = "sandbox"
    ManagedBy   = "Terraform"
    Repo        = "OKDMania"
    Stack       = "infra/aws/sandbox"
  }

  # Internal DNS suffix for cloud-init FQDNs (not a real resolvable zone).
  internal_domain = "okd.sandbox.local"
}
