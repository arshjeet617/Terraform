terraform {
  backend "s3" {
    bucket = "assignment1akaur617"  // Bucket where to SAVE Terraform State
    key    = "assignment1/terraform.tfstate" // Object name in the bucket to SAVE Terraform State
    region = "us-east-1"                 // Region where bucket is created
  }
}
output "public_ip" {
  value = aws_instance.my_amazon.public_ip
}
# Security Group
resource "aws_security_group" "web_sg" {
  name        = "allow_http_ssh"
  description = "Allow HTTP and SSH inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "HTTP from everywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "SSH from everywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  
  ingress {
    description      = "tcp from everywhere"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "tcp from everywhere"
    from_port        = 8081
    to_port          = 8081
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# Step 1 - Define the provider
provider "aws" {
  region = "us-east-1"
}

# Data source for availability zones in us-east-1
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  public_cidrs = "10.15.0.0/24"
  vpc_cidr     = "10.15.0.0/16"
}

# Create a new VPC 
resource "aws_vpc" "main" {
  cidr_block       = local.vpc_cidr
  instance_tenancy = "default"
}



# Add provisioning of the public subnet2 in the custom VPC
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.public_cidrs
  availability_zone = data.aws_availability_zones.available.names[0]
}


# Create Internet Gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.main.id
}

# Route table to route add default gateway pointing to Internet Gateway (IGW)
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
}



# Associate subnets with the custom route table
resource "aws_route_table_association" "public_route_table_association" {
  route_table_id = aws_route_table.public_route_table.id
  subnet_id      = aws_subnet.public_subnet.id
}
# Data source for AMI id
data "aws_ami" "latest_amazon_linux" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Reference subnet provisioned by 01-Networking 
resource "aws_instance" "my_amazon" {
  ami                         = data.aws_ami.latest_amazon_linux.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.web_key.key_name
  subnet_id                   = aws_subnet.public_subnet.id
  security_groups             = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }
}

# Adding SSH key to Amazon EC2
resource "aws_key_pair" "web_key" {
  key_name   = "assignment1"
  public_key = file("assignment1.pub")
}

resource "aws_ecr_repository" "clo835-assignment-1" {
  name                 = "clo835-assignment1"
 

}

