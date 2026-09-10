# ansible/ — configuration management for the OKD sandbox

This directory is the **Phase 2** surface (see the root `README.md` roadmap).
Phase 1 (Terraform) builds the machines; Ansible configures them from here.

```
ansible/
├── ansible.cfg
├── inventory/
│   ├── hosts.ini            # GENERATED from Terraform outputs - gitignored
│   └── hosts.ini.example    # committed template
├── group_vars/
│   ├── all.yml
│   ├── okd_masters.yml
│   └── okd_workers.yml
└── playbooks/
    ├── ping.yml             # connectivity check
    └── os-prep.yml          # Phase 2 baseline OS prep (skeleton)
```

## Inventory is generated, never hand-written (spec section 18)

The four instances get **dynamic** public IPs. Hard-coding them into a committed
file rots immediately and leaks addresses. Instead the inventory is built from
Terraform outputs, two ways:

| Method | Command | When |
|---|---|---|
| Terraform-native | `terraform apply` in `infra/aws/sandbox/environments/sandbox` | every apply — `inventory.tf` writes repo-root `ansible/inventory/hosts.ini` (`ansible_inventory_path`, 5 levels up) |
| Script | `infra/aws/sandbox/scripts/gen-inventory.sh` | refresh without an apply (e.g. after stop/start changed the IPs) |

Both produce the same file. It matches `hosts.ini.example` in structure:

```ini
[okd_masters]
okd-master ansible_host=<public-ip> private_ip=<vpc-ip> ansible_user=fedora

[okd_workers]
okd-worker ansible_host=<public-ip> private_ip=<vpc-ip> ansible_user=fedora

[okd_cluster:children]
okd_masters
okd_workers
```

The Terraform outputs that feed it (`terraform output`):
`okd_master_public_ip`, `okd_master_private_ip`, `okd_worker_public_ip`,
`okd_worker_private_ip`, `okd_ansible_*`, `okd_runner_*`.

## Running Ansible

### From your laptop

```bash
# 1. keys + infra
cd infra/aws/sandbox/scripts && ./generate-key.sh
cp okd-project.pem ~/.ssh/ && chmod 400 ~/.ssh/okd-project.pem
cd ../environments/sandbox && terraform apply    # writes the inventory

# 2. Ansible  (repo-root/ansible, 5 levels up from environments/sandbox)
cd ../../../../../ansible
ansible-playbook playbooks/ping.yml
ansible-playbook playbooks/os-prep.yml --limit okd_cluster
```

### From the okd-ansible box (the real control node)

```bash
# copy the key and this dir up to the box
scp -i ~/.ssh/okd-project.pem ~/.ssh/okd-project.pem ubuntu@<ansible_public_ip>:~/.ssh/
rsync -e "ssh -i ~/.ssh/okd-project.pem" -a ansible/ ubuntu@<ansible_public_ip>:~/okd/ansible/
ssh -i ~/.ssh/okd-project.pem ubuntu@<ansible_public_ip>
cd ~/okd/ansible && ansible-playbook playbooks/ping.yml
```

The `okd-ansible` cloud-init already installed `ansible`, `git`, `python3`,
`awscli`, `jq`, `openssh-client`. It uses the `okd-project` key to reach the
Fedora nodes over their **private** IPs (all four are in the same VPC).

## Important: these Fedora boxes are not an OKD cluster

`os-prep.yml` only does universal OS prep. Turning the nodes into a real OKD 4.x
cluster is **not** an Ansible job — OKD 4.x uses Fedora CoreOS + Ignition +
`openshift-install`. See `docs/sandbox-findings.md` and the root `README.md`
decision log (D031 = AWS UPI). Use this sandbox to get fluent with Ansible,
`oc`, and `openshift-install` before/while the UPI stack is built.
