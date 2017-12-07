#
# Nat Gw for the instances in the private subnet
#
resource "aws_eip" "nat" {
  vpc      = true
}
resource "aws_nat_gateway" "nat-gw" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id = "${aws_subnet.ycsb-pub-subnet.id}"
  depends_on = ["aws_internet_gateway.internet-gw"]
}

#
# Routing setup for NAT
#
resource "aws_route_table" "main-private" {
    vpc_id = "${aws_vpc.main.id}"
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = "${aws_nat_gateway.nat-gw.id}"
    }

    tags {
        Name = "${var.name}-private-route"
    }
}

#
# Route Associations Private Subnet
#
resource "aws_route_table_association" "main-private-1-a" {
    subnet_id = "${aws_subnet.ycsb-priv-subnet.id}"
    route_table_id = "${aws_route_table.main-private.id}"
}