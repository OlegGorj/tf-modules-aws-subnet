
###############################################################################
# variables
###############################################################################

variable "namespace" {
  type        = "string"
  description = "Namespace"
}

variable "stage" {
  type        = "string"
  description = "Stage (e.g. `prod`, `dev`, `staging`)"
}

variable "name" {
  type        = "string"
  description = "Name (e.g. `app`)"
}

variable "delimiter" {
  type        = "string"
  default     = "-"
  description = "Delimiter to be used between `namespace`, `stage`, `name`, and `attributes`"
}

variable "attributes" {
  type        = "list"
  default     = []
  description = "Additional attributes (e.g. `policy` or `role`)"
}

variable "tags" {
  type        = "map"
  default     = {}
  description = "Additional tags (e.g. map(`Cluster`,`XYZ`)"
}

variable "region" {
  type        = "string"
  description = "AWS Region (e.g. `us-east-1`)"
}

variable "vpc_id" {
  type        = "string"
  description = "VPC ID where subnets will be created (e.g. `vpc-aceb2723`)"
}

variable "igw_id" {
  type        = "string"
  description = "Internet Gateway ID the public route table will point to (e.g. `igw-9c26a123`)"
}

variable "cidr_block" {
  type        = "string"
  description = "Base CIDR block which will be divided into subnet CIDR blocks (e.g. `10.0.0.0/16`)"
}

variable "availability_zones" {
  type        = "list"
  description = "List of Availability Zones where subnets will be created"
}

variable "vpc_default_route_table_id" {
  default     = ""
  description = "Default route table for public subnets. If not set, will be created. (e.g. `rtb-f4f0ce12`)"
}

variable "public_network_acl_id" {
  default     = ""
  description = "Network ACL ID that will be added to public subnets. If empty, a new ACL will be created"
}

variable "private_network_acl_id" {
  default     = ""
  description = "Network ACL ID that will be added to private subnets. If empty, a new ACL will be created"
}

variable "nat_gateway_enabled" {
  description = "Flag to enable/disable NAT gateways for private subnets"
  default     = "true"
}

###############################################################################
# RESOURCES
###############################################################################


terraform {
  required_version = ">= 0.10.2"
}

# Get object aws_vpc by vpc_id
data "aws_vpc" "default" {
  id = "${var.vpc_id}"
}

data "aws_availability_zones" "available" {}


###############################################################################
# Outputs
###############################################################################

output "public_subnet_ids" {
  value = ["${aws_subnet.public.*.id}"]
}

output "private_subnet_ids" {
  value = ["${aws_subnet.private.*.id}"]
}

output "public_route_table_ids" {
  value = ["${aws_route_table.public.*.id}"]
}

output "private_route_table_ids" {
  value = ["${aws_route_table.private.*.id}"]
}
