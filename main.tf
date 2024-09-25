terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-2"
}

variable "server_port" {
  description = "The port the server will be listening on"
  default = 8080
  type = number
}

resource "aws_instance" "my_server" {
  ami           = "ami-085f9c64a9b75eed5"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y busybox
    echo "<html><body><h1>Hello, World</h1></body></html>" > index.html
    nohup busybox httpd -f -p ${var.server_port} &
    EOF

  tags = {
    Name = "terraform-server-name"
  }
}

resource "aws_security_group" "instance" {

  name = "terraform-server-example"

  ingress {
    from_port = var.server_port
    to_port = var.server_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "public_ip" {
  value = aws_instance.my_server.public_ip
  description = "The public IP address of the web server" #
}