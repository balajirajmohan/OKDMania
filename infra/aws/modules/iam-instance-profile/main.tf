# ===========================================================================
# IAM instance profile for AWS Systems Manager  (spec sections 11 & 12)
# ===========================================================================
# Enabled by default (var.create = true) so every node registers with SSM and
# Ansible can manage it over the aws_ssm connection plugin without inbound
# SSH. Set var.create = false only if iam:CreateRole is blocked by an SCP on
# a shared account. Least-privilege: only AmazonSSMManagedInstanceCore unless
# you add extra_policy_arns.
# ===========================================================================

locals {
  enabled = var.create
}

data "aws_iam_policy_document" "assume" {
  count = local.enabled ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  count = local.enabled ? 1 : 0

  name               = var.name
  assume_role_policy = data.aws_iam_policy_document.assume[0].json
  tags               = merge(var.tags, { Name = var.name })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  count = local.enabled && var.enable_ssm ? 1 : 0

  role       = aws_iam_role.this[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "extra" {
  for_each = local.enabled ? toset(var.extra_policy_arns) : toset([])

  role       = aws_iam_role.this[0].name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "inline" {
  count = local.enabled && var.inline_policy_json != null ? 1 : 0

  name   = "${var.name}-inline"
  role   = aws_iam_role.this[0].id
  policy = var.inline_policy_json
}

resource "aws_iam_instance_profile" "this" {
  count = local.enabled ? 1 : 0

  name = var.name
  role = aws_iam_role.this[0].name
  tags = merge(var.tags, { Name = var.name })
}
