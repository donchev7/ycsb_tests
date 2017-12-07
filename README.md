# YCSB Tests
## for Aerospike, AWS Elasticache, Redis and Tarantool

For more information about this repository read the post [here](http://donchev.is).

To do the tests yourself start by building the ycsb container:
```code bash
docker build -t ycsb -f Docker/Dockerfile_ycsb .
```
You can also use my image hosted on docker hub donchev7/alpine-ycsb:0.12.0

Now would be a good time to provision the infrastructure for the tests. I use terraform and the corresponding terraform files can be found in the infrastructure directory.

You can provision the infrastructure by running
```code bash
cd infrastructure/
terraform init
terraform plan
terraform apply
```
Terrafrom will provision an AWS managed Elasticache Node (redis) m3.large and 4x m3.large ec2 instances. These Nodes are:<br />
1x redis<br />
1x tarantool<br />
1x aerospike<br />
1x test runner<br />

After terraform has provisioned the infrastructure you can run the ycsb.py script from your laptop. The python script will use the docker api and connect to the remote ec2 instance to perform the tests. In order for this to work you will need to run the script as follows:
```bash
python ycsb.py run --html=True --stdout=True --config_file='ycsb_conf.dat' --docker_host='tcp://54.246.252.45:2375'
```
Change the docker host IP with the IP terraform provided you in the previous step (YCSB-Tester)

The command above will create an HTML file for the results in your current directory named results.html
If you need to ssh into the running instances you can do so by using the private key located in the infrastructure/keys directory:
```bash
ssh -i infrastructure/keys/ycsb ec2-user@10.0.0.16
```
Change the IP in the above command to the IP of the YCSB-Tester. Note that you can not ssh directly into the other running instances but you can use the YCSB-Tester instance as a bastion host to get access to the others. Also, note that by default SSH and Docker API access is restricted to your Public IP only.
When you are done with your tests you can destroy the infrastructure by issuing:
```terraform destroy```
<br />

## YCSB Configuration

The ycsb_conf.dat file holds the configuration for the YCSB tester. You can define recordcount, operationcount...etc.. values in there. For a full list of configuration values please have a look at the official [documentation](https://github.com/brianfrankcooper/YCSB/wiki/Core-Properties)

After creating the infrastructure with terraform you will need to open this file to edit the Server IPs. Terraform will output all the IPs and you can paste them into the [Servers] section.

You can also define which workloads to run. Note that even if you only specify to run workloadC the script will first load the data using workloadA. This is in accordance with the official YCSB documentation.