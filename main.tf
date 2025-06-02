# Get IPAM pool allocation for VPC (/21 as requested)
resource "aws_vpc_ipam_pool_cidr_allocation" "vpc_cidr" {
  provider       = aws.delegated_account_us-west-2
  ipam_pool_id   = var.ipam_pool_ids[var.vpc_config.ipam_pool_key]
  netmask_length = 21  
  description    = "CIDR allocation for ${var.vpc_config.name}"
}

# Create the VPC
resource "aws_vpc" "main" {
  provider             = aws.delegated_account_us-west-2
  cidr_block           = aws_vpc_ipam_pool_cidr_allocation.vpc_cidr.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = var.vpc_config.name
    Environment = var.vpc_config.environment
    ManagedBy   = "terraform"
  }
}

# Create public subnets 
resource "aws_subnet" "public" {
  provider = aws.delegated_account_us-west-2
  count    = 2

  vpc_id            = aws_vpc.main.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 3, count.index)  # /21 + 3 = /24

  tags = {
    Name = "${var.vpc_config.name}-public-${substr(data.aws_availability_zones.available.names[count.index], -1, 1)}"
    Type = "public"
    Environment = var.vpc_config.environment
    ManagedBy = "terraform"
  }
}

# Create private subnets 
resource "aws_subnet" "private" {
  provider = aws.delegated_account_us-west-2
  count    = 2

  vpc_id            = aws_vpc.main.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 3, count.index + 2)  # /21 + 3 = /24

  tags = {
    Name = "${var.vpc_config.name}-private-${substr(data.aws_availability_zones.available.names[count.index], -1, 1)}"
    Type = "private"
    Environment = var.vpc_config.environment
    ManagedBy = "terraform"
  }
}

# Create route tables
resource "aws_route_table" "public" {
  provider = aws.delegated_account_us-west-2
  vpc_id   = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_config.name}-public-rt"
    Environment = var.vpc_config.environment
    ManagedBy = "terraform"
  }
}

resource "aws_route_table" "private" {
  provider = aws.delegated_account_us-west-2
  vpc_id   = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_config.name}-private-rt"
    Environment = var.vpc_config.environment
    ManagedBy = "terraform"
  }
}

# Associate subnets with route tables
resource "aws_route_table_association" "public" {
  provider = aws.delegated_account_us-west-2
  count    = 2

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  provider = aws.delegated_account_us-west-2
  count    = 2

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Create Internet Gateway
resource "aws_internet_gateway" "main" {
  provider = aws.delegated_account_us-west-2
  vpc_id   = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_config.name}-igw"
    Environment = var.vpc_config.environment
    ManagedBy = "terraform"
  }
}

# Add default route for public subnets
resource "aws_route" "public_default" {
  provider               = aws.delegated_account_us-west-2
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# Transit Gateway attachment
resource "aws_ec2_transit_gateway_vpc_attachment" "main" {
  provider           = aws.delegated_account_us-west-2
  subnet_ids         = aws_subnet.private[*].id
  transit_gateway_id = var.transit_gateway_id
  vpc_id             = aws_vpc.main.id
  
  appliance_mode_support                          = "enable"
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  
  tags = {
    Name = "${var.vpc_config.name}-tgw-attachment"
    Environment = var.vpc_config.environment
    ManagedBy = "terraform"
  }
}

# Associate with Transit Gateway route table
resource "aws_ec2_transit_gateway_route_table_association" "main" {
  provider                       = aws.delegated_account_us-west-2
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.main.id
  transit_gateway_route_table_id = var.transit_gateway_route_table_id
}

# Add default route to TGW in private route table
resource "aws_route" "private_default" {
  provider               = aws.delegated_account_us-west-2
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = var.transit_gateway_id
}

# Add routes to other spoke VPCs via Transit Gateway in public route table
resource "aws_route" "public_to_spoke_vpcs" {
  provider               = aws.delegated_account_us-west-2
  for_each              = var.spoke_vpc_routes
  
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = each.value
  transit_gateway_id     = var.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.main]
}
