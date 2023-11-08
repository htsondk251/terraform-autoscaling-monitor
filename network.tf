resource "aws_vpc" "vpc" {
  cidr_block           = var.VPC_CIDR
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.PROJECT_NAME}-vpc"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.PROJECT_NAME}-igw"
  }
}

data "aws_availability_zones" "available_zones" {}

resource "aws_subnet" "public-subnet-1a" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.PUBLIC_SUBNET_1A_CIDR
  availability_zone       = data.aws_availability_zones.available_zones.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-1a"
  }
}

resource "aws_subnet" "public-subnet-1b" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.PUBLIC_SUBNET_1B_CIDR
  availability_zone       = data.aws_availability_zones.available_zones.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-1b"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table_association" "public-subnet-1a_route_table_association" {
  subnet_id      = aws_subnet.public-subnet-1a.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public-subnet-1b_route_table_association" {
  subnet_id      = aws_subnet.public-subnet-1b.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_eip" "nat_gw_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_gw_eip.id
  subnet_id     = aws_subnet.public-subnet-1a.id

  tags = {
    Name = "${var.PROJECT_NAME}-nat-gw"
  }

  depends_on = [
    aws_internet_gateway.internet_gateway,
    aws_eip.nat_gw_eip
  ]
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "private-rt"
  }
}

resource "aws_subnet" "private-subnet-1a" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.PRIVATE_SUBNET_1A_CIDR
  availability_zone       = data.aws_availability_zones.available_zones.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "private-subnet-1a"
  }
}

resource "aws_subnet" "private-subnet-1b" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.PRIVATE_SUBNET_1B_CIDR
  availability_zone       = data.aws_availability_zones.available_zones.names[1]
  map_public_ip_on_launch = false

  tags = {
    Name = "private-subnet-1b"
  }
}

resource "aws_route_table_association" "private-subnet-1a_route_table_association" {
  subnet_id      = aws_subnet.private-subnet-1a.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private-subnet-1b_route_table_association" {
  subnet_id      = aws_subnet.private-subnet-1b.id
  route_table_id = aws_route_table.private_route_table.id
}
