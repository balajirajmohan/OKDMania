# Cost estimate

Rough **on-demand** figures, `us-east-1`, late 2026. Check the AWS Pricing
Calculator for current numbers — these move.

## Compute (the expensive part)

| Instance | Type | vCPU / RAM | ~$/hr | ~$/mo if left ON 24/7 |
|---|---|---|---|---|
| OKD-Master | m5.xlarge | 4 / 16 | 0.192 | ~$140 |
| OKD-Worker | t3.xlarge | 4 / 16 | 0.166 | ~$120 |
| OKD-Ansible | t3.xlarge | 4 / 16 | 0.166 | ~$120 |
| OKD-Runner | t3.xlarge | 4 / 16 | 0.166 | ~$120 |
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
| Public IPv4 addresses (Master/Ansible/Runner; the Worker has none) | 3 × ~$3.60/mo = **~$11/mo** while running |
| NAT Gateway (single, for the private Worker subnet) | **~$32/mo** + ~$0.045/GB data processed |
| Data transfer out | first 100 GB/mo free, then ~$0.09/GB |

## State backend

| Item | Cost |
|---|---|
| S3 bucket (state, a few MB, versioned) | pennies |

## Bottom line

- **Left on 24/7:** roughly **$555–580/month**.
- **Stopped when idle** (nights/weekends, ~40 hrs/week runtime): roughly
  **$150–180/month** — EBS, EIPs, and the NAT gateway still bill while
  instances are stopped; compute does not.
- **`terraform destroy` when done for the day:** ~$0 (only the S3 backend
  remains, which is free-tier noise).

## Keeping it cheap

1. `terraform destroy` in `infra/aws/` every time you stop for more than a
   day. The backend stack stays up (costs nothing).
2. Or `aws ec2 stop-instances` for the four IDs (`terraform output`) — keeps
   disks/IPs, saves most of compute (the NAT gateway itself keeps billing
   while stopped, since it isn't an EC2 instance).
3. Set an **AWS Budgets** alarm so a forgotten deployment pings you.
4. `t3` instances are burstable — watch CPU credits if you actually load them.

Regenerate the inventory after a stop/start (public IPs change):
`scripts/gen-inventory.sh` or `terraform apply`.
