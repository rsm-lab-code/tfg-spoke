variable "spoke_vpc_attachments" {
  description = "Map of spoke VPC names to their CIDR blocks and TGW attachment IDs"
  type = map(object({
    cidr_block    = string
    attachment_id = string
  }))
}

variable "vpc_environments" {
  description = "Map of VPC names to their environments"
  type        = map(string)
}

variable "inspection_rt_id" {
  description = "ID of the inspection route table"
  type        = string
}

variable "main_rt_id" {
  description = "ID of the main route table"
  type        = string
}

variable "dev_rt_id" {
  description = "ID of the dev route table"
  type        = string 
  default     = null
}

variable "nonprod_rt_id" {
  description = "ID of the nonprod route table"
  type        = string
}


variable "prod_rt_id" {
  description = "ID of the Production Transit Gateway route table"
  type        = string
}


########################################################
#Blackhole variable 
variable "enable_environment_specific_routes" {
  description = "Whether to create specific routes for each VPC in environment route tables"
  type        = bool
  default     = true  
}

########################################################
