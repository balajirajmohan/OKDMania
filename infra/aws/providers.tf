provider "aws" {
  region = var.aws_region

  # Applied to every taggable resource automatically (spec section 20).
  default_tags {
    tags = local.common_tags
  }

  # The account auto-applies governance tags (SSO "Owner", Cloud Custodian
  # "c7n-*"). They are not in our config, so Terraform would try to strip them
  # on every apply and Custodian would re-add them - a permanent no-op diff.
  ignore_tags {
    keys         = ["Owner"]
    key_prefixes = ["c7n-"]
  }
}

locals {
  common_tags = {
    Project   = "OKD-Project"
    ManagedBy = "Terraform"
    Repo      = "OKDMania"
    Stack     = "infra/aws"
  }

  # Internal DNS suffix for cloud-init FQDNs (not a real resolvable zone).
  internal_domain = "okd.internal"
}
