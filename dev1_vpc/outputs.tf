output "vpc_ids" {
  description = "IDs of the created VPCs"
  value = {
    "${var.aws_regions[0]}" = aws_vpc.vpc_west.id
   
  }
}

output "vpc_cidrs" {
  description = "CIDR blocks of the created VPCs"
  value = {
    "${var.aws_regions[0]}" = aws_vpc.vpc_west.cidr_block
    }
}

output "subnet_ids" {
  description = "IDs of the created subnets"
  value = {
    "${var.aws_regions[0]}" = aws_subnet.subnet_west[*].id   
  }
}

output "subnet_cidrs" {
  description = "CIDR blocks of the created subnets"
  value = {
    "${var.aws_regions[0]}" = aws_subnet.subnet_west[*].cidr_block
  }
}


