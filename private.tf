#
#
#

locals {
  private_count = "${var.enabled == "true" && var.type == "private" ? length(var.subnet_names) : 0}"
}

resource "aws_subnet" "private" {
  count             = "${local.private_count}"
  vpc_id            = "${var.vpc_id}"
  availability_zone = "${var.availability_zone}"
  cidr_block        = "${cidrsubnet(var.cidr_block, ceil(log(var.max_subnets, 2)), count.index)}"
#  tags {
#    Name = "${var.name}"
#  }
  tags                             = "${var.tags}"
}

resource "aws_route_table" "private" {
  count  = "${local.private_count}"
  vpc_id = "${var.vpc_id}"
}

resource "aws_route" "private" {
  count                  = "${local.private_count}"
  route_table_id         = "${element(aws_route_table.private.*.id, count.index)}"
  network_interface_id   = "${var.eni_id}"
  nat_gateway_id         = "${var.ngw_id}"
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "private" {
  count          = "${local.private_count}"
  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
}

resource "aws_network_acl" "private" {
  count      = "${var.enabled == "true" && var.type == "private" && signum(length(var.private_network_acl_id)) == 0 ? 1 : 0}"
  vpc_id     = "${data.aws_vpc.default.id}"
  subnet_ids = ["${aws_subnet.private.*.id}"]
  egress     = "${var.private_network_acl_egress}"
  ingress    = "${var.private_network_acl_ingress}"
}
