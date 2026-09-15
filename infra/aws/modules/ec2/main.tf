# ===========================================================================
# Reusable single EC2 instance  (spec section 4)
# ===========================================================================
# One call = one instance. The environment wires this module four times
# (master, worker, ansible, runner). Bootstrap is done with cloud-init /
# user_data only - no remote-exec provisioners (spec section 13).
# ===========================================================================

resource "aws_instance" "this" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.vpc_security_group_ids
  key_name                    = var.key_name
  associate_public_ip_address = var.associate_public_ip
  iam_instance_profile        = var.iam_instance_profile
  user_data                   = var.user_data

  # Re-running cloud-init on every user_data tweak would rebuild the box and
  # lose in-cluster state. Change user_data deliberately, then taint/replace.
  user_data_replace_on_change = false

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = var.root_volume_type
    encrypted             = true
    delete_on_termination = true

    tags = merge(var.tags, { Name = "${var.name}-root" })
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 only
    http_put_response_hop_limit = 2          # containers can still reach IMDS
  }

  tags = merge(var.tags, {
    Name = var.name
    Role = var.role
    OS   = var.os
  })

  lifecycle {
    # AMI IDs move as Fedora/Ubuntu publish new images; don't force-replace
    # a running node just because a newer AMI exists. Replace on purpose.
    ignore_changes = [ami]
  }
}
