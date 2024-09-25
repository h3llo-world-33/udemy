resource "aws_security_group" "instance" {
  name        = "terraform-server-example"
 

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "EC2_Server" {
  ami           = ami-085f9c64a9b75eed5
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]

 user_data = <<-EOF
 #!/bin/bash
 echo "Hello, World" > index.html
 nohup busybox httpd -f -p ${var.server_port} &
 EOF

 tags {
   Name = "terraform-server-example"
 }
}
