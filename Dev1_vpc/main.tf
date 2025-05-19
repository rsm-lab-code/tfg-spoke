# Create VPC in us-west-2 using production pool
resource "aws_vpc" "vpc_west" {
  provider = aws.delegated_account_us-west-2
  
  # Use IPAM pool for IP assignment
  ipv4_ipam_pool_id   = var.ipam_pool_ids["us-west-2-prod"]
  ipv4_netmask_length = 21
  
  tags = {
    Name = var.vpc_names["us-west-2"]
    Environment = "Production"
  }
}

# Create four subnets in us-west-2 VPC
resource "aws_subnet" "subnet_west" {
  count = 4
  provider = aws.delegated_account_us-west-2
  
  vpc_id = aws_vpc.vpc_west.id
  
   # We'll calculate a /24 CIDR from the VPC CIDR
  cidr_block = cidrsubnet(aws_vpc.vpc_west.cidr_block, 3, count.index)
  
  availability_zone = "${var.aws_regions[0]}${count.index == 0 ? "a" : "b"}"
  
  tags = {
    Name = var.subnet_names["us-west-2"][count.index]
    Environment = "Production"
  }
}


