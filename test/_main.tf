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
    dynamodb_table = "terraform-lock"
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
  tags      = {environment = "dev", terraform = "true"}
}

locals {
  public_cidr_block  = "${cidrsubnet(module.vpc.vpc_cidr_block, 1, 0)}"
  private_cidr_block = "${cidrsubnet(module.vpc.vpc_cidr_block, 1, 1)}"
}

module "public_subnets" {
  source            = "git::https://github.com/oleggorj/tf-modules-aws-subnet.git?ref=dev-branch"
  namespace         = "${var.namespace}"
  stage             = "${var.env}"
  name              = "${var.name}"
  subnet_names      = ["web1"]
  vpc_id            = "${module.vpc.vpc_id}"
  cidr_block        = "${local.public_cidr_block}"
  type              = "public"
  igw_id            = "${module.vpc.igw_id}"
  availability_zone = "ca-central-1a"
  tags              = {environment = "dev", terraform = "true", type = "public", name = "web"}
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

output "public_cidr_block" {
  value = "${local.public_cidr_block}"
}
