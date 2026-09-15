# ===========================================================================
# Generate the Ansible inventory from the live instance IPs  (spec section 18)
# ===========================================================================
# On `terraform apply` this writes repo-root ansible/inventory/hosts.ini so
# the Ansible control node (and your laptop) always has current addresses -
# no hard-coded IPs anywhere (spec section 18).
#
# The file is gitignored. The committed template is
# ansible/inventory/hosts.ini.example. Alternative generator that needs no
# apply: infra/aws/scripts/gen-inventory.sh (parses `terraform output`). The
# dynamic ansible/inventory/aws_ec2.yml plugin is preferred for SSM-based
# runs; this static file is the SSH fallback.
# ===========================================================================

resource "local_file" "ansible_inventory" {
  count = var.generate_ansible_inventory ? 1 : 0

  filename        = "${path.module}/${var.ansible_inventory_path}"
  file_permission = "0644"

  content = templatefile("${path.module}/templates/ansible-hosts.ini.tftpl", {
    master_public_ip     = module.okd_master.public_ip
    master_private_ip    = module.okd_master.private_ip
    worker_public_ip     = module.okd_worker.public_ip
    worker_private_ip    = module.okd_worker.private_ip
    ansible_public_ip    = module.okd_ansible.public_ip
    ansible_private_ip   = module.okd_ansible.private_ip
    runner_public_ip     = module.okd_runner.public_ip
    runner_private_ip    = module.okd_runner.private_ip
    ssh_private_key_file = var.ssh_private_key_file
  })
}
