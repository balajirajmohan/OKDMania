# ===========================================================================
# Outputs  (spec sections 17 & 23)  -  no private keys, no secrets
# ===========================================================================

# --- Network ---------------------------------------------------------
output "vpc_id" {
  description = "ID of OKD-VPC."
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR of OKD-VPC."
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs (empty until you set private_subnet_cidrs)."
  value       = module.vpc.private_subnet_ids
}

# --- Security groups ------------------------------------------------
output "security_group_ids" {
  description = "role -> security group ID."
  value       = module.security_groups.all_sg_ids
}

# --- SSH key -------------------------------------------------------
output "ssh_key_name" {
  description = "EC2 key pair name (private key stays on your machine)."
  value       = module.key_pair.key_name
}

# --- OKD master ---------------------------------------------------
output "okd_master_instance_id" {
  value       = module.okd_master.instance_id
  description = "Instance ID - OKD master."
}
output "okd_master_public_ip" {
  value       = module.okd_master.public_ip
  description = "Public IP - OKD master."
}
output "okd_master_private_ip" {
  value       = module.okd_master.private_ip
  description = "Private IP - OKD master."
}

# --- OKD worker -------------------------------------------------
output "okd_worker_instance_id" {
  value       = module.okd_worker.instance_id
  description = "Instance ID - OKD worker."
}
output "okd_worker_public_ip" {
  value       = module.okd_worker.public_ip
  description = "Public IP - OKD worker."
}
output "okd_worker_private_ip" {
  value       = module.okd_worker.private_ip
  description = "Private IP - OKD worker."
}

# --- okd-ansible ----------------------------------------------
output "okd_ansible_instance_id" {
  value       = module.okd_ansible.instance_id
  description = "Instance ID - Ansible control node."
}
output "okd_ansible_public_ip" {
  value       = module.okd_ansible.public_ip
  description = "Public IP - Ansible control node."
}
output "okd_ansible_private_ip" {
  value       = module.okd_ansible.private_ip
  description = "Private IP - Ansible control node."
}

# --- okd-runner ---------------------------------------------
output "okd_runner_instance_id" {
  value       = module.okd_runner.instance_id
  description = "Instance ID - CI/CD runner."
}
output "okd_runner_public_ip" {
  value       = module.okd_runner.public_ip
  description = "Public IP - CI/CD runner."
}
output "okd_runner_private_ip" {
  value       = module.okd_runner.private_ip
  description = "Private IP - CI/CD runner."
}

# --- Convenience: ready-to-use SSH commands --------------------
output "ssh_commands" {
  description = "Copy/paste SSH commands (assumes key at ~/.ssh/okd-project.pem)."
  value = {
    master  = "ssh -i ~/.ssh/okd-project.pem fedora@${module.okd_master.public_ip}"
    worker  = "ssh -i ~/.ssh/okd-project.pem fedora@${module.okd_worker.public_ip}"
    ansible = "ssh -i ~/.ssh/okd-project.pem ubuntu@${module.okd_ansible.public_ip}"
    runner  = "ssh -i ~/.ssh/okd-project.pem ubuntu@${module.okd_runner.public_ip}"
  }
}

output "ubuntu_ami_id_used" {
  description = "The Ubuntu AMI actually used (from variable or SSM)."
  value       = local.ubuntu_ami_id
}
