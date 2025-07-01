output "inspection_rt_routes" {
  description = "Routes created in the inspection route table"
  value = {
    for name, route in aws_ec2_transit_gateway_route.inspection_rt_spoke_routes : name => {
      destination_cidr_block        = route.destination_cidr_block
      transit_gateway_attachment_id = route.transit_gateway_attachment_id
      route_table_id               = route.transit_gateway_route_table_id
    }
  }
}

output "main_rt_routes" {
  description = "Routes created in the main route table"
  value = {
    for name, route in aws_ec2_transit_gateway_route.main_rt_spoke_routes : name => {
      destination_cidr_block        = route.destination_cidr_block
      transit_gateway_attachment_id = route.transit_gateway_attachment_id
      route_table_id               = route.transit_gateway_route_table_id
    }
  }
}

output "prod_rt_routes" {
  description = "Routes created in the prod route table"
  value = {
    for name, route in aws_ec2_transit_gateway_route.prod_rt_spoke_routes : name => {
      destination_cidr_block        = route.destination_cidr_block
      transit_gateway_attachment_id = route.transit_gateway_attachment_id
      route_table_id               = route.transit_gateway_route_table_id
    }
  }
}
output "nonprod_rt_routes" {
  description = "Routes created in the nonprod route table"
  value = {
    for name, route in aws_ec2_transit_gateway_route.nonprod_rt_spoke_routes : name => {
      destination_cidr_block        = route.destination_cidr_block
      transit_gateway_attachment_id = route.transit_gateway_attachment_id
      route_table_id               = route.transit_gateway_route_table_id
    }
  }
}

output "total_routes_created" {
  description = "Summary of total routes created across all route tables"
  value = {
    inspection_routes = length(aws_ec2_transit_gateway_route.inspection_rt_spoke_routes)
    main_routes       = length(aws_ec2_transit_gateway_route.main_rt_spoke_routes)
    prod_routes       = length(aws_ec2_transit_gateway_route.prod_rt_spoke_routes)
    nonprod_routes    = length(aws_ec2_transit_gateway_route.nonprod_rt_spoke_routes)
    total_routes      = (
      length(aws_ec2_transit_gateway_route.inspection_rt_spoke_routes) +
      length(aws_ec2_transit_gateway_route.main_rt_spoke_routes) +
      #length(aws_ec2_transit_gateway_route.dev_rt_spoke_routes) +
      length(aws_ec2_transit_gateway_route.nonprod_rt_spoke_routes) +
      length(aws_ec2_transit_gateway_route.prod_rt_spoke_routes)
    )
  }
}

output "routes_by_vpc" {
  description = "All routes organized by VPC name"
  value = {
    for vpc_name in keys(var.spoke_vpc_attachments) : vpc_name => {
      cidr_block = var.spoke_vpc_attachments[vpc_name].cidr_block
      attachment_id = var.spoke_vpc_attachments[vpc_name].attachment_id
      environment = lookup(var.vpc_environments, vpc_name, "unknown")
      routes_created_in = compact([
        "inspection_rt",
        "main_rt",
        # contains(keys(aws_ec2_transit_gateway_route.dev_rt_spoke_routes), vpc_name) ? "dev_rt" : "",
        contains(keys(aws_ec2_transit_gateway_route.nonprod_rt_spoke_routes), vpc_name) ? "nonprod_rt" : "",
        contains(keys(aws_ec2_transit_gateway_route.prod_rt_spoke_routes), vpc_name) ? "prod_rt" : ""
      ])
    }
  }
}

########################################################
#Blackhole output
output "environment_specific_routes_enabled" {
  description = "Whether environment-specific routes are enabled"
  value       = var.enable_environment_specific_routes
}

########################################################
