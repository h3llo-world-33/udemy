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

resource "aws_launch_configuration" "example" {
  image_id           = "ami-085f9c64a9b75eed5"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.instance.id]

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

  lifecycle {
    create_before_destroy = true
  }
}

# get the details of default vpc
data "aws_vpc" "default" {
  default = true
}

# use the default vpc id and get the default subnets ids 
data "aws_subnet_ids" "default_subnet_ids" {
  vpc_id = data.aws_vpc_default.default.id
}

resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.name
  # use the default subnet ids
  vpc_zone_identifier = data.aws_subnet_ids.default_subnet_ids.ids

  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  min_size = 2
  max_size = 10

  tag {
    key = "Name"
    value = "terraform-asg-example"
    propagate_at_launch = true
  }
}

resource "aws_security_group" "alb" {
  name = "terraform-example-alb"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "example" {
  name = "terraform-asg-example"
  load_balancer_type = "application"
  subnets = data.aws_subnet_ids.default_subnet_ids.ids
  security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response = {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code = 404
    }
  }
}

resource "aws_lb_target_group" "asg" {
  name = "terraform-example-target-group"

  port = var.server_port
  protocol = "HTTP"
  vpc_id = data.aws_vpc.default.id

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

