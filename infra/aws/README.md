# OKD AWS Infrastructure (Terraform)

Provisions the AWS infrastructure for the OKDMania project: a VPC and four
EC2 instances, managed by Terraform. Configuration of those instances (OS
packages, users, OKD tooling, etc.) is Ansible's job, connecting over AWS
Systems Manager — see [Ansible](#ansible).

This does **not** install OKD. OKD 4.x nodes run Fedora CoreOS + Ignition and
are built by `openshift-install`; a plain Fedora Cloud VM configured by
Ansible is the OKD 3.11 model, long EOL. `OKD-Master` / `OKD-Worker` here are
a learning/tooling surface for `oc`, `openshift-install`, Ignition, and
Ansible — not a running cluster.

---

## Architecture

```
                          Internet
                             │
                     Internet Gateway
                             │
                ┌────────────┴─────────────┐
                │       OKD-VPC 10.50.0.0/16│
                │                           │
                │  Public subnets           │  0.0.0.0/0 → IGW
                │  ┌───────────┐┌──────────┐│
                │  │OKD-Master ││OKD-Ansible││
                │  │m5.xlarge  ││t3.xlarge  ││
                │  └───────────┘└──────────┘│
                │  ┌──────────┐              │
                │  │OKD-Runner│              │
                │  │t3.xlarge │              │
                │  └──────────┘              │
                │                           │
                │  Private subnet    NAT ───┼── outbound only
                │  ┌───────────┐            │
                │  │OKD-Worker │            │
                │  │t3.xlarge  │            │
                │  └───────────┘            │
                └───────────────────────────┘
```

| Instance | Name tag | Type | OS | Subnet | Role |
|---|---|---|---|---|---|
| master | `OKD-Master` | `m5.xlarge` | Fedora | Public | control-plane scratch node |
| worker | `OKD-Worker` | `t3.xlarge` | Fedora | Private, no public IP | compute scratch node |
| ansible | `OKD-Ansible` | `t3.xlarge` | Ubuntu 24.04 | Public | Ansible control node |
| runner | `OKD-Runner` | `t3.xlarge` | Ubuntu 24.04 | Public | CI/CD runner host |

Every resource is tagged `Project = OKD-Project` / `ManagedBy = Terraform`
via provider `default_tags`. Instances also get `Name` / `Role` / `OS` tags.

## Components

- **VPC** (`modules/vpc`) — `OKD-VPC`, IGW, public subnets (Master/Ansible/
  Runner), a private subnet (Worker), and a single NAT gateway for the
  private subnet's outbound traffic.
- **Security groups** (`modules/security-groups`) — one per role. SSH (22) is
  admin-CIDR-only everywhere; the OKD API (6443) and app HTTP/HTTPS (80/443)
  are exposed only on the master; master/worker/ansible share an open
  "cluster fabric" rule between their own security groups (etcd, kubelet,
  SDN overlay, etc. — see the module for the full port map).
- **Key pair** (`modules/key-pair`) — references the **existing** `OKD-Project`
  EC2 key pair by name; Terraform never creates or uploads key material.
- **IAM instance profile** (`modules/iam-instance-profile`) — attaches
  `AmazonSSMManagedInstanceCore` to every instance so AWS Systems Manager
  (and Ansible over SSM) work without opening SSH.
- **EC2** (`modules/ec2`) — one reusable instance module, called four times.

## Terraform usage

```bash
cd infra/aws
cp terraform.tfvars.example terraform.tfvars
$EDITOR terraform.tfvars              # set admin_cidrs, fedora_ami_id

terraform init                        # reads backend.tf -> S3 (run bootstrap/ first)
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

`terraform destroy` tears down the VPC/instances/security groups/NAT gateway
but leaves the state backend (`bootstrap/`) untouched, so you can rebuild
cheaply. See `bootstrap/README.md` for the one-time backend setup and
`scripts/cost-estimate.md` for running costs.

## Ansible

Instances register with **AWS Systems Manager** on boot (via the attached
IAM instance profile); Ansible connects using the
[`amazon.aws` / `community.aws` SSM connection plugin](https://docs.ansible.com/projects/ansible/latest/collections/amazon/aws/aws_ssm_connection.html),
not SSH. See `ansible/README.md` for setup. Typical workflow:

```bash
cd ansible
ansible-galaxy collection install -r requirements.yml
ansible-inventory -i inventory/aws_ec2.yml --graph
ansible-playbook -i inventory/aws_ec2.yml playbooks/ping.yml
```

The dynamic inventory groups hosts by their `Role` tag (`masters`, `workers`,
`ansible`, `runner`) using the tag `Project = OKD-Project` as the filter, so
new instances are picked up automatically — no hand-maintained IPs. A static,
SSH-based fallback inventory (`ansible/inventory/hosts.ini`) is also
generated on every `terraform apply` (see `inventory.tf`), using the
worker's private IP since it has no public one.

## Access

Administrative access (SSH) is restricted to `206.128.133.4/32` via
`admin_cidrs` in `terraform.tfvars` — never `0.0.0.0/0`. The OKD API (6443)
defaults to the same restriction. App HTTP/HTTPS (80/443) on the master is
open to the internet by default (`apps_ingress_cidrs`) so demo workloads are
reachable from a browser; tighten it for anything sensitive.

## Future scaling

`main.tf` has commented-out `okd_master_02/03` and `okd_worker_02/03` module
blocks. Uncomment and adjust the subnet index / hostname to add nodes — no
other restructuring needed.

## Repository structure

```
infra/aws/
├── README.md
├── bootstrap/            S3 state backend (its own local-state stack)
├── backend.tf  providers.tf  versions.tf
├── main.tf  variables.tf  outputs.tf  inventory.tf
├── terraform.tfvars  terraform.tfvars.example
├── modules/
│   ├── vpc/                       VPC, IGW, public + private subnets, NAT
│   ├── security-groups/           master / worker / ansible / runner SGs
│   ├── key-pair/                  references the existing OKD-Project key pair
│   ├── ec2/                       one reusable instance + cloud-init
│   └── iam-instance-profile/      SSM instance profile
├── templates/             cloud-init (*.tftpl) + ansible inventory template
└── scripts/
    ├── gen-inventory.sh   regenerate the static inventory from `terraform output`
    └── cost-estimate.md
```

## Security considerations

- SSH restricted to `admin_cidrs`; `0.0.0.0/0` is rejected by variable
  validation.
- The worker has no public IP and reaches the internet only through the NAT
  gateway.
- **IMDSv2 required** on every instance (`http_tokens = required`).
- **EBS encrypted** at rest; **S3 state** encrypted + versioned +
  public-access blocked + TLS-only bucket policy + `BucketOwnerEnforced`.
- No secrets in code. `*.tfvars`, `*.pem`, `*.tfstate` are gitignored.
  Runner/GitHub/GitLab tokens are never put in Terraform or cloud-init —
  register the runner by hand.
- Later phases: use AWS Secrets Manager / SSM Parameter Store — not
  variables — for credentials.

## Git hygiene

The repo-root [`.gitignore`](../../.gitignore) excludes Terraform state,
`.terraform/`, `*.tfvars` (keeps `*.tfvars.example`), `*.pem`, `.env`, and the
generated `ansible/inventory/hosts.ini` (keeps `hosts.ini.example`).
`.terraform.lock.hcl` **is** committed for reproducible providers.
