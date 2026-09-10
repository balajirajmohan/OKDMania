# ===========================================================================
# Optional IAM instance profile  (spec sections 13 & 22)
# ===========================================================================
# Disabled by default (var.create = false) because:
#   * the sandbox does not need any AWS API access from the nodes, and
#   * iam:CreateRole may be restricted by an SCP on shared accounts.
#
# Enable it to get AWS Systems Manager Session Manager - a browser/CLI shell
# to the instances without opening port 22 at all. Least-privilege: only
# AmazonSSMManagedInstanceCore unless you add extra_policy_arns.
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

resource "aws_iam_instance_profile" "this" {
  count = local.enabled ? 1 : 0

  name = var.name
  role = aws_iam_role.this[0].name
  tags = merge(var.tags, { Name = var.name })
}
