# bootstrap/ — Terraform remote state backend

Creates the shared **S3 bucket** (Terraform state) and **DynamoDB table**
(`okd-terraform-lock`, state locking) that every other stack in this repo uses
as its backend.

Run this **once**, before `environments/sandbox/`.

## Why this stack uses local state

It is the chicken that lays the egg: it *creates* the bucket, so it cannot store
its own state there on the first apply. Its state file (`terraform.tfstate`) stays
local and is gitignored. The resources here change rarely; if you lose the state,
`terraform import` gets them back in two commands.

Optionally, after the first apply you can migrate this stack's own state into the
bucket by adding a `backend "s3"` block and running `terraform init -migrate-state`.

## Usage

```bash
cd infra/aws/sandbox/bootstrap
cp terraform.tfvars.example terraform.tfvars
$EDITOR terraform.tfvars          # set a globally-unique state_bucket_name

terraform init
terraform plan
terraform apply

terraform output backend_config_snippet   # paste into ../environments/sandbox/backend.tf
```

## State locking: `use_lockfile` vs DynamoDB

| | Native S3 lockfile | DynamoDB (`dynamodb_table`) |
|---|---|---|
| Terraform | 1.10 experimental, **1.11+ recommended** | all versions, **deprecated since 1.11** |
| Infra needed | none (uses S3 conditional writes) | a DynamoDB table |
| Cost | none | ~$0 at PAY_PER_REQUEST for this usage |
| Config | `use_lockfile = true` | `dynamodb_table = "okd-terraform-lock"` |

This repo's `environments/sandbox/backend.tf` uses **`use_lockfile = true`**.
We still create the DynamoDB table so you can:

- switch back by uncommenting the `dynamodb_table` line, or
- use it from other tooling that predates native locking.

You can safely `terraform destroy` this stack only after every dependent stack is
destroyed. The DynamoDB table has `deletion_protection_enabled = true`; remove that
in `main.tf` and re-apply before you can destroy it.

## Teardown

```bash
# 1. destroy environments/sandbox first
# 2. empty the state bucket (all versions) if you really mean it
# 3. set force_destroy_state_bucket = true, disable DDB deletion protection
terraform destroy
```
