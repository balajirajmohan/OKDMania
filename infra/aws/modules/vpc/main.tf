# ===========================================================================
# VPC module
# ===========================================================================
# 1 VPC, IGW, public route table + subnets, and (when private_subnet_cidrs is
# set) private subnets + a private route table + NAT gateway. Nothing about
# the public tier changes when private subnets are added.
# ===========================================================================

locals {
  az_count          = length(var.azs)
  create_private    = length(var.private_subnet_cidrs) > 0
  nat_gateway_count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : local.az_count) : 0
  private_rtb_count = local.create_private ? (var.enable_nat_gateway && !var.single_nat_gateway ? local.az_count : 1) : 0
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true # OKD / kubelet expect resolvable hostnames

  tags = merge(var.tags, { Name = var.name })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name}-igw" })
}

# --- Public subnets -------------------------------------------------------
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index % local.az_count]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.name}-public-${count.index + 1}"
    Tier = "public"
    # kubernetes.io/role/elb = 1  <- add when a real cluster uses these subnets
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name}-public-rtb" })
}

resource "aws_route" "public_default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# --- Private subnets (created only when private_subnet_cidrs is set) -------
resource "aws_subnet" "private" {
  count = local.create_private ? length(var.private_subnet_cidrs) : 0

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index % local.az_count]

  tags = merge(var.tags, {
    Name = "${var.name}-private-${count.index + 1}"
    Tier = "private"
  })
}

# One NAT gateway (shared) or one per AZ, sitting in the public subnets.
resource "aws_eip" "nat" {
  count  = local.nat_gateway_count
  domain = "vpc"
  tags   = merge(var.tags, { Name = "${var.name}-nat-${count.index + 1}" })
}

resource "aws_nat_gateway" "this" {
  count         = local.nat_gateway_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index % length(aws_subnet.public)].id
  tags          = merge(var.tags, { Name = "${var.name}-nat-${count.index + 1}" })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "private" {
  count  = local.private_rtb_count
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name}-private-rtb-${count.index + 1}" })
}

resource "aws_route" "private_default" {
  count = var.enable_nat_gateway ? local.private_rtb_count : 0

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[var.single_nat_gateway ? 0 : count.index].id
}

resource "aws_route_table_association" "private" {
  count = local.create_private ? length(aws_subnet.private) : 0

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[var.single_nat_gateway || local.private_rtb_count == 1 ? 0 : count.index].id
}
