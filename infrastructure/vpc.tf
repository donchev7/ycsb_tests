#
# VPC
#
resource "aws_vpc" "main" {
    cidr_block = "10.0.16.0/24"
    instance_tenancy = "default"
    enable_dns_support = "true"
    enable_dns_hostnames = "true"
    enable_classiclink = "false"
    tags {
        Name = "${var.name}"
        Group = "${var.name}"
    }
}

#
# Private Subnet for Redis and Tarantool
#
resource "aws_subnet" "ycsb-priv-subnet" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "10.0.16.1/28"
    map_public_ip_on_launch = "false"
    availability_zone = "${data.aws_availability_zones.available.names[0]}"
    tags {
            Name = "${var.name}-priv-subnet"
    }
}

#
# Public Subnet for YCSB
# 
resource "aws_subnet" "ycsb-pub-subnet" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "10.0.16.16/28"
    map_public_ip_on_launch = "true"
    availability_zone = "${data.aws_availability_zones.available.names[0]}"
    tags {
            Name = "${var.name}-pub-subnet"
    }
}


#
# Internet GW
#
resource "aws_internet_gateway" "internet-gw" {
    vpc_id = "${aws_vpc.main.id}"

    tags {
        Name = "${var.name}-interet-gw"
    }
}

#
# Route Tables
#
resource "aws_route_table" "main-public" {
    vpc_id = "${aws_vpc.main.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.internet-gw.id}"
    }

    tags {
        Name = "${var.name}-rt-table"
    }
}
resource "aws_route_table_association" "main-public-1-a" {
    subnet_id = "${aws_subnet.ycsb-pub-subnet.id}"
    route_table_id = "${aws_route_table.main-public.id}"
}

resource "aws_elasticache_subnet_group" "elasticache" {
  name       = "elasticache-subnet"
  subnet_ids = ["${aws_subnet.ycsb-priv-subnet.id}"]
}