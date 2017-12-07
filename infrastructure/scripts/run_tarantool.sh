#!/bin/sh

export PATH=/usr/local/bin:$PATH;

cat << EOF >> /home/ec2-user/app.lua
box.cfg {
   listen = "0.0.0.0:3301",
   log = "tarantool.log",
   log_level = 5,
   log_nonblock = true,
   wal_mode = "none",
}

box.schema.space.create("ycsb", {id = 1024})
box.space.ycsb:create_index("primary", {type = "hash", parts = {1, "string"}})
EOF

yum install -y docker
service docker start
usermod -a -G docker ec2-user

docker run --init --rm ${command} tarantool /opt/tarantool/app.lua