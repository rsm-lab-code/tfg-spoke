# Get IPAM pool allocation for dev_vpc2
resource "aws_vpc_ipam_pool_cidr_allocation" "dev_vpc2_cidr" {
  provider       = aws.delegated_account_us-west-2
   ipam_pool_id   = var.ipam_pool_ids["us-west-2-prod-subnet1"]
  netmask_length = var.vpc_cidr_netmask
  # netmask_length = 23
  description    = "CIDR allocation for dev-vpc2"
}

# Create the VPC
resource "aws_vpc" "dev_vpc2" {
  provider             = aws.delegated_account_us-west-2
  cidr_block           = aws_vpc_ipam_pool_cidr_allocation.dev_vpc2_cidr.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "dev-vpc2"
  }
}

# Create public subnets
resource "aws_subnet" "dev_vpc2_public_subnet_a" {
  provider          = aws.delegated_account_us-west-2
  vpc_id            = aws_vpc.dev_vpc2.id
  availability_zone = "${var.aws_regions[0]}a"
  cidr_block        = cidrsubnet(aws_vpc.dev_vpc2.cidr_block, var.subnet_prefix, 0)

  tags = {
    Name = "dev-vpc2-public-subnet-use1-a"
  }
}

resource "aws_subnet" "dev_vpc2_public_subnet_b" {
  provider          = aws.delegated_account_us-west-2
  vpc_id            = aws_vpc.dev_vpc2.id
  availability_zone = "${var.aws_regions[0]}b"
  cidr_block        = cidrsubnet(aws_vpc.dev_vpc2.cidr_block, var.subnet_prefix, 1)

  tags = {
    Name = "dev-vpc2-public-subnet-use1-b"
  }
}

# Create private subnets
resource "aws_subnet" "dev_vpc2_private_subnet_a" {
  provider          = aws.delegated_account_us-west-2
  vpc_id            = aws_vpc.dev_vpc2.id
  availability_zone = "${var.aws_regions[0]}a"
  cidr_block        = cidrsubnet(aws_vpc.dev_vpc2.cidr_block, var.subnet_prefix, 2)

  tags = {
    Name = "dev-vpc2-private-subnet-use1-a"
  }
}

resource "aws_subnet" "dev_vpc2_private_subnet_b" {
  provider          = aws.delegated_account_us-west-2
  vpc_id            = aws_vpc.dev_vpc2.id
  availability_zone = "${var.aws_regions[0]}b"
  cidr_block        = cidrsubnet(aws_vpc.dev_vpc2.cidr_block, var.subnet_prefix, 3)

  tags = {
    Name = "dev-vpc2-private-subnet-use1-b"
  }
}

# Create route tables for public and private subnets
resource "aws_route_table" "dev_vpc2_public_rt" {
  provider = aws.delegated_account_us-west-2
  vpc_id   = aws_vpc.dev_vpc2.id

  tags = {
    Name = "dev-vpc2-public-rt"
  }
}

resource "aws_route_table" "dev_vpc2_private_rt" {
  provider = aws.delegated_account_us-west-2
  vpc_id   = aws_vpc.dev_vpc2.id

  tags = {
    Name = "dev-vpc2-private-rt"
  }
}

# Associate subnets with route tables
resource "aws_route_table_association" "dev_vpc2_public_rta_a" {
  provider       = aws.delegated_account_us-west-2
  subnet_id      = aws_subnet.dev_vpc2_public_subnet_a.id
  route_table_id = aws_route_table.dev_vpc2_public_rt.id
}

resource "aws_route_table_association" "dev_vpc2_public_rta_b" {
  provider       = aws.delegated_account_us-west-2
  subnet_id      = aws_subnet.dev_vpc2_public_subnet_b.id
  route_table_id = aws_route_table.dev_vpc2_public_rt.id
}

resource "aws_route_table_association" "dev_vpc2_private_rta_a" {
  provider       = aws.delegated_account_us-west-2
  subnet_id      = aws_subnet.dev_vpc2_private_subnet_a.id
  route_table_id = aws_route_table.dev_vpc2_private_rt.id
}

resource "aws_route_table_association" "dev_vpc2_private_rta_b" {
  provider       = aws.delegated_account_us-west-2
  subnet_id      = aws_subnet.dev_vpc2_private_subnet_b.id
  route_table_id = aws_route_table.dev_vpc2_private_rt.id
}

# Create internet gateway for public access
resource "aws_internet_gateway" "dev_vpc2_igw" {
  provider = aws.delegated_account_us-west-2
  vpc_id   = aws_vpc.dev_vpc2.id

  tags = {
    Name = "dev-vpc2-igw"
  }
}

# Add default route via IGW for public subnets
resource "aws_route" "dev_vpc2_public_rt_default" {
  provider               = aws.delegated_account_us-west-2
  route_table_id         = aws_route_table.dev_vpc2_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.dev_vpc2_igw.id
}

# Attach VPC to Transit Gateway
resource "aws_ec2_transit_gateway_vpc_attachment" "dev_vpc2_tgw_attachment" {
  provider           = aws.delegated_account_us-west-2
  subnet_ids         = [aws_subnet.dev_vpc2_private_subnet_a.id, aws_subnet.dev_vpc2_private_subnet_b.id]
  transit_gateway_id = var.transit_gateway_id
  vpc_id             = aws_vpc.dev_vpc2.id
  
  appliance_mode_support                          = "enable"
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  
  tags = {
    Name = "dev-vpc2-tgw-attachment-use1"
  }
}

# Associate with the transit gateway route table
resource "aws_ec2_transit_gateway_route_table_association" "dev_vpc2_tgw_rt_association" {
  provider                       = aws.delegated_account_us-west-2
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.dev_vpc2_tgw_attachment.id
  transit_gateway_route_table_id = var.transit_gateway_route_table_id
}

# Propagate routes to the transit gateway route table
resource "aws_ec2_transit_gateway_route_table_propagation" "dev_vpc2_tgw_rt_propagation" {
  provider                       = aws.delegated_account_us-west-2
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.dev_vpc2_tgw_attachment.id
  transit_gateway_route_table_id = var.transit_gateway_route_table_id
}

# Add default route to TGW in the private route table
resource "aws_route" "dev_vpc2_private_rt_default" {
  provider               = aws.delegated_account_us-west-2
  route_table_id         = aws_route_table.dev_vpc2_private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = var.transit_gateway_id
}
