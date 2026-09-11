terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
  }

  # First apply from your laptop with local state. Move to S3+DynamoDB
  # after this runner is Idle — then UPI Terraform can run on the runner.
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.aws_default_tags
  }
}
