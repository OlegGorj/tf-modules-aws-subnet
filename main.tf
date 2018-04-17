
###############################################################################
# variables
###############################################################################

variable "namespace" {
  description = "Namespace"
  type        = "string"
}

variable "stage" {
  description = "Stage (e.g. `prod`, `dev`, `staging`)"
  type        = "string"
}

variable "name" {
  type        = "string"
  description = "Application or solution name"
}

variable "delimiter" {
  type        = "string"
  default     = "-"
  description = "Delimiter to be used between `name`, `namespace`, `stage`, `attributes`"
}

variable "attributes" {
  type        = "list"
  default     = []
  description = "Additional attributes (e.g. `policy` or `role`)"
}

variable "tags" {
  type        = "map"
  default     = {}
  description = "Additional tags (e.g. map(`BusinessUnit`,`XYZ`)"
}

variable "subnet_names" {
  type        = "list"
  description = "List of subnet names (e.g. `['apples', 'oranges', 'grapes']`)"
}

variable "max_subnets" {
  default     = "16"
  description = "Maximum number of subnets which can be created. This variable is being used for CIDR blocks calculation. Default to length of `names` argument"
}

variable "type" {
  default     = "private"
  description = "Type of subnets (`private` or `public`)"
}

variable "availability_zone" {
  description = "Availability Zone"
}

variable "vpc_id" {
  description = "VPC ID"
}

variable "cidr_block" {
  description = "Base CIDR block which will be divided into subnet CIDR blocks (e.g. `10.0.0.0/16`)"
}

variable "igw_id" {
  description = "Internet Gateway ID which will be used as a default route in public route tables (e.g. `igw-9c26a123`). Conflicts with `ngw_id`"
  default     = ""
}

variable "ngw_id" {
  description = "NAT Gateway ID which will be used as a default route in private route tables (e.g. `igw-9c26a123`). Conflicts with `igw_id`"
  default     = ""
}

variable "public_network_acl_id" {
  description = "Network ACL ID that will be added to the subnets. If empty, a new ACL will be created "
  default     = ""
}

variable "private_network_acl_id" {
  description = "Network ACL ID that will be added to the subnets. If empty, a new ACL will be created "
  default     = ""
}

variable "public_network_acl_egress" {
  description = "Egress network ACL rules"
  type        = "list"

  default = [
    {
      rule_no    = 100
      action     = "allow"
      cidr_block = "0.0.0.0/0"
      from_port  = 0
      to_port    = 0
      protocol   = "-1"
    },
  ]
}

variable "public_network_acl_ingress" {
  description = "Egress network ACL rules"
  type        = "list"

  default = [
    {
      rule_no    = 100
      action     = "allow"
      cidr_block = "0.0.0.0/0"
      from_port  = 0
      to_port    = 0
      protocol   = "-1"
    },
  ]
}

variable "private_network_acl_egress" {
  description = "Egress network ACL rules"
  type        = "list"

  default = [
    {
      rule_no    = 100
      action     = "allow"
      cidr_block = "0.0.0.0/0"
      from_port  = 0
      to_port    = 0
      protocol   = "-1"
    },
  ]
}

variable "private_network_acl_ingress" {
  description = "Egress network ACL rules"
  type        = "list"

  default = [
    {
      rule_no    = 100
      action     = "allow"
      cidr_block = "0.0.0.0/0"
      from_port  = 0
      to_port    = 0
      protocol   = "-1"
    },
  ]
}

variable "enabled" {
  description = "Set to false to prevent the module from creating any resources"
  default     = "true"
}

variable "nat_enabled" {
  description = "Flag of creation NAT Gateway"
  default     = "true"
}

variable "eni_id" {
  default = ""
}

###############################################################################
# RESOURCES
###############################################################################


terraform {
  required_version = ">= 0.10.2"
}

data "aws_vpc" "default" {
  id = "${var.vpc_id}"
}

#data "aws_availability_zones" "available" {}


###############################################################################
# Outputs
###############################################################################

output "ngw_id" {
  value       = "${join("", aws_nat_gateway.default.*.id)}"
  description = "NAT Gateway ID"
}

output "ngw_private_ip" {
  value       = "${join("", aws_nat_gateway.default.*.private_ip)}"
  description = "Private IP address of the NAT Gateway"
}

output "ngw_public_ip" {
  value       = "${join("", aws_nat_gateway.default.*.public_ip)}"
  description = "Public IP address of the NAT Gateway"
}

output "subnet_ids" {
  value       = ["${coalescelist(aws_subnet.private.*.id, aws_subnet.public.*.id)}"]
  description = "Subnet IDs"
}

output "route_table_ids" {
  value       = ["${coalescelist(aws_route_table.public.*.id, aws_route_table.private.*.id)}"]
  description = "Route Table IDs"
}

output "named_subnet_ids" {
  description = "Map of subnet names to subnet IDs"
  value       = "${zipmap(var.subnet_names, matchkeys(coalescelist(aws_subnet.private.*.id, aws_subnet.public.*.id), coalescelist(aws_subnet.private.*.tags.Named, aws_subnet.public.*.tags.Named), var.subnet_names))}"
}
