#!/bin/sh

export PATH=/usr/local/bin:$PATH;

cat << EOF >> /home/ec2-user/aerospike.conf

service {
	user root
	group root
	paxos-single-replica-limit 1
	pidfile /var/run/aerospike/asd.pid
	service-threads 4
	transaction-queues 4
	transaction-threads-per-queue 4
	proto-fd-max 1024
}
logging {
    file /var/log/aerospike/aerospike.log {
        context any info
    }
}
network {
	service {
		address any
		port 3000
	}
	heartbeat {
		mode mesh
		port 3002
		interval 150
		timeout 10
	}
	fabric {
		port 3001
	}
	info {
		port 3003
	}
}
namespace ycsb {
	replication-factor 1
	memory-size 15G
	default-ttl 5d
	storage-engine device {
		file /opt/aerospike/data/test.dat
		filesize 4G
		data-in-memory true # Store data in memory in addition to file.
	}
}
EOF

yum install -y docker
service docker start
usermod -a -G docker ec2-user

docker run --init --rm ${command} --config-file /opt/aerospike/etc/aerospike.conf