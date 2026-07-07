# VPC module: a VPC with public + private subnets across multiple AZs, an
# internet gateway, NAT gateway(s), and route tables. Subnets are created with
# for_each (T4) keyed by AZ so removing an AZ only affects that AZ's subnets.

locals {
  # build a map of AZ -> index so we can carve subnet CIDRs deterministically
  az_indexed = { for idx, az in var.availability_zones : az => idx }

  common_tags = merge(var.tags, {
    Module    = "vpc"
    ManagedBy = "terraform"
  })
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(local.common_tags, { Name = "${var.name}-vpc" })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.common_tags, { Name = "${var.name}-igw" })
}

# public subnets (one per AZ) — tagged for EKS ELBs
resource "aws_subnet" "public" {
  for_each                = local.az_indexed
  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.key
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, each.value)
  map_public_ip_on_launch = true
  tags = merge(local.common_tags, {
    Name                     = "${var.name}-public-${each.key}"
    "kubernetes.io/role/elb" = "1"
    Tier                     = "public"
  })
}

# private subnets (one per AZ) — where EKS nodes and RDS live
resource "aws_subnet" "private" {
  for_each          = local.az_indexed
  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, each.value + length(var.availability_zones))
  tags = merge(local.common_tags, {
    Name                              = "${var.name}-private-${each.key}"
    "kubernetes.io/role/internal-elb" = "1"
    Tier                              = "private"
  })
}

# NAT: one shared NAT gateway for cost (dev) or one per AZ for HA (prod),
# controlled by single_nat_gateway. Conditional count (T4).
resource "aws_eip" "nat" {
  count  = var.single_nat_gateway ? 1 : length(var.availability_zones)
  domain = "vpc"
  tags   = merge(local.common_tags, { Name = "${var.name}-nat-eip-${count.index}" })
}

resource "aws_nat_gateway" "this" {
  count         = var.single_nat_gateway ? 1 : length(var.availability_zones)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = values(aws_subnet.public)[count.index].id
  tags          = merge(local.common_tags, { Name = "${var.name}-nat-${count.index}" })
  depends_on    = [aws_internet_gateway.this]
}

# public route table -> IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = merge(local.common_tags, { Name = "${var.name}-public-rt" })
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# private route table(s) -> NAT
resource "aws_route_table" "private" {
  count  = var.single_nat_gateway ? 1 : length(var.availability_zones)
  vpc_id = aws_vpc.this.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[count.index].id
  }
  tags = merge(local.common_tags, { Name = "${var.name}-private-rt-${count.index}" })
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = var.single_nat_gateway ? aws_route_table.private[0].id : aws_route_table.private[local.az_indexed[each.key]].id
}
