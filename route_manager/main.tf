# Add routes to inspection route table for all spoke VPCs
resource "aws_ec2_transit_gateway_route" "inspection_rt_spoke_routes" {
  provider                       = aws.delegated_account_us-west-2
  for_each                      = var.spoke_vpc_attachments

  destination_cidr_block        = each.value.cidr_block
  transit_gateway_attachment_id = each.value.attachment_id
  transit_gateway_route_table_id = var.inspection_rt_id
}

# Add routes to main route table for all spoke VPCs
resource "aws_ec2_transit_gateway_route" "main_rt_spoke_routes" {
  provider                       = aws.delegated_account_us-west-2
  for_each                      = var.spoke_vpc_attachments

  destination_cidr_block        = each.value.cidr_block
  transit_gateway_attachment_id = each.value.attachment_id
  transit_gateway_route_table_id = var.main_rt_id
}

# Add routes for spoke VPCs to their respective environment route tables
resource "aws_ec2_transit_gateway_route" "dev_rt_spoke_routes" {
  provider                       = aws.delegated_account_us-west-2
  for_each = {
    for name, vpc in var.spoke_vpc_attachments : name => vpc
    if lookup(var.vpc_environments, name, "") == "dev"
  }

  destination_cidr_block         = each.value.cidr_block
  transit_gateway_attachment_id  = each.value.attachment_id
  transit_gateway_route_table_id = var.dev_rt_id
}

resource "aws_ec2_transit_gateway_route" "nonprod_rt_spoke_routes" {
  provider                       = aws.delegated_account_us-west-2
  for_each = {
    for name, vpc in var.spoke_vpc_attachments : name => vpc
    if lookup(var.vpc_environments, name, "") == "nonprod"
  }

  destination_cidr_block         = each.value.cidr_block
  transit_gateway_attachment_id  = each.value.attachment_id
  transit_gateway_route_table_id = var.nonprod_rt_id
}
