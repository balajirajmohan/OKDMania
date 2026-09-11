# This account's SCP denies ec2:DescribeImages. Canonical publishes the AMI
# via SSM, which still works (same pattern as origin/infra).
data "aws_ssm_parameter" "ubuntu" {
  name = var.ubuntu_ssm_parameter
}

resource "aws_instance" "runner" {
  ami                         = data.aws_ssm_parameter.ubuntu.insecure_value
  instance_type               = var.instance_type
  subnet_id                   = local.subnet_id
  vpc_security_group_ids      = [aws_security_group.runner.id]
  iam_instance_profile        = aws_iam_instance_profile.runner.name
  associate_public_ip_address = true

  # No SSH key. Use: aws ssm start-session --target <instance-id>
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "enabled"
  }

  root_block_device {
    volume_size           = var.root_volume_gb
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  # EBS volumes do not inherit provider default_tags. Repeat them here.
  volume_tags = merge(local.aws_default_tags, {
    Name = "${var.name_prefix}-1-root"
  })

  user_data = templatefile("${path.module}/user-data.sh.tftpl", {
    aws_region         = var.aws_region
    ssm_parameter_name = aws_ssm_parameter.runner_token.name
    github_repo_url    = "https://github.com/${var.github_repo}"
    runner_name        = "${var.name_prefix}-1"
    runner_labels      = var.runner_labels
  })

  user_data_replace_on_change = false

  depends_on = [time_sleep.iam_propagation]

  tags = {
    Name = "${var.name_prefix}-1"
    Role = "Runner"
  }

  lifecycle {
    ignore_changes = [ami, user_data]
  }
}
