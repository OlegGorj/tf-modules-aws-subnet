#
#
#
locals {
  public_count  = "${var.enabled == "true" && var.type == "public" ? length(var.subnet_names) : 0}"
  ngw_count     = "${var.enabled == "true" && var.type == "public" && var.nat_enabled == "true" ? 1 : 0}"
}

resource "aws_subnet" "public" {
  count             = "${local.public_count}"
  vpc_id            = "${var.vpc_id}"
  availability_zone = "${var.availability_zone}"
  cidr_block        = "${cidrsubnet(var.cidr_block, ceil(log(var.max_subnets, 2)), count.index)}"

  tags = "${merge(
    var.tags,
    map(
      "Name"             , "public-subnet${var.delimiter}${element(var.subnet_names, count.index)}",
      "stage"            , "${var.stage}",
      "namespace"        , "${var.namespace}",
      "backup" 			     , "false",
  		"purpose" 		     , "public_subnet",
  		"project" 		     , "infrastructure",
      "responsible_team" ,  "TECHNICAL",
      "type"             , "eip",
      "roles"            , "public-subnet-${var.availability_zone}",
      "terraform"        , "true"
    )
  )}"
}

resource "aws_route_table" "public" {
  count  = "${local.public_count}"
  vpc_id = "${var.vpc_id}"

  tags = {
    Name             = "route-table${var.delimiter}${element(var.subnet_names, count.index)}"
    stage            = "${var.stage}"
    namespace        = "${var.namespace}"
    backup 			     = "false"
		purpose 		     = "public_subnet"
		project 		     = "infrastructure"
    responsible_team =  "TECHNICAL"
    type             = "eip"
    roles            = "pub_subnet"
    terraform        = "true"
  }
}

resource "aws_route" "public" {
  count                  = "${local.public_count}"
  route_table_id         = "${element(aws_route_table.public.*.id, count.index)}"
  gateway_id             = "${var.igw_id}"
  destination_cidr_block = "0.0.0.0/0"

}

resource "aws_route_table_association" "public" {
  count          = "${local.public_count}"
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.public.*.id, count.index)}"
}

resource "aws_network_acl" "public" {
  count      = "${var.enabled == "true" && var.type == "public" && signum(length(var.public_network_acl_id)) == 0 ? 1 : 0}"
  vpc_id     = "${data.aws_vpc.default.id}"
  subnet_ids = ["${aws_subnet.public.*.id}"]
  egress     = "${var.public_network_acl_egress}"
  ingress    = "${var.public_network_acl_ingress}"

}

resource "aws_eip" "default" {
  count = "${local.ngw_count}"
  vpc   = "true"

  lifecycle {
    create_before_destroy = true
  }

  tags {
    Name             = "${var.stage}_public_subnet_eip"
    stage            = "${var.stage}"
    namespace        = "${var.namespace}"
		backup 			     = "false"
		purpose 		     = "public_subnet"
		project 		     = "infrastructure"
    responsible_team =  "TECHNICAL"
    type             = "eip"
    roles            = "pub_subnet"
    terraform        = "true"
  }

}

resource "aws_nat_gateway" "default" {
  count         = "${local.ngw_count}"
  allocation_id = "${join("", aws_eip.default.*.id)}"
  subnet_id     = "${element(aws_subnet.public.*.id, 0)}"

  lifecycle {
    create_before_destroy = true
  }

  tags {
    Name = "public-NAT-Gateway"
  }

}
