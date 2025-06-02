variable "vpc_config" {
  description = "VPC configuration"
  type = object({
    name         = string
    environment  = string
    ipam_pool_key = string
  })
}

variable "aws_regions" {
  description = "List of AWS regions"
  type        = list(string)
  default     = ["us-west-2", "us-east-1"]
}

variable "delegated_account_id" {
  description = "AWS Account ID for delegated account"
  type        = string
}

variable "ipam_pool_ids" {
  description = "IDs of subnet pools from IPAM"
  type        = map(string)
}

variable "transit_gateway_id" {
  description = "ID of the Transit Gateway"
  type        = string
}

variable "transit_gateway_route_table_id" {
  description = "ID of the Transit Gateway route table"
  type        = string
}

variable "spoke_vpc_routes" {
  description = "Map of other spoke VPC CIDR blocks for routing"
  type        = map(string)
  default     = {}
}
