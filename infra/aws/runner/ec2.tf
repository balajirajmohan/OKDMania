data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_instance" "runner" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
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

  depends_on = [
    time_sleep.iam_propagation,
    aws_route_table_association.public,
  ]

  tags = {
    Name = "${var.name_prefix}-1"
  }

  lifecycle {
    ignore_changes = [ami, user_data]
  }
}
