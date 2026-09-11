data "aws_iam_policy_document" "assume_ec2" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "runner" {
  name               = "${var.name_prefix}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_ec2.json
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.runner.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "bootstrap" {
  statement {
    sid     = "ReadAndBurnRegistrationToken"
    actions = ["ssm:GetParameter", "ssm:DeleteParameter"]
    resources = [
      aws_ssm_parameter.runner_token.arn,
    ]
  }
}

resource "aws_iam_role_policy" "bootstrap" {
  name   = "${var.name_prefix}-bootstrap"
  role   = aws_iam_role.runner.id
  policy = data.aws_iam_policy_document.bootstrap.json
}

# UPI Terraform needs IAM/EC2/ELB/Route53/S3. Flip this after the smoke job is green.
resource "aws_iam_role_policy_attachment" "admin" {
  count      = var.attach_administrator_access ? 1 : 0
  role       = aws_iam_role.runner.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "runner" {
  name = "${var.name_prefix}-profile"
  role = aws_iam_role.runner.name
}

resource "time_sleep" "iam_propagation" {
  depends_on = [
    aws_iam_instance_profile.runner,
    aws_iam_role_policy.bootstrap,
    aws_iam_role_policy_attachment.ssm,
  ]
  create_duration = "20s"
}
