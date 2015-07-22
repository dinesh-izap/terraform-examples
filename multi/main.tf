provider "azure" {
    settings_file = "${var.azure_settings_file}"
}

resource "azure_instance" "server" {
    name = "russ-terraform-test"
    hosted_service_name = "${var.hosted_service}"
    image = "OpenLogic 7.1"
    size = "Basic_A1"
    storage_service_name = "${var.storage_service}"
    location = "West Europe"
    username = "${var.azure_username}"
    ssh_key_thumbprint = "${var.azure_ssh_key_thumbprint}"

    endpoint {
        name = "SSH"
        protocol = "tcp"
        public_port = 22
        private_port = 22
    }

    endpoint {
        name = "WEB"
        protocol = "tcp"
        public_port = 80
        private_port = 80
    }

    connection {
        user = "${var.azure_username}"
        type = "ssh"
        key_file = "${var.pvt_key}"
        timeout = "2m"
        agent = false
    }

    provisioner "file" {
        source = "script.sh"
        destination = "/tmp/script.sh"
    }

    provisioner "remote-exec" {
        inline = ["bash /tmp/script.sh"]
    }

}

provider "digitalocean" {
    token = "${var.do_token}"
}

resource "digitalocean_droplet" "server" {
    image = "centos-7-0-x64"
    name = "${var.server_name}"
    region = "nyc2"
    size = "512mb"
    ssh_keys = [
        "${var.do_ssh_fingerprint}"
    ]

    connection {
        user = "root"
        type = "ssh"
        key_file = "${var.pvt_key}"
        timeout = "2m"
        agent = false
    }

    provisioner "file" {
        source = "script.sh"
        destination = "/tmp/script.sh"
    }

    provisioner "remote-exec" {
        inline = ["bash /tmp/script.sh"]
    }

}

provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region = "us-east-1"
}

resource "aws_instance" "server" {

    ami = "ami-96a818fe"
    instance_type = "t2.micro"
    subnet_id = "${var.aws_subnet_id }"
    security_groups = [ "${aws_security_group.web.id}", "${aws_security_group.ssh.id}", "${aws_security_group.all_outgoing.id}"]
    key_name = "${var.aws_key_name}"

    connection {
        user = "centos"
        type = "ssh"
        key_file = "${var.pvt_key}"
        timeout = "2m"
        agent = false
    }

    provisioner "file" {
        source = "script.sh"
        destination = "/tmp/script.sh"
    }

    provisioner "remote-exec" {
        inline = ["bash /tmp/script.sh"]
    }

    tags {
        Name = "${var.server_name}"
    }

}

resource "aws_security_group" "web" {
  name = "web"
  description = "Allow all web traffic"
  vpc_id = "${var.aws_vpc}"

  ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "web"
  }
}

resource "aws_security_group" "ssh" {
  name = "ssh"
  description = "Allow all ssh traffic"
  vpc_id = "${var.aws_vpc}"

  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "ssh"
  }
}

resource "aws_security_group" "all_outgoing" {
  name = "all_outgoing"
  description = "Allow all outgoing traffic"
  vpc_id = "${var.aws_vpc}"

  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }

    tags {
    Name = "all_outgoing"
  }

}

resource "aws_route53_record" "testing" {
   zone_id = "${var.aws_hosted_zone_id}"
   name = "${var.fqdn}"
   type = "A"
   ttl = "300"
   records = [ "${aws_instance.server.public_ip}", "${azure_instance.server.vip_address}", "${digitalocean_droplet.server.ipv4_address}"]
}