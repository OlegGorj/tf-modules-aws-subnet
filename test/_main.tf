###############################################################################
# variables
###############################################################################
variable "region" {}
variable "env" {}
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
  }
}

provider "aws" {
  region                   = "${var.region}"
  shared_credentials_file  = "${var.cred-file}"
  profile                  = "${var.env}"
}

# call vpc module
module "vpc" {
  source    = "git::https://github.com/OlegGorj/tf-modules-aws-vpc.git?ref=dev-branch"
  namespace = "awscloud"
  stage     = "${var.env}"
  name      = "testcluster"
  tags      = {environment = "dev", terraform = "true"}
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
