###############################################################################
# variables
###############################################################################
variable "region" {}
variable "env" {}
variable "state_bucket" {}
variable "kms_key_id" {}
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

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config {
    region     = "${var.region}"
    bucket     = "${var.state_bucket}"
    key        = "terraform/vpc/${var.env}.tfstate"
    profile    = "${var.env}"
    encrypt    = 1
    acl        = "private"
    kms_key_id = "${var.kms_key_id}"
  }
}

module "subnets" {
  source              = "git::https://github.com/cloudposse/terraform-aws-dynamic-subnets.git?ref=master"
  namespace           = "cp"
  stage               = "prod"
  name                = "app"
  region              = "${var.region}"
  vpc_id              = "${module.vpc.vpc_id}"
  igw_id              = "${module.vpc.igw_id}"
  cidr_block          = "${module.vpc.cidr_block}"
  availability_zones  = ["us-east-1a", "us-east-1b"]
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
