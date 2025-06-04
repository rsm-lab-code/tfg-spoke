output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.vpc.id
}

output "vpc_cidr" {
  description = "CIDR block of the created VPC"
  value       = aws_vpc.vpc.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public_subnet[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private_subnet[*].id
}

output "route_table_ids" {
  description = "IDs of the route tables"
  value       = {
    public  = aws_route_table.public_rt.id
    private = aws_route_table.private_rt.id
  }
}

output "tgw_attachment_id" {
  description = "ID of the Transit Gateway attachment"
  value       = aws_ec2_transit_gateway_vpc_attachment.tgw_attachment.id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway (if created)"
  value       = local.actual_create_igw ? aws_internet_gateway.igw[0].id : null
}

output "availability_zones" {
  description = "Availability zones used by this VPC"
  value       = local.actual_availability_zones
}