# Get IPAM pool allocation for nonprod_vpc1
resource "aws_vpc_ipam_pool_cidr_allocation" "nonprod_vpc1_cidr" {
  provider       = aws.delegated_account_us-west-2
  ipam_pool_id   = var.ipam_pool_ids["us-west-2-prod-subnet2"]  
  netmask_length = 23
  description    = "CIDR allocation for nonprod_vpc1"
}
resource "aws_vpc" "nonprod_vpc1" {
  provider             = aws.delegated_account_us-west-2
  cidr_block           = aws_vpc_ipam_pool_cidr_allocation.nonprod_vpc1_cidr.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "nonprod-vpc1"
  }
}
# Create public subnets
resource "aws_subnet" "nonprod_vpc1_public_subnet_a" {
  provider          = aws.delegated_account_us-west-2
  vpc_id            = aws_vpc.nonprod_vpc1.id
  availability_zone = "${var.aws_regions[0]}a"
  cidr_block        = cidrsubnet(aws_vpc.nonprod_vpc1.cidr_block, var.subnet_prefix, 0)

  tags = {
    Name = "nonprod-vpc1-public-subnet-use2-a"
  }
}

resource "aws_subnet" "nonprod_vpc1_public_subnet_b" {
  provider          = aws.delegated_account_us-west-2
  vpc_id            = aws_vpc.nonprod_vpc1.id
  availability_zone = "${var.aws_regions[0]}b"
  cidr_block        = cidrsubnet(aws_vpc.nonprod_vpc1.cidr_block, var.subnet_prefix, 1)

  tags = {
    Name = "nonprod-vpc1-public-subnet-use2-b"
  }
}

# Create private subnets
resource "aws_subnet" "nonprod_vpc1_private_subnet_a" {
  provider          = aws.delegated_account_us-west-2
  vpc_id            = aws_vpc.nonprod_vpc1.id
  availability_zone = "${var.aws_regions[0]}a"
  cidr_block        = cidrsubnet(aws_vpc.nonprod_vpc1.cidr_block, var.subnet_prefix, 2)

  tags = {
    Name = "nonprod-vpc1-private-subnet-use2-a"
  }
}

resource "aws_subnet" "nonprod_vpc1_private_subnet_b" {
  provider          = aws.delegated_account_us-west-2
  vpc_id            = aws_vpc.nonprod_vpc1.id
  availability_zone = "${var.aws_regions[0]}b"
  cidr_block        = cidrsubnet(aws_vpc.nonprod_vpc1.cidr_block, var.subnet_prefix, 3)

  tags = {
    Name = "nonprod-vpc1-private-subnet-use2-b"
  }
}

# Create route tables for public and private subnets
resource "aws_route_table" "nonprod_vpc1_public_rt" {
  provider = aws.delegated_account_us-west-2
  vpc_id   = aws_vpc.nonprod_vpc1.id

  tags = {
    Name = "nonprod-vpc1-public-rt"
  }
}

resource "aws_route_table" "nonprod_vpc1_private_rt" {
  provider = aws.delegated_account_us-west-2
  vpc_id   = aws_vpc.nonprod_vpc1.id

  tags = {
    Name = "nonprod-vpc1-private-rt"
  }
}

# Associate subnets with route tables
resource "aws_route_table_association" "nonprod_vpc1_public_rta_a" {
  provider       = aws.delegated_account_us-west-2
  subnet_id      = aws_subnet.nonprod_vpc1_public_subnet_a.id
  route_table_id = aws_route_table.nonprod_vpc1_public_rt.id
}

resource "aws_route_table_association" "nonprod_vpc1_public_rta_b" {
  provider       = aws.delegated_account_us-west-2
  subnet_id      = aws_subnet.nonprod_vpc1_public_subnet_b.id
  route_table_id = aws_route_table.nonprod_vpc1_public_rt.id
}

resource "aws_route_table_association" "nonprod_vpc1_private_rta_a" {
  provider       = aws.delegated_account_us-west-2
  subnet_id      = aws_subnet.nonprod_vpc1_private_subnet_a.id
  route_table_id = aws_route_table.nonprod_vpc1_private_rt.id
}

resource "aws_route_table_association" "nonprod_vpc1_private_rta_b" {
  provider       = aws.delegated_account_us-west-2
  subnet_id      = aws_subnet.nonprod_vpc1_private_subnet_b.id
  route_table_id = aws_route_table.nonprod_vpc1_private_rt.id
}

# Create internet gateway for public access
resource "aws_internet_gateway" "nonprod_vpc1_igw" {
  provider = aws.delegated_account_us-west-2
  vpc_id   = aws_vpc.nonprod_vpc1.id

  tags = {
    Name = "nonprod-vpc1-igw"
  }
}

# Add default route via IGW for public subnets
resource "aws_route" "nonprod_vpc1_public_rt_default" {
  provider               = aws.delegated_account_us-west-2
  route_table_id         = aws_route_table.nonprod_vpc1_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.nonprod_vpc1_igw.id
}

# Attach VPC to Transit Gateway
resource "aws_ec2_transit_gateway_vpc_attachment" "nonprod_vpc1_tgw_attachment" {
  provider           = aws.delegated_account_us-west-2
  subnet_ids         = [aws_subnet.nonprod_vpc1_private_subnet_a.id, aws_subnet.nonprod_vpc1_private_subnet_b.id]
  transit_gateway_id = var.transit_gateway_id
  vpc_id             = aws_vpc.nonprod_vpc1.id
  
  appliance_mode_support                          = "enable"
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  
  tags = {
    Name = "nonprod-vpc1-tgw-attachment-use2"
  }
}

# Associate with the transit gateway route table
resource "aws_ec2_transit_gateway_route_table_association" "nonprod_vpc1_tgw_rt_association" {
  provider                       = aws.delegated_account_us-west-2
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.nonprod_vpc1_tgw_attachment.id
  transit_gateway_route_table_id = var.transit_gateway_route_table_id
}

# Add default route to TGW in the private route table
resource "aws_route" "nonprod_vpc1_private_rt_default" {
  provider               = aws.delegated_account_us-west-2
  route_table_id         = aws_route_table.nonprod_vpc1_private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = var.transit_gateway_id
}


# Add routes to other spoke VPCs via Transit Gateway in public route table
resource "aws_route" "public_rt_to_spoke_vpcs" {
  provider               = aws.delegated_account_us-west-2
  for_each              = var.spoke_vpc_routes

  route_table_id         = aws_route_table.nonprod_vpc1_public_rt.id
  destination_cidr_block = each.value
  transit_gateway_id     = var.transit_gateway_id

  depends_on = [
    aws_route_table.nonprod_vpc1_public_rt,
    aws_ec2_transit_gateway_vpc_attachment.nonprod_vpc1_tgw_attachment
  ]
}
