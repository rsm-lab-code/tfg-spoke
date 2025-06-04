variable "aws_regions" {
  description = "List of AWS regions for deploying resources"
  type        = list(string)
  default     = ["us-west-2", "us-east-1"]
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "environment" {
  description = "Environment type (prod, nonprod, dev, staging, etc.)"
  type        = string
}

variable "delegated_account_id" {
  description = "AWS Account ID for delegated account where VPC is created"
  type        = string
}

variable "ipam_pool_id" {
  description = "ID of the IPAM subnet pool for CIDR allocation"
  type        = string
}

# Made these nullable with defaults handled by locals
variable "vpc_cidr_netmask" {
  description = "Netmask for the VPC CIDR allocation. If null, uses environment default."
  type        = number
  default     = null
}

variable "subnet_prefix" {
  description = "Additional bits for subnet CIDR division within VPC. If null, uses environment default."
  type        = number
  default     = null
}

variable "availability_zones" {
  description = "List of availability zones for subnet creation. If empty, uses first 2 AZs dynamically."
  type        = list(string)
  default     = []
}

variable "transit_gateway_id" {
  description = "ID of the Transit Gateway to attach to"
  type        = string
}

variable "transit_gateway_route_table_id" {
  description = "ID of the Transit Gateway route table for this VPC"
  type        = string
}

variable "spoke_vpc_routes" {
  description = "Map of other spoke VPC names to their CIDR blocks for routing"
  type        = map(string)
  default     = {}
}

variable "create_igw" {
  description = "Whether to create an Internet Gateway for this VPC. If null, uses environment default."
  type        = bool
  default     = null
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy = "terraform"
  }
}