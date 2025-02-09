variable "profile" {
  type    = string
  default = "default"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "eks-project"
}

variable "vpc_cidr" {
  type        = string
  default     = "192.168.0.0/16"  
}

variable "public_subnets" {
  type        = list(string)
  default     = ["192.168.0.0/20", "192.168.16.0/20", "192.168.32.0/20"]
}

variable "private_subnets" {
  type        = list(string)
  default     = ["192.168.48.0/20", "192.168.64.0/20", "192.168.80.0/20"]
}

variable "your_public_ip" {
  type    = list(string)
  default = ["1.1.1.1/32"]
}

variable "node_app_listen_port" {
  type    = number
  default = 3000
}

##Uncomment for x86
/*
#x86-Bastion-Type
variable "bastion_instance_type" { // x86
  type    = string
  default = "t3a.medium"
}

#x86-Node-Type
variable "node_instance_types" { // x86
  type    = list(string)
  default = ["t3a.medium"]
}

#x86-AMI-Type
variable ami_type { // x86
  type    = string
  default = "AL2023_x86_64_STANDARD"
}

#Get Linux AMI ID using SSM Parameter endpoint for Linux-Ami/x86
data "aws_ssm_parameter" "linuxAmi" { // x86
  provider = aws.region-master
  name     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}
*/

##Comment for x86

#ARM-Node-Type
variable "node_instance_types" { // ARM
  type    = list(string)
  default = ["t4g.medium"]
}

#ARM-Bastion-Type
variable "bastion_instance_type" { // ARM
  type    = string
  default = "t4g.small"
}

#ARM-AMI-Type
variable ami_type { // ARM
  type    = string
  default = "AL2023_ARM_64_STANDARD"
}

#Get Linux AMI ID using SSM Parameter endpoint for Linux-Ami/ARM
data "aws_ssm_parameter" "linuxAmi" { // ARM
  provider = aws.region-master
  name     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-arm64-gp2"
}

variable "remote_user" {
  type    = string
  default = "ec2-user"
}

variable "public_key_file" {
  type    = string
  default = "~/.ssh/id_rsa_ter.pub"
}

variable "private_key_file" {
  type    = string
  default = "~/.ssh/id_rsa_ter"
}
