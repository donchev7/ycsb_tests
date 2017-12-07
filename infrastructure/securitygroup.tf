resource "aws_security_group" "allow-ssh-docker" {
  vpc_id = "${aws_vpc.main.id}"
  name = "allow-ssh-docker"
  description = "security group that allows ssh and all egress traffic"
  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["${var.your_ip}/32"]
  }

  ingress {
      from_port = 2375
      to_port = 2375
      protocol = "tcp"
      cidr_blocks = ["${var.your_ip}/32"]
  }
  tags {
    Name = "${var.name}-sg-allow-ssh-docker"
  }
}

resource "aws_security_group" "allow-all" {
  vpc_id = "${aws_vpc.main.id}"
  name = "allow-all"
  description = "security group that allows all ingress and egress traffic"
  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  } 
tags {
    Name = "${var.name}-sg-allow-all"
  }
}