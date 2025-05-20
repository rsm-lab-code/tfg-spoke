# Get IPAM pool allocation for the dev-vpc1
resource "aws_vpc_ipam_pool_cidr_allocation" "vpc_cidr" {
  provider       = aws.delegated_account_us-west-2
  ipam_pool_id   = var.ipam_pool_ids["us-west-2-nonprod-subnet1"]
  netmask_length = var.vpc_cidr_netmask
  description    = "CIDR allocation for ${var.vpc_name}"
}

# Create the VPC
resource "aws_vpc" "vpc" {
  provider             = aws.delegated_account_us-west-2
  cidr_block           = aws_vpc_ipam_pool_cidr_allocation.vpc_cidr.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}

# Create public subnets
resource "aws_subnet" "public_subnet_a" {
  provider          = aws.delegated_account_us-west-2
  vpc_id            = aws_vpc.vpc.id
  availability_zone = "${var.aws_regions[0]}a"
  cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, var.subnet_prefix, 0)

  tags = {
    Name = "${var.vpc_name}-public-subnet-use1-a"
  }
}

resource "aws_subnet" "public_subnet_b" {
  provider          = aws.delegated_account_us-west-2
  vpc_id            = aws_vpc.vpc.id
  availability_zone = "${var.aws_regions[0]}b"
  cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, var.subnet_prefix, 1)

  tags = {
    Name = "${var.vpc_name}-public-subnet-use1-b"
  }
}

# Create private subnets
resource "aws_subnet" "private_subnet_a" {
  provider          = aws.delegated_account_us-west-2
  vpc_id            = aws_vpc.vpc.id
  availability_zone = "${var.aws_regions[0]}a"
  cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, var.subnet_prefix, 2)

  tags = {
    Name = "${var.vpc_name}-private-subnet-use1-a"
  }
}

resource "aws_subnet" "private_subnet_b" {
  provider          = aws.delegated_account_us-west-2
  vpc_id            = aws_vpc.vpc.id
  availability_zone = "${var.aws_regions[0]}b"
  cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, var.subnet_prefix, 3)

  tags = {
    Name = "${var.vpc_name}-private-subnet-use1-b"
  }
}

# Create route tables for public and private subnets
resource "aws_route_table" "public_rt" {
  provider = aws.delegated_account_us-west-2
  vpc_id   = aws_vpc.vpc.id

  tags = {
    Name = "${var.vpc_name}-public-rt"
  }
}

resource "aws_route_table" "private_rt" {
  provider = aws.delegated_account_us-west-2
  vpc_id   = aws_vpc.vpc.id

  tags = {
    Name = "${var.vpc_name}-private-rt"
  }
}

# Associate subnets with route tables
resource "aws_route_table_association" "public_rta_a" {
  provider       = aws.delegated_account_us-west-2
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_rta_b" {
  provider       = aws.delegated_account_us-west-2
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_rta_a" {
  provider       = aws.delegated_account_us-west-2
  subnet_id      = aws_subnet.private_subnet_a.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_rta_b" {
  provider       = aws.delegated_account_us-west-2
  subnet_id      = aws_subnet.private_subnet_b.id
  route_table_id = aws_route_table.private_rt.id
}

# Create internet gateway for public access
resource "aws_internet_gateway" "igw" {
  provider = aws.delegated_account_us-west-2
  vpc_id   = aws_vpc.vpc.id

  tags = {
    Name = "${var.vpc_name}-igw"
  }
}

# Add default route via IGW for public subnets
resource "aws_route" "public_rt_default" {
  provider               = aws.delegated_account_us-west-2
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Attach VPC to Transit Gateway
resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_attachment" {
  provider           = aws.delegated_account_us-west-2
  subnet_ids         = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
  transit_gateway_id = var.transit_gateway_id
  vpc_id             = aws_vpc.vpc.id
  
  appliance_mode_support                          = "enable"
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  
  tags = {
    Name = "${var.vpc_name}-tgw-attachment-use1"
  }
}

# Associate with the transit gateway route table
resource "aws_ec2_transit_gateway_route_table_association" "tgw_rt_association" {
  provider                       = aws.delegated_account_us-west-2
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw_attachment.id
  transit_gateway_route_table_id = var.transit_gateway_route_table_id
}

# Add default route to TGW in the private route table
resource "aws_route" "private_rt_default" {
  provider               = aws.delegated_account_us-west-2
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = var.transit_gateway_id
}
#Create Propagation

resource "aws_ec2_transit_gateway_route_table_propagation" "tgw_rt_propagation" {
  provider                       = aws.delegated_account_us-west-2
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw_attachment.id  
  transit_gateway_route_table_id = var.transit_gateway_route_table_id
}
