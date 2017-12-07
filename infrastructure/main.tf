#
# AWS as provider
#
provider "aws" {
  region = "${var.region}"
}

#
# Data resource for availability zone
#
data "aws_availability_zones" "available" {}

#
# AMI selector for AWS Linux
#
data "aws_ami" "aws_linux_latest" {
  most_recent = true
  filter {
    name = "name"
    values = ["amzn-ami-*-x86_64-gp2"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name = "owner-alias"
    values = ["amazon"]
  }
}

#
# KeyPair for ssh
#
resource "aws_key_pair" "YCSB-key" {
  key_name = "YCSB-key"
  public_key = "${file("${var.PATH_TO_PUBLIC_KEY}")}"
}

#
# YCSB instance
#
resource "aws_instance" "YCSB-tester" {
  ami           = "${data.aws_ami.aws_linux_latest.id}"
  instance_type = "c4.2xlarge"
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  subnet_id = "${aws_subnet.ycsb-pub-subnet.id}"
  key_name = "${aws_key_pair.YCSB-key.key_name}"
  vpc_security_group_ids = ["${aws_security_group.allow-ssh-docker.id}"]
  user_data = "${data.template_file.ycsb-script.rendered}"
  depends_on = [
    "aws_route_table_association.main-private-1-a",
    "aws_nat_gateway.nat-gw"
  ]
  tags {
    Name = "${var.name}-TestPerformer"
  }
}


#
# Redis instance
#
resource "aws_instance" "Redis-tester" {
  ami           = "${data.aws_ami.aws_linux_latest.id}"
  instance_type = "m4.xlarge"
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  subnet_id = "${aws_subnet.ycsb-priv-subnet.id}"
  key_name = "${aws_key_pair.YCSB-key.key_name}"
  vpc_security_group_ids = ["${aws_security_group.allow-all.id}"]
  user_data = "${data.template_file.redis-script.rendered}"
  depends_on = [
    "aws_route_table_association.main-private-1-a",
    "aws_nat_gateway.nat-gw"
  ]
  tags {
    Name = "${var.name}-RedisContainerInstance"
  }
}

#
# Tarantool instance
#
resource "aws_instance" "Tarantool-tester" {
  ami           = "${data.aws_ami.aws_linux_latest.id}"
  instance_type = "m4.xlarge"
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  subnet_id = "${aws_subnet.ycsb-priv-subnet.id}"
  key_name = "${aws_key_pair.YCSB-key.key_name}"
  vpc_security_group_ids = ["${aws_security_group.allow-all.id}"]
  user_data = "${data.template_file.tarantool-script.rendered}"
  depends_on = [
    "aws_route_table_association.main-private-1-a",
    "aws_nat_gateway.nat-gw"
  ]
  tags {
    Name = "${var.name}-TarantoolContainerInstance"
  }
}

#
# Aerospike instance
#
resource "aws_instance" "Aerospike-tester" {
  ami           = "${data.aws_ami.aws_linux_latest.id}"
  instance_type = "m4.xlarge"
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  subnet_id = "${aws_subnet.ycsb-priv-subnet.id}"
  key_name = "${aws_key_pair.YCSB-key.key_name}"
  vpc_security_group_ids = ["${aws_security_group.allow-all.id}"]
  user_data = "${data.template_file.aerospike-script.rendered}"
  depends_on = [
    "aws_route_table_association.main-private-1-a",
    "aws_nat_gateway.nat-gw"
  ]
  tags {
    Name = "${var.name}-AerospikeContainerInstance"
  }
}
#
# Elasticache instance
#
resource "aws_elasticache_cluster" "Elasticache-tester" {
  cluster_id           = "elasticache-ycsb"
  engine               = "redis"
  engine_version       = "3.2.4"
  node_type            = "cache.m4.xlarge"
  port                 = 6379
  num_cache_nodes      = 1
  parameter_group_name = "default.redis3.2"
  subnet_group_name    = "${aws_elasticache_subnet_group.elasticache.name}"
  security_group_ids   = ["${aws_security_group.allow-all.id}"]
    tags {
    Name = "${var.name}-ManagedRedis"
  }
}

output "YCSB-tester" {
  value = "${aws_instance.YCSB-tester.public_ip}"
}

output "Redis-tester" {
  value = "${aws_instance.Redis-tester.private_ip}"
}

output "Tarantool-tester" {
  value = "${aws_instance.Tarantool-tester.private_ip}"
}

output "Elasticache-tester" {
  value = "${aws_elasticache_cluster.Elasticache-tester.cache_nodes.0.address}"
}

output "Aerospike-tester" {
  value = "${aws_instance.Aerospike-tester.private_ip}"
}
