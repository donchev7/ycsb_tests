#
# A project name
#
variable "name" {
  default = "YCSB-perf-test"
  description = "We will use this variable for tagging purposes"
}

#
# Your IP for security
#
variable "your_ip" {
  description = "Please insert your Public IP, if you dont know it run\ncurl -s https://donchev.is/what-is-my-ip | jq '.IP'"
}

#
# AWS Region
#
variable "region" {
  default = "eu-west-1"
  description = "change the default region here or when you do terraform plan / apply"
}

# SSH keys for the instances
variable "PATH_TO_PRIVATE_KEY" {
  default = "keys/ycsb"
}

variable "PATH_TO_PUBLIC_KEY" {
  default = "keys/ycsb.pub"
}