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

resource "aws_instance" "my_Server" {
  ami           = "ami-085f9c64a9b75eed5"
  instance_type = "t2.micro"
}