#!/bin/sh

export PATH=/usr/local/bin:$PATH;

yum install -y docker
sed -i '/OPTIONS=/c\OPTIONS="--default-ulimit nofile=1024:4096 -H tcp:\/\/0.0.0.0:2375 -H unix:\/\/\/var\/run\/docker.sock"' /etc/sysconfig/docker
service docker start
usermod -a -G docker ec2-user

docker run --init --rm ${command}