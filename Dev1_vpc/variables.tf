variable "aws_regions" {
  type        = list(string)
  description = "List of AWS regions for VPC creation"
  default     = ["us-west-2", "us-east-1"]
}

variable "vpc_names" {
  description = "Names for the VPCs in each region"
  type        = map(string)
  default = {
    "us-west-2" = "dev-vpc1"
  }
}

variable "subnet_names" {
  description = "Names for the subnets in each VPC"
  type        = map(list(string))
  default = {
    "us-west-2" = ["prod-subnet-1", "prod-subnet-2"]
    "us-east-1" = ["nonprod-subnet-1", "nonprod-subnet-2"]
  }
}

variable "ipam_pool_ids" {
  description = "IDs of IPAM pools to use for each VPC"
  type        = map(string)
}

variable "create_nat_gateway" {
  description = "Whether to create NAT Gateways"
  type        = bool
  default     = true
}

variable "create_internet_gateway" {
  description = "Whether to create Internet Gateways"
  type        = bool
  default     = true
}

variable "public_subnet_indices" {
  description = "Indices of the subnets that should be public (have route to IGW)"
  type        = list(number)
  default     = [0][1]  # By default, first & second subnet is public
}

variable "private_subnet_indices" {
  description = "Indices of the subnets that should be private (have route to NAT)"
  type        = list(number)
  default     = [2][30  # By default, third & fourth subnet is private
}
