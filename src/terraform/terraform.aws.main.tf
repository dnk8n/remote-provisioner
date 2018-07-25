variable "vpc_id" {
  default = ""
}
variable "subnet_id" {
  default = ""
}
variable "ami_owners" {
  type = "list"
  default = ["amazon"]
}
variable "ami_name_regex" {
  default = "amzn-ami-*"
}
variable "ami_most_recent" {
  default = true
}
variable "ssh_user" {
  default = "ec2-user"
}
variable "instance_type" {
  default = "t2.nano"
}
variable "iam_instance_profile" {
  default = ""
}
variable "region" {
  default = "us-east-1"
}
variable "zone" {
  default = ""
}
variable "timeout_minutes" {
  default = 1
}
variable "file_or_dir_source" {
  default = "terraform.aws.main.tf"
}
variable "file_or_dir_dest" {
  default = "/tmp/terraform.aws.main.tf"
}
variable "remote_command" {
  type = "list"
  default = ["echo 'Hello World!' && ls -lah /tmp/terraform.aws.main.tf"]
}
variable "security_group_id" {
  default = ""
}
variable "ingress_security_groups" {
  type = "list"
  default = []
}
variable "ingress_security_groups_from_port" {
  default = 0
}
variable "ingress_security_groups_to_port" {
  default = 0
}

provider "http" {}

provider "tls" {}

provider "aws" {
  region = "${var.region}"
}

data "aws_vpc" "provisioner" {
  default = "${var.vpc_id == "" ? true : false}"
  filter {
    name = "vpc-id"
    values = ["${var.vpc_id == "" ? "*" : var.vpc_id}"]
  }
}

data "aws_ami" "provisioner" {
  most_recent = "${var.ami_most_recent}"
  owners = "${var.ami_owners}"
  name_regex = "${var.ami_name_regex}"
}

data "http" "my_public_ip" {
  url = "http://icanhazip.com"
}

resource "tls_private_key" "provisioner" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "aws_key_pair" "provisioner" {
  key_name = "temp-provisioner-${uuid()}"
  public_key = "${tls_private_key.provisioner.public_key_openssh}"
}

resource "aws_security_group" "provisioner" {
  name = "temp-provisioner-${uuid()}"
  vpc_id = "${data.aws_vpc.provisioner.id}"
  ingress {
    from_port = "${var.ingress_security_groups_from_port}"
    to_port = "${var.ingress_security_groups_to_port}"
    protocol = "tcp"
    security_groups = "${var.ingress_security_groups}"
    description = "Managed by Terraform"
  }
  egress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Managed by Terraform"
  }
}

resource "aws_security_group_rule" "allow_ssh" {
  security_group_id = "${var.security_group_id == "" ? aws_security_group.provisioner.id : var.security_group_id}"
  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = ["${chomp(data.http.my_public_ip.body)}/32"]
  description = "Managed by Terraform"
}

resource "aws_instance" "provisioner" {
  ami = "${data.aws_ami.provisioner.id}"
  instance_type = "${var.instance_type}"
  iam_instance_profile = "${var.iam_instance_profile}"
  tags {
    Name = "temp-provisioner-${uuid()}"
  }
  availability_zone = "${var.zone == "" ? "" : format(var.region, var.zone)}"
  key_name = "${aws_key_pair.provisioner.key_name}"
  subnet_id = "${var.subnet_id}"
  vpc_security_group_ids = [
    "${var.security_group_id == "" ? aws_security_group.provisioner.id : var.security_group_id}"
  ]
  user_data = <<EOF
#!/usr/bin/env bash
shutdown -P +${var.timeout_minutes}
EOF
  provisioner "file" {
    source = "${var.file_or_dir_source}"
    destination = "${var.file_or_dir_dest}"
    connection {
      user = "${var.ssh_user}"
      private_key = "${tls_private_key.provisioner.private_key_pem}"
      agent = false
    }
  }
  provisioner "remote-exec" {
    inline = "${var.remote_command}"
    connection {
      user = "${var.ssh_user}"
      private_key = "${tls_private_key.provisioner.private_key_pem}"
      agent = false
    }
  }
}

