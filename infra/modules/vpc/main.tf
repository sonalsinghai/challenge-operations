# VPC Module: creates a VPC with public and private subnets

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  # availability zones for the VPC
  azs = length(var.availability_zones) > 0 ? var.availability_zones : slice(data.aws_availability_zones.available.names, 0, 3)

  # common tags for all resources
  common_tags = merge(
    var.tags,
    {
      Module = "vpc"
    }
  )
}

# VPC: creates the VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    local.common_tags,
    {
      Name = "${var.app_name}-${var.env}-vpc"
    }
  )
}

# Internet Gateway: creates an internet gateway for the VPC
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.app_name}-${var.env}-igw"
    }
  )
}

# Public Subnet: creates a public subnet for the VPC
resource "aws_subnet" "public" {
  count             = length(local.azs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = local.azs[count.index]

  map_public_ip_on_launch = true

  tags = merge(
    local.common_tags,
    {
      Name = "${var.app_name}-${var.env}-public-${count.index + 1}"
      Type = "public"
    }
  )
}

# Private Subnet: creates a private subnet for the VPC
resource "aws_subnet" "private" {
  count             = length(local.azs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = local.azs[count.index]

  tags = merge(
    local.common_tags,
    {
      Name = "${var.app_name}-${var.env}-private-${count.index + 1}"
      Type = "private"
    }
  )
}

# Public Route Table: creates a route table for the public subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.app_name}-${var.env}-public-rt"
    }
  )
}

# Public Route Table Association: associates the public route table with the public subnet
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# NAT Elastic IP: creates a NAT Elastic IP for the VPC
resource "aws_eip" "nat" {
  count  = length(local.azs)
  domain = "vpc"

  tags = merge(
    local.common_tags,
    {
      Name = "${var.app_name}-${var.env}-nat-eip-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# NAT Gateway: creates a NAT gateway for the VPC
resource "aws_nat_gateway" "main" {
  count         = length(local.azs)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.app_name}-${var.env}-nat-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# Private Route Table: creates a route table for the private subnet
resource "aws_route_table" "private" {
  count  = length(local.azs)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.app_name}-${var.env}-private-rt-${count.index + 1}"
    }
  )
}

# Private Route Table Association: associates the private route table with the private subnet
resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
