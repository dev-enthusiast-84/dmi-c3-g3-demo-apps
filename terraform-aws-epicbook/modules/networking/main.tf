locals {
  common_tags = merge(
    {
      Project   = var.project_name
      ManagedBy = "terraform"
    },
    var.tags
  )
}

# ------------------------------------------------------------------
# VPC
# ------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true # required for EC2 and RDS endpoint resolution
  enable_dns_hostnames = true # gives EC2 instances public DNS names and RDS endpoints resolvable names

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-vpc"
  })
}

# ------------------------------------------------------------------
# Subnets
# ------------------------------------------------------------------

# Public subnet: hosts the EC2 instance (one AZ)
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-public-subnet"
    Tier = "public"
  })
}

# Private database subnet A (AZ 1)
resource "aws_subnet" "private_db_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_db_subnet_a_cidr
  availability_zone = var.availability_zones[0]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-private-db-subnet-a"
    Tier = "database"
  })
}

# Private database subnet B (AZ 2, different from A).
# RDS DB subnet groups require subnets across at least two AZs.
resource "aws_subnet" "private_db_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_db_subnet_b_cidr
  availability_zone = var.availability_zones[1]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-private-db-subnet-b"
    Tier = "database"
  })
}

# ------------------------------------------------------------------
# Internet Gateway
# ------------------------------------------------------------------
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-igw"
  })
}

# ------------------------------------------------------------------
# Public route table: default route to the Internet Gateway
# ------------------------------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ------------------------------------------------------------------
# Private route table: NO internet route, local VPC traffic only.
# Associated with both database subnets.
# ------------------------------------------------------------------
resource "aws_route_table" "private_db" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-private-db-rt"
  })
}

resource "aws_route_table_association" "private_db_a" {
  subnet_id      = aws_subnet.private_db_a.id
  route_table_id = aws_route_table.private_db.id
}

resource "aws_route_table_association" "private_db_b" {
  subnet_id      = aws_subnet.private_db_b.id
  route_table_id = aws_route_table.private_db.id
}
