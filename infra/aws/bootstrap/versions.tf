# Bootstrap stack: creates the S3 bucket + DynamoDB table that every other
# Terraform stack in this repo uses as its remote backend.
#
# This stack itself uses LOCAL state (there is no backend block) - it is the
# chicken that lays the egg. Commit its terraform.tfstate? No. Instead, the
# resources it creates are trivially re-importable and rarely change. If you
# want the bootstrap state itself remote, migrate it into the bucket after the
# first apply (see README).

terraform {
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "OKD-Project"
      Environment = "shared"
      ManagedBy   = "Terraform"
      Component   = "tf-state-backend"
    }
  }

  # The account auto-applies governance tags (SSO "Owner", Cloud Custodian
  # "c7n-*"). They are not in our config, so Terraform would try to strip them
  # on every apply and Custodian would re-add them - a permanent no-op diff.
  ignore_tags {
    keys         = ["Owner"]
    key_prefixes = ["c7n-"]
  }
}
