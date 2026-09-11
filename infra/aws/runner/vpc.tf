# Join Vignesh's OKD-VPC (origin/infra). Do not create a second VPC.
# Apply his infra/aws stack first so this lookup succeeds.

data "aws_vpc" "shared" {
  count = var.vpc_id == "" ? 1 : 0

  tags = {
    Name = var.vpc_name
  }
}

data "aws_subnets" "public" {
  count = var.subnet_id == "" ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }

  tags = {
    Tier = "public"
  }
}

locals {
  vpc_id    = var.vpc_id != "" ? var.vpc_id : data.aws_vpc.shared[0].id
  subnet_id = var.subnet_id != "" ? var.subnet_id : sort(data.aws_subnets.public[0].ids)[0]
}

# Own SG in the shared VPC. Egress only. No SSH — SSM Session Manager.
resource "aws_security_group" "runner" {
  name        = "${var.name_prefix}-sg"
  description = "GitHub Actions runner: outbound only"
  vpc_id      = local.vpc_id

  egress {
    description = "HTTPS to GitHub, AWS APIs, package mirrors"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "HTTP for apt redirects / some mirrors"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "DNS"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "DNS TCP"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-sg"
  }
}
