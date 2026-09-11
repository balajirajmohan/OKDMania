# Ansible — OKD-Project configuration management

Configures the EC2 instances that `infra/aws/` provisions. Terraform owns
infrastructure; Ansible owns everything on top of it (OS packages, users,
OKD tooling, application/runtime config).

## Connection: AWS Systems Manager

Every instance gets an IAM instance profile with `AmazonSSMManagedInstanceCore`
(see `infra/aws/modules/iam-instance-profile`) and registers with SSM on
boot. Ansible connects through the
[`aws_ssm` connection plugin](https://docs.ansible.com/projects/ansible/latest/collections/amazon/aws/aws_ssm_connection.html)
instead of SSH — no inbound port 22 needed for automation. SSH stays open to
`admin_cidrs` only, as a human break-glass path.

## Setup

```bash
cd ansible
ansible-galaxy collection install -r requirements.yml
aws sso login --profile <your-profile>   # or your usual AWS auth
export AWS_PROFILE=<your-profile>

ansible-inventory -i inventory/aws_ec2.yml --graph
ansible-playbook -i inventory/aws_ec2.yml playbooks/ping.yml
```

## Inventory

- `inventory/aws_ec2.yml` — **dynamic**, tag-based (`amazon.aws.aws_ec2`
  plugin). Filters on `tag:Project = OKD-Project`, groups hosts by their
  `Role` tag into `masters`, `workers`, `ansible`, `runner`. New instances
  Terraform creates are picked up automatically.
- `inventory/hosts.ini` — **static**, SSH-based fallback, regenerated on
  every `terraform apply` (gitignored; see `hosts.ini.example`). Useful if
  SSM is unavailable. The worker has no public IP, so this file addresses it
  by private IP — it only works from a host inside the VPC (e.g. `okd-ansible`
  or over a VPN).

## Playbooks

- `playbooks/ping.yml` — connectivity check over SSM. Run this first after
  any `terraform apply`.

Further OS-prep and OKD-toolchain playbooks build on `roles/` as that work
lands — see the root `README.md` roadmap.
