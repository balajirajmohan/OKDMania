# OKD Sandbox — AWS Infrastructure (Terraform)

A small, cost-conscious, **learning/ops** environment on AWS for the OKDMania
POC. It provisions a VPC and four EC2 instances and nothing more. It **does not
install OKD** — see [Why this is not a cluster](#why-this-is-not-a-cluster) and
[`docs/sandbox-findings.md`](../../../docs/sandbox-findings.md).

The real OKD cluster is a separate **AWS UPI** build (root
[`README.md`](../../../README.md) decision **D031**). This sandbox sits beside
it: the Ansible controller, the CI runner, two scratch Fedora nodes, and a set
of reusable Terraform modules that the UPI stack can build on.

---

## Contents

1. [Architecture](#architecture)
2. [Why this is not a cluster](#why-this-is-not-a-cluster)
3. [Prerequisites](#prerequisites)
4. [AWS authentication](#aws-authentication)
5. [Repository layout](#repository-layout)
6. [Step 1 — bootstrap the state backend](#step-1--bootstrap-the-state-backend)
7. [Step 2 — generate the SSH key](#step-2--generate-the-ssh-key)
8. [Step 3 — configure and deploy the sandbox](#step-3--configure-and-deploy-the-sandbox)
9. [Terraform outputs](#terraform-outputs)
10. [SSH access](#ssh-access)
11. [Ansible setup](#ansible-setup)
12. [Security groups & ports](#security-groups--ports)
13. [Security considerations](#security-considerations)
14. [Cost considerations](#cost-considerations)
15. [Destroy procedure](#destroy-procedure)
16. [OKD next steps](#okd-next-steps)
17. [Git hygiene](#git-hygiene)

---

## Architecture

```
                          Internet
                             │
                     Internet Gateway
                             │
                ┌────────────┴─────────────┐
                │   OKD-VPC  10.50.0.0/16   │
                │                          │
                │   Public route table     │  0.0.0.0/0 → IGW
                │   ┌──────────────────┐    │
                │   │ public subnet a  │ 10.50.0.0/24  (us-east-1a)
                │   │ public subnet b  │ 10.50.1.0/24  (us-east-1b)
                │   └──────────────────┘    │
                │                          │
                │  ┌──────────┐ ┌──────────┐│
                │  │OKD-master│ │OKD-worker ││  Fedora  (scratch nodes)
                │  │m5.xlarge │ │t3.xlarge  ││
                │  └──────────┘ └──────────┘│
                │  ┌──────────┐ ┌──────────┐│
                │  │okd-ansible│ │okd-runner││  Ubuntu 24.04
                │  │t3.xlarge │ │t3.xlarge  ││
                │  └──────────┘ └──────────┘│
                └──────────────────────────┘

State backend (separate stack, bootstrap/):
  S3  okd-test-terraform-state-<suffix>   versioned · encrypted · private
  DynamoDB  okd-terraform-lock            LockID · PAY_PER_REQUEST
```

**Designed to evolve** — the `vpc` module already supports private subnets and a
NAT gateway (`private_subnet_cidrs`, `enable_nat_gateway`); nothing in the
public tier changes when you add them. Future shape:

```
OKD-VPC
├── public subnets   → bastion, load balancers
└── private subnets  → OKD nodes, internal services
```

| Instance | Name tag | Type | vCPU/RAM | OS | Role |
|---|---|---|---|---|---|
| master | `OKD-master` | `m5.xlarge` | 4 / 16 | Fedora | scratch control-plane node |
| worker | `OKD-worker` | `t3.xlarge` | 4 / 16 | Fedora | scratch worker node |
| ansible | `okd-ansible` | `t3.xlarge` | 4 / 16 | Ubuntu 24.04 | Ansible control node |
| runner | `okd-runner` | `t3.xlarge` | 4 / 16 | Ubuntu 24.04 | CI/CD runner host |

Every resource is tagged `Project = OKD-Test` (+ `Environment = sandbox`,
`ManagedBy = Terraform`) via provider `default_tags`. Instances also get
`Name` / `Role` / `OS`.

---

## Why this is not a cluster

OKD **4.x** nodes run **Fedora CoreOS + Ignition** and are installed by
`openshift-install`, with a temporary bootstrap node, load balancers for
`:6443` / `:22623` / `:80` / `:443`, and real DNS. A plain Fedora VM configured
by Ansible is the **OKD 3.11** model — long EOL. Full detail and the
"closest compatible alternative" options are in
[`docs/sandbox-findings.md`](../../../docs/sandbox-findings.md).

So: use `OKD-master` / `OKD-worker` as scratch Linux boxes to learn `oc`,
`openshift-install`, Ignition, and Ansible. Build the actual cluster with the
UPI stack (root README D031).

---

## Prerequisites

| Tool | Version | Notes |
|---|---|---|
| Terraform | **≥ 1.11** (tested 1.15.8) | 1.11 is the floor for native S3 locking (`use_lockfile`) |
| AWS CLI | v2 | for auth + `terraform` provider calls |
| `ssh` / `ssh-keygen` | any | key generation and access |
| `jq` | any | only for `scripts/gen-inventory.sh` |
| Ansible | ≥ 2.15 | Phase 2, or just use the `okd-ansible` box |

An AWS account/role that can create VPC, EC2, S3, and DynamoDB resources.
**Known constraint on account `853973692277`:** an SCP denies
`ec2:DescribeImages`, so this code uses AMI **variables/SSM**, not `aws_ami`
data sources. See findings §2.

---

## AWS authentication

Use any standard method — the code never embeds credentials.

```bash
# SSO (this account uses IAM Identity Center)
aws sso login --profile <your-profile>
export AWS_PROFILE=<your-profile>

# or static keys / env
export AWS_ACCESS_KEY_ID=... AWS_SECRET_ACCESS_KEY=... AWS_SESSION_TOKEN=...

aws sts get-caller-identity      # confirm before you apply
```

Region comes from `var.aws_region` (default `us-east-1`), not `AWS_REGION`.

---

## Repository layout

```
infra/aws/sandbox/
├── README.md                     ← this file
├── bootstrap/                     S3 + DynamoDB state backend (local state)
├── environments/sandbox/          the deployable root module
│   ├── backend.tf  versions.tf  providers.tf
│   ├── main.tf  variables.tf  outputs.tf  inventory.tf
│   └── terraform.tfvars.example
├── modules/
│   ├── vpc/                       VPC, IGW, public (+ optional private) subnets
│   ├── security-groups/           master / worker / ansible / runner SGs
│   ├── key-pair/                  imports the okd-project public key
│   ├── ec2/                       one reusable instance + cloud-init
│   └── iam-instance-profile/      optional SSM Session Manager role
├── templates/                     cloud-init (*.tftpl) + ansible inventory
└── scripts/
    ├── generate-key.sh            create okd-project.pem (chmod 400)
    ├── gen-inventory.sh           inventory from `terraform output`
    └── cost-estimate.md
```

---

## Step 1 — bootstrap the state backend

Run **once** per AWS account. Uses local state (it creates the bucket it would
otherwise store state in).

```bash
cd infra/aws/sandbox/bootstrap
cp terraform.tfvars.example terraform.tfvars
$EDITOR terraform.tfvars                 # set a GLOBALLY-UNIQUE state_bucket_name

terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply

terraform output backend_config_snippet  # copy this
```

Paste the bucket name into `environments/sandbox/backend.tf` (replace
`REPLACE_WITH_STATE_BUCKET`). Locking uses `use_lockfile = true`; the
`okd-terraform-lock` DynamoDB table is created too, as a fallback
(see [`bootstrap/README.md`](bootstrap/README.md)).

---

## Step 2 — generate the SSH key

```bash
cd infra/aws/sandbox/scripts
./generate-key.sh                        # writes okd-project.pem (0400) + .pub

cp okd-project.pem ~/.ssh/               # so `ssh -i` / Ansible find it
chmod 400 ~/.ssh/okd-project.pem
```

`okd-project.pem` is **gitignored**. Terraform uploads only `okd-project.pem.pub`
— the private key never enters state or output (spec section 7).

---

## Step 3 — configure and deploy the sandbox

```bash
cd infra/aws/sandbox/environments/sandbox
cp terraform.tfvars.example terraform.tfvars
$EDITOR terraform.tfvars
```

Set at minimum:

| Variable | Example | Why |
|---|---|---|
| `admin_cidrs` | `["<your-ip>/32"]` | SSH allow-list. `curl -s https://checkip.amazonaws.com` |
| `fedora_ami_id` | `ami-0abc…` | no data source (SCP). See findings §2 for how to find it |

Then:

```bash
terraform init                           # reads backend.tf → S3
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

Expected plan: 1 VPC, 1 IGW, 2 subnets, 1 route table (+2 assoc), 4 security
groups (+ rules), 1 key pair, 4 instances, 1 local file (the Ansible inventory).

---

## Terraform outputs

`terraform output` (spec sections 17 & 23) — no secrets are ever output:

```
vpc_id                 = "vpc-…"
public_subnet_ids      = ["subnet-…", "subnet-…"]
private_subnet_ids     = []
security_group_ids     = { master = "sg-…", worker = "sg-…", ansible = "sg-…", runner = "sg-…" }
ssh_key_name           = "okd-project"

okd_master_instance_id / okd_master_public_ip / okd_master_private_ip
okd_worker_instance_id / okd_worker_public_ip / okd_worker_private_ip
okd_ansible_instance_id / okd_ansible_public_ip / okd_ansible_private_ip
okd_runner_instance_id / okd_runner_public_ip / okd_runner_private_ip

ssh_commands           = { master = "ssh -i ~/.ssh/okd-project.pem fedora@…", … }
```

---

## SSH access

```bash
terraform output ssh_commands

ssh -i ~/.ssh/okd-project.pem fedora@$(terraform output -raw okd_master_public_ip)
ssh -i ~/.ssh/okd-project.pem fedora@$(terraform output -raw okd_worker_public_ip)
ssh -i ~/.ssh/okd-project.pem ubuntu@$(terraform output -raw okd_ansible_public_ip)
ssh -i ~/.ssh/okd-project.pem ubuntu@$(terraform output -raw okd_runner_public_ip)
```

Default users: **`fedora`** (Fedora Cloud), **`ubuntu`** (Ubuntu). SSH only
works from an IP inside `admin_cidrs`. With `create_instance_profile = true` you
can instead use `aws ssm start-session --target <instance-id>` and keep port 22
closed.

Watch first-boot cloud-init: `cloud-init status --wait` then
`sudo less /var/log/cloud-init-output.log`.

---

## Ansible setup

`terraform apply` writes `ansible/inventory/hosts.ini` from the live IPs (via
`inventory.tf`). Full guide: [`ansible/README.md`](../../../ansible/README.md).

```bash
cd ../../../../../ansible       # repo-root/ansible (from environments/sandbox)
ansible-playbook playbooks/ping.yml
ansible-playbook playbooks/os-prep.yml --limit okd_cluster
```

Refresh the inventory without an apply (e.g. after stop/start):
`infra/aws/sandbox/scripts/gen-inventory.sh`.

---

## Security groups & ports

One SG per role. SSH (22) is **only** ever open to `admin_cidrs` — never
`0.0.0.0/0` (spec section 8, enforced by a variable validation).

| Port(s) | Where | Source | Why internet-facing? |
|---|---|---|---|
| 22 | all | `admin_cidrs` | admin only — restricted |
| 6443 | master | `cluster_api_cidrs` (def = `admin_cidrs`) | Kubernetes/OKD API for `oc` — restricted |
| 80, 443 | master, worker | `apps_ingress_cidrs` (def = `0.0.0.0/0`) | so demo apps / the OpenShift router are reachable from a browser. Tighten for anything sensitive |
| 30000–32767 | worker | off by default (`enable_nodeport_from_apps`) | NodePort services, if you skip the router |
| ICMP | all | `vpc_cidr` | path-MTU / ping for debugging — VPC-internal only |
| **all traffic** | master ↔ worker, and from ansible SG | referenced SGs | the OKD "cluster fabric": etcd (2379-80), machine-config (22623), kubelet/controller/scheduler (10250-10259), host services (9000-9999), NodePorts, SDN/OVN overlay (VXLAN 4789/udp, Geneve 6081/udp, IPsec 500/4500/udp), BGP 179, DNS 53. Enumerating these drifts from the OKD docs, so we allow all *between the node SGs only* — the same approach the upstream OpenShift AWS CloudFormation templates take. Not internet-exposed. |
| all egress | all | `0.0.0.0/0` | public subnets, no NAT — nodes need direct outbound for package/image pulls and AWS APIs |

---

## Security considerations

- **SSH** restricted to `admin_cidrs`; `0.0.0.0/0` is rejected by validation.
- **Private key** generated locally, `chmod 400`, gitignored, never in state or
  output. AWS holds only the public key.
- **IMDSv2 required** on every instance (`http_tokens = required`).
- **EBS encrypted** at rest; **S3 state** encrypted + versioned + public-access
  blocked + TLS-only bucket policy + `BucketOwnerEnforced`.
- **No secrets in code.** `*.tfvars`, `*.pem`, `*.tfstate` are gitignored.
  Runner/GitHub/GitLab tokens are **never** put in Terraform or cloud-init —
  register the runner by hand later (spec sections 19 & 22).
- **DynamoDB lock table** has deletion protection.
- Later phases: use IAM roles, AWS Secrets Manager, SSM Parameter Store — not
  variables — for credentials.
- Trade-off accepted for a learning sandbox: instances have **public IPs** and
  app ports default to the internet. Move to private subnets + a bastion/LB
  (the `vpc` module already supports it) for anything less disposable.

---

## Cost considerations

Full breakdown: [`scripts/cost-estimate.md`](scripts/cost-estimate.md).

| Posture | ~Cost |
|---|---|
| All 4 instances on 24/7 | **~$530–550/month** |
| Stopped when idle (~40 h/week) | **~$140–170/month** (EBS + EIPs still bill) |
| `terraform destroy` when done | **~$0** (only the free-tier S3/DynamoDB backend remains) |

No NAT gateway, no load balancer, no RDS/EKS (spec section 21). Set an **AWS
Budgets** alarm. `t3` instances are burstable — mind CPU credits under load.

---

## Destroy procedure

```bash
# 1. the sandbox (instances, VPC, SGs, key pair)
cd infra/aws/sandbox/environments/sandbox
terraform destroy

# 2. (optional) the state backend — only if you're done with the whole project
cd ../../bootstrap
#   - empty the S3 bucket (all versions) first
#   - set force_destroy_state_bucket = true in terraform.tfvars
#   - remove `deletion_protection_enabled` from the DynamoDB table, re-apply
terraform destroy
```

Destroying the sandbox does **not** touch the backend, so you can rebuild
cheaply the next day. Regenerate the inventory after any rebuild.

---

## OKD next steps

This repo's roadmap lives in the root [`README.md`](../../../README.md). From
this sandbox:

1. **Phase 2 (Ansible):** flesh out `ansible/playbooks/os-prep.yml` — hostname,
   chrony, kernel params, DNS, SSH, base packages.
2. **Learn the OKD 4.x toolchain** on `okd-ansible`: `openshift-install`, `oc`,
   `butane`, Ignition, pull secret handling.
3. **Build the real cluster** with the UPI stack (`infra/aws/upi/`, root README
   D031): VPC + NLBs (`:6443`, `:22623`, `:80/:443`) + Route 53 + IAM +
   bootstrap + 3 masters + 3 workers on FCOS/Ignition; approve CSRs; delete
   bootstrap.
4. **Phases 4–8:** app deploy, observability (OTel), CI/CD, GitOps, chaos — all
   on the UPI cluster.

---

## Git hygiene

The repo-root [`.gitignore`](../../../.gitignore) excludes Terraform state,
`.terraform/`, `*.tfvars` (keeps `*.tfvars.example`), `*.pem`, `.env`, and the
generated `ansible/inventory/hosts.ini` (keeps `hosts.ini.example`).
`.terraform.lock.hcl` **is** committed for reproducible providers.

**One root `.gitignore` is enough** (spec section 15) — Terraform's own
recommended ignore patterns are all path-relative globs (`**/.terraform/*`,
`*.tfstate`, `*.tfvars`), so they work repo-wide from the root. A per-module
`.gitignore` would only add drift. The one project-specific addition beyond the
standard Terraform set is `okd-project.pem*` and `ansible/inventory/hosts.ini`.

Quick check before pushing:

```bash
git status --porcelain | grep -E '\.(pem|tfstate|tfvars)$|hosts\.ini$' && echo "STOP — secret/state staged" || echo "clean"
```
