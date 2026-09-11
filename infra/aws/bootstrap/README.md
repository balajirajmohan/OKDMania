# bootstrap/ — Terraform remote state backend

Creates the shared **S3 bucket** that every other Terraform stack in this
repo uses as its remote state backend.

Run this **once**, before `infra/aws/`.

## Why this stack uses local state

It is the chicken that lays the egg: it *creates* the bucket, so it cannot
store its own state there on the first apply. Its state file
(`terraform.tfstate`) stays local and is gitignored. The resources here
change rarely; if you lose the state, `terraform import` gets them back in
one command.

## Usage

```bash
cd infra/aws/bootstrap
cp terraform.tfvars.example terraform.tfvars
$EDITOR terraform.tfvars          # set a globally-unique state_bucket_name

terraform init
terraform plan
terraform apply

terraform output backend_config_snippet   # paste into ../backend.tf
```

## State locking

Locking uses Terraform's **native S3 lockfile** (`use_lockfile = true`,
Terraform 1.11+) — S3 conditional writes, no extra infrastructure or cost.
There is no DynamoDB table in this stack.

## Teardown

```bash
# 1. destroy infra/aws first
# 2. empty the S3 bucket (all versions) if you really mean it
# 3. set force_destroy_state_bucket = true
terraform destroy
```
