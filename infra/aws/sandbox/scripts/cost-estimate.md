# Sandbox cost estimate (spec section 21)

Rough **on-demand** figures, `us-east-1`, late 2026. Check the AWS Pricing
Calculator for current numbers — these move.

## Compute (the expensive part)

| Instance | Type | vCPU / RAM | ~$/hr | ~$/mo if left ON 24/7 |
|---|---|---|---|---|
| OKD-master | m5.xlarge | 4 / 16 | 0.192 | ~$140 |
| OKD-worker | t3.xlarge | 4 / 16 | 0.166 | ~$120 |
| okd-ansible | t3.xlarge | 4 / 16 | 0.166 | ~$120 |
| okd-runner | t3.xlarge | 4 / 16 | 0.166 | ~$120 |
| **Compute total** | | | | **~$500/mo** |

## Storage

| Item | Size | ~$/mo |
|---|---|---|
| gp3 root — master | 60 GiB | ~$4.80 |
| gp3 root — 3 × 40 GiB | 120 GiB | ~$9.60 |
| **EBS total** | | **~$15/mo** |

## Networking

| Item | Cost |
|---|---|
| VPC, IGW, subnets, route tables, security groups | **$0** |
| Public IPv4 addresses (auto-assigned) | 4 × ~$3.60/mo = **~$14/mo** while running |
| NAT Gateway | **$0** — not created (spec section 21) |
| Data transfer out | first 100 GB/mo free, then ~$0.09/GB |

## State backend

| Item | Cost |
|---|---|
| S3 bucket (state, a few MB, versioned) | pennies |
| DynamoDB `okd-terraform-lock` (PAY_PER_REQUEST) | effectively $0 |

## Bottom line

- **Left on 24/7:** roughly **$530–550/month**.
- **Stopped when idle** (nights/weekends, ~40 hrs/week runtime): roughly
  **$140–170/month** — EBS + EIPs still bill while stopped, compute does not.
- **`terraform destroy` when done for the day:** ~$0 (only the S3/DynamoDB
  backend remains, which is free-tier noise).

## Keeping it cheap

1. `terraform destroy` in `environments/sandbox/` every time you stop for more
   than a day. The backend stack stays up (costs nothing).
2. Or `aws ec2 stop-instances` for the four IDs (`terraform output`) — keeps
   disks/IPs, saves ~70% of compute.
3. Set an **AWS Budgets** alarm at e.g. $50 so a forgotten cluster pings you.
4. Don't add NAT Gateway, load balancers, RDS, or EKS (spec section 21).
5. `t3` instances are burstable — watch CPU credits if you actually load them.

Regenerate the inventory after a stop/start (public IPs change):
`scripts/gen-inventory.sh` or `terraform apply`.
