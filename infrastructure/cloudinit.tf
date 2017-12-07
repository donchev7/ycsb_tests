data "template_file" "redis-script" {
  template = "${file("scripts/run_container.sh")}"
  vars {
      command = "--name redis -d --net=host redis:4-alpine"
  }
}

data "template_file" "tarantool-script" {
  template = "${file("scripts/run_tarantool.sh")}"
  vars {
      command = "--name tarantool -d -v /home/ec2-user/app.lua:/opt/tarantool/app.lua --net=host tarantool/tarantool:1.8"
  }
}

data "template_file" "aerospike-script" {
  template = "${file("scripts/run_aerospike.sh")}"
  vars {
      command = "--name aerospike -d --net=host -v /home/ec2-user/:/opt/aerospike/etc aerospike/aerospike-server"
  }
}

data "template_file" "ycsb-script" {
  template = "${file("scripts/run_container.sh")}"
  vars {
      command = "--name ycsb --net=host donchev7/alpine-ycsb:0.12.0 -h"
  }
}
