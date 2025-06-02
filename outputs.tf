output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the created VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "route_table_ids" {
  description = "IDs of the route tables"
  value       = {
    public  = aws_route_table.public.id
    private = aws_route_table.private.id
  }
}

output "tgw_attachment_id" {
  description = "ID of the Transit Gateway attachment"
  value       = aws_ec2_transit_gateway_vpc_attachment.main.id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}
