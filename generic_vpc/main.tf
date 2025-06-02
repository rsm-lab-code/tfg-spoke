# Get IPAM pool allocation for the VPC
resource "aws_vpc_ipam_pool_cidr_allocation" "vpc_cidr" {
  provider       = aws.delegated_account_us-west-2
  ipam_pool_id   = var.ipam_pool_id
  netmask_length = var.vpc_cidr_netmask
  description    = "CIDR allocation for ${var.vpc_name}"
}

# Create the VPC
resource "aws_vpc" "vpc" {
  provider             = aws.delegated_account_us-west-2
  cidr_block           = aws_vpc_ipam_pool_cidr_allocation.vpc_cidr.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.common_tags, {
    Name = var.vpc_name
    Environment = var.environment
  })
}

# Create public subnets
resource "aws_subnet" "public_subnet" {
  provider          = aws.delegated_account_us-west-2
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.vpc.id
  availability_zone = var.availability_zones[count.index]
  cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, var.subnet_prefix, count.index)

  tags = merge(var.common_tags, {
    Name = "${var.vpc_name}-public-subnet-${substr(var.availability_zones[count.index], -1, 1)}"
    Environment = var.environment
    Type = "public"
  })
}

# Create private subnets
resource "aws_subnet" "private_subnet" {
  provider          = aws.delegated_account_us-west-2
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.vpc.id
  availability_zone = var.availability_zones[count.index]
  cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, var.subnet_prefix, count.index + length(var.availability_zones))

  tags = merge(var.common_tags, {
    Name = "${var.vpc_name}-private-subnet-${substr(var.availability_zones[count.index], -1, 1)}"
    Environment = var.environment
    Type = "private"
  })
}

# Create route tables for public and private subnets
resource "aws_route_table" "public_rt" {
  provider = aws.delegated_account_us-west-2
  vpc_id   = aws_vpc.vpc.id

  tags = merge(var.common_tags, {
    Name = "${var.vpc_name}-public-rt"
    Environment = var.environment
  })
}

resource "aws_route_table" "private_rt" {
  provider = aws.delegated_account_us-west-2
  vpc_id   = aws_vpc.vpc.id

  tags = merge(var.common_tags, {
    Name = "${var.vpc_name}-private-rt"
    Environment = var.environment
  })
}

# Associate subnets with route tables
resource "aws_route_table_association" "public_rta" {
  provider       = aws.delegated_account_us-west-2
  count          = length(aws_subnet.public_subnet)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_rta" {
  provider       = aws.delegated_account_us-west-2
  count          = length(aws_subnet.private_subnet)
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_rt.id
}

# Create internet gateway for public access
resource "aws_internet_gateway" "igw" {
  provider = aws.delegated_account_us-west-2
  count    = var.create_igw ? 1 : 0
  vpc_id   = aws_vpc.vpc.id

  tags = merge(var.common_tags, {
    Name = "${var.vpc_name}-igw"
    Environment = var.environment
  })
}

# Add default route via IGW for public subnets
resource "aws_route" "public_rt_default" {
  provider               = aws.delegated_account_us-west-2
  count                  = var.create_igw ? 1 : 0
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw[0].id
}

# Attach VPC to Transit Gateway
resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_attachment" {
  provider           = aws.delegated_account_us-west-2
  subnet_ids         = aws_subnet.private_subnet[*].id
  transit_gateway_id = var.transit_gateway_id
  vpc_id             = aws_vpc.vpc.id
  
  appliance_mode_support                          = "enable"
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  
  tags = merge(var.common_tags, {
    Name = "${var.vpc_name}-tgw-attachment-usw2"
    Environment = var.environment
  })
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

# Add routes to other spoke VPCs via Transit Gateway in public route table
resource "aws_route" "public_rt_to_spoke_vpcs" {
  provider               = aws.delegated_account_us-west-2
  for_each              = var.spoke_vpc_routes
  
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = each.value
  transit_gateway_id     = var.transit_gateway_id

  depends_on = [
    aws_route_table.public_rt,
    aws_ec2_transit_gateway_vpc_attachment.tgw_attachment
  ]
}
