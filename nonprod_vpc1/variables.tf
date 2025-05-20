variable "aws_regions" {
  description = "List of AWS regions for deploying resources"
  type        = list(string)
  default     = ["us-west-2", "us-east-1"]
}

variable "delegated_account_id" {
  description = "AWS Account ID for delegated account where VPC is created"
  type        = string
}

variable "ipam_pool_ids" {
  description = "IDs of subnet pools from IPAM"
  type        = map(string)
}

variable "vpc_cidr_netmask" {
  description = "Netmask for the VPC CIDR allocation"
  type        = number
  default     = 23
}

variable "subnet_prefix" {
  description = "Additional bits for subnet CIDR division within VPC"
  type        = number
  default     = 4
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "nonprod-vpc1"
}


variable "transit_gateway_id" {
  description = "ID of the Transit Gateway to attach to"
  type        = string
}

variable "transit_gateway_route_table_id" {
  description = "ID of the Transit Gateway route table for workload VPCs"
  type        = string
}
