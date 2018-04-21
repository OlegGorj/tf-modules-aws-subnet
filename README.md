[![GitHub release](https://img.shields.io/github/release/OlegGorj/tf-modules-aws-subnet.svg)](https://github.com/OlegGorj/tf-modules-aws-subnet/releases)
[![GitHub issues](https://img.shields.io/github/issues/OlegGorj/tf-modules-aws-subnet.svg)](https://github.com/OlegGorj/tf-modules-aws-subnet/issues)
[![Codacy Badge](https://api.codacy.com/project/badge/Grade/0c85a578cb0c4c85bddb373a6f3686ce)](https://app.codacy.com/app/oleggorj/tf-modules-aws-subnet?utm_source=github.com&utm_medium=referral&utm_content=OlegGorj/tf-modules-aws-subnet&utm_campaign=badger)

# Terraform Module: AWS Subnet

Terraform module for creating subnets on AWS VPC

### Prerequisites:

- existing CMK in AWS KMS
- generated keys pair
- created S3 bucket to store TF state


## How to use Subnets module:

Example of `../environments/dev/dev.tfvars` file:

```bash
export ENVIRONMENT="dev"

export AWS_REGION="ca-central-1"
export AWS_PROFILE="default"

export AWS_STATE_BUCKET="tf-state-bucket"

export AWS_KMS_ARN="arn:aws:kms:ca-central-1:4545454545:key/xxxxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxxxx"
export TF_VAR_kms_key_id=${AWS_KMS_ARN}
```

Init terraform:

```bash

# example of usage is located under ./test directory
cd test

terraform init  \
    -backend-config="bucket=ca-central-1.aws-terraform-state-bucket" \
    -backend-config="key=terraform/dev/tf.tfstate" \
    -backend-config="region=ca-central-1" \
    -backend-config="profile=dev"  \
    -var-file=../environments/dev/dev.tfvars

```

Plan terraform:

```bash
terraform plan -var-file=../environments/dev/dev.tfvars -out=./terraform
```

Apply terraform:

```bash
terraform apply -var-file=../environments/dev/dev.tfvars
```


## Subnet calculation

For subnet set calculation, the module uses Terraform interpolation `cidrsubnet` (docs: https://www.terraform.io/docs/configuration/interpolation.html#cidrsubnet-iprange-newbits-netnum-).

The `cidrsubnet()` function has the following signature:

`cidrsubnet(iprange, newbits, netnum)`

where:

- `iprange` is the CIDR block of your virtual network,
- `newbits` is the new mask for the subnet within the virtual network, and
- `netnum` is the zero-based index of the subnet when the network is masked with the `newbit`.


Calculate `newbits`:
    `newbits` number specifies how many subnets be the CIDR block (input or VPC) will be divided into. `newbits` is the number of binary digits.


Example:

```
newbits = 1 - 2 subnets are available (1 binary digit allows to count up to 2)

newbits = 2 - 4 subnets are available (2 binary digits allows to count up to 4)

newbits = 3 - 8 subnets are available (3 binary digits allows to count up to 8)

etc.
```

We know, that we have 6 AZs in a `us-east-1 `region.

We need to create 1 public subnet and 1 private subnet in each AZ, thus we need to create 12 subnets in total (6 AZs * (1 public + 1 private)).

We need 4 binary digits for that ( 24 = 16 ). In order to calculate the number of binary digits we should use logarithm function. We should use base 2 logarithm because decimal numbers can be calculated as powers of binary number. See Wiki for more details

Example:

```
For 12 subnets we need 3.58 binary digits (log212)

For 16 subnets we need 4 binary digits (log216)

For 7 subnets we need 2.81 binary digits (log27)

etc.
```

We can't use fractional values to calculate the number of binary digits. We can't round it down because smaller number of binary digits is insufficient to represent the required subnets. We round it up. See ceil.

Example:
```
For 12 subnets we need 4 binary digits (ceil(log212))

For 16 subnets we need 4 binary digits (ceil(log216))

For 7 subnets we need 3 binary digits (ceil(log27))

etc.
```

Assign private subnets according to AZ number (we're using count.index for that).

Assign public subnets according to AZ number but with a shift according to the number of AZs in the region (see step 2)


Using the logic above, to create 1 public subnet and 2 private subnets, the following TF code:

```
locals {
  ca_central_1a_public_cidr_block  = "${cidrsubnet(module.vpc.vpc_cidr_block, 2, 0)}"
  ca_central_1a_private_cidr_block = "${cidrsubnet(module.vpc.vpc_cidr_block, 2, 1)}"
  ca_central_1b_private_cidr_block = "${cidrsubnet(module.vpc.vpc_cidr_block, 2, 2)}"
}
```

---
