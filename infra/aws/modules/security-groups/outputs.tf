output "master_sg_id" {
  description = "Security group ID for the OKD master."
  value       = aws_security_group.master.id
}

output "worker_sg_id" {
  description = "Security group ID for the OKD worker."
  value       = aws_security_group.worker.id
}

output "ansible_sg_id" {
  description = "Security group ID for the Ansible control node."
  value       = aws_security_group.ansible.id
}

output "runner_sg_id" {
  description = "Security group ID for the CI/CD runner."
  value       = aws_security_group.runner.id
}

output "all_sg_ids" {
  description = "Map of role -> security group ID."
  value = {
    master  = aws_security_group.master.id
    worker  = aws_security_group.worker.id
    ansible = aws_security_group.ansible.id
    runner  = aws_security_group.runner.id
  }
}
