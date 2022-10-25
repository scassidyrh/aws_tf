terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "eu-west-2"
}

variable ami_to_use {
  type = string
  default = "ami-0648ea225c13e0729"
}

variable keypair_to_use {
  type = string
  default = "*** PUT SSH PUBLIC KEY HERE ***"
}

resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "main"
  }
}

resource "aws_subnet" "private_sub" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "private_subnet"
  }
}

resource "aws_subnet" "public_sub" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.10.0/24"
  tags = {
    "Name" = "public_subnet"
  }

}

resource "aws_route_table" "route_table_1" {
  vpc_id     = aws_vpc.main.id
  tags = {
    "Name" = "RT1"
  }
}


resource "aws_route_table_association" "public" {
  subnet_id = aws_subnet.public_sub.id
  route_table_id = aws_route_table.route_table_1.id
}

resource "aws_internet_gateway" "igw_1" {
  vpc_id = aws_vpc.main.id
  tags = {
    "Name" = "Internet Gateway"
  }
}

resource "aws_route" "internet_route" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id = aws_route_table.route_table_1.id
  gateway_id = aws_internet_gateway.igw_1.id
}

resource "aws_key_pair" "keypair1" {
  key_name   = "keypair1"
  public_key = var.keypair_to_use
}

resource "aws_security_group" "pub_sg" {
  name = "allow web access"
  description = "allow inbound traffic"
  vpc_id = aws_vpc.main.id
   
  ingress {
     to_port = "22"
     from_port = "22"
     protocol = "tcp"
     cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "0"
    protocol = "-1"
    to_port = "0"
  }
  tags = {
    "Name" = "SG1"
  }
}

resource "aws_eip" "ip_one" {
  vpc = true
  network_interface = aws_network_interface.nic_1.id
  tags = {
    "Name" = "EIP1"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id = aws_subnet.private_sub.id
  route_table_id = aws_route_table.route_table_1.id
}



resource "aws_network_interface" "nic_1" {
  subnet_id   = aws_subnet.private_sub.id
  private_ips = ["10.0.1.10"]
  security_groups = [aws_security_group.pub_sg.id]

  tags = {
    Name = "primary_network_interface"
  }
}
#
resource "aws_instance" "instance1" {
  ami           = var.ami_to_use
  instance_type = "t2.micro"
  network_interface {
    network_interface_id = aws_network_interface.nic_1.id
    device_index = 0
  }
  key_name = aws_key_pair.keypair1.key_name
}
