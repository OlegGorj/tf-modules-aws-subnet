###############################################################################
# variables
###############################################################################
variable "region" {}
variable "env" {}
variable "state_bucket" {}
variable "kms_key_id" {}
variable "namespace" {
  default = "awscloud"
}
variable "name" {
  default = "testcluster"
}
variable "cred-file" {
  default = "~/.aws/credentials"
}

###############################################################################
# RESOURCES
###############################################################################
terraform {
  backend "s3" {
    encrypt = true
    acl     = "private"
#    dynamodb_table = "terraform-lock"
  }
}

provider "aws" {
  region                   = "${var.region}"
  shared_credentials_file  = "${var.cred-file}"
  profile                  = "${var.env}"
}

module "vpc" {
  source    = "git::https://github.com/OlegGorj/tf-modules-aws-vpc.git?ref=dev-branch"
  namespace = "${var.namespace}"
  stage     = "${var.env}"
  name      = "${var.name}"
  tags      = {Name = "TestVPN", environment = "dev", terraform = "true"}

}


locals {
  # Note: newbits=1 in cidrsubnet(module.vpc.vpc_cidr_block, 1, ..) will give me 2 subnets
  ca_central_1a_public_cidr_block  = "${cidrsubnet(module.vpc.vpc_cidr_block, 2, 0)}"
  ca_central_1a_private_cidr_block = "${cidrsubnet(module.vpc.vpc_cidr_block, 2, 1)}"
  ca_central_1b_private_cidr_block = "${cidrsubnet(module.vpc.vpc_cidr_block, 2, 2)}"
}

module "public_subnets" {
  source            = "git::https://github.com/oleggorj/tf-modules-aws-subnet.git?ref=dev-branch"
  namespace         = "${var.namespace}"
  stage             = "${var.env}"
  name              = "public subnet 1A"
  subnet_names      = ["web1"]
  vpc_id            = "${module.vpc.vpc_id}"
  cidr_block        = "${local.ca_central_1a_public_cidr_block}"
  type              = "public"
  igw_id            = "${module.vpc.igw_id}"
  availability_zone = "ca-central-1a"
  attributes        = ["ca-central-1a"]
  tags              = {environment = "dev", terraform = "true", type = "public", name = "web", az = "ca-central-1a"}
}

module "private_subnets_1" {
  source            = "git::https://github.com/oleggorj/tf-modules-aws-subnet.git?ref=dev-branch"
  namespace         = "${var.namespace}"
  stage             = "${var.env}"
  name              = "private subnet 1A"
  subnet_names      = ["cassandra"]
  vpc_id            = "${module.vpc.vpc_id}"
  cidr_block        = "${local.ca_central_1a_private_cidr_block}"
  type              = "private"
  ngw_id            = "${module.public_subnets.ngw_id}"
  availability_zone = "ca-central-1a"
  attributes        = ["ca-central-1a"]
  tags              = {environment = "dev", terraform = "true", type = "private", name = "database", az = "ca-central-1a"}
}
module "private_subnets_2" {
  source            = "git::https://github.com/oleggorj/tf-modules-aws-subnet.git?ref=dev-branch"
  namespace         = "${var.namespace}"
  stage             = "${var.env}"
  name              = "private subnet 1B"
  subnet_names      = ["cassandra"]
  vpc_id            = "${module.vpc.vpc_id}"
  cidr_block        = "${local.ca_central_1b_private_cidr_block}"
  type              = "private"
  ngw_id            = "${module.public_subnets.ngw_id}"
  availability_zone = "ca-central-1b"
  attributes        = ["ca-central-1b"]
  tags              = {environment = "dev", terraform = "true", type = "private", name = "database", az = "ca-central-1b"}
}


###############################################################################
# Outputs
###############################################################################
output "environment" {
  value = "${var.env}"
}

output "vpc_id" {
  value = "${module.vpc.vpc_id}"
}

output "subnet_ids" {
  value = "${module.public_subnets.subnet_ids}"
}
output "private_subnet_ids" {
  value = "${module.private_subnets_1.subnet_ids}"
}
