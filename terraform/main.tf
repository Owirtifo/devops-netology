# Configure the AWS Provider
provider "aws" {
  region     = "us-west-2"
}

# Find Image AMI Ubuntu
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners   = ["099720109477"]
}

# Create VPC
resource "aws_vpc" "vpc-test" {
  cidr_block = "10.10.0.0/16"

  tags = {
    Name = "VPC Test"
  }
}

# Create Subnet
resource "aws_subnet" "subnet_test" {
  vpc_id            = aws_vpc.vpc-test.id
  cidr_block        = "10.10.1.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "Subnet Test"
  }
}

# Create Security Group
resource "aws_security_group" "sg-test" {
  name        = "sg_test"
  description = "Test Security Group"
  vpc_id      = aws_vpc.vpc-test.id

  ingress = [
    {
      description      = "SSH"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      self             = false
      security_groups  = []
    },
  ]

  egress = [
    {
      description      = "All"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      self             = true
      security_groups  = []
    },
  ]

  tags = {
    Name = "SG Test"
  }
}

# Create Network Interface
resource "aws_network_interface" "ni_test" {
  subnet_id   = aws_subnet.subnet_test.id
  private_ips = ["10.10.1.5"]
  security_groups = [aws_security_group.sg-test.id]

  tags = {
    Name = "AWS NI Test"
  }
}

# Create Instace
resource "aws_instance" "netology" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  network_interface {
    network_interface_id = aws_network_interface.ni_test.id
    device_index         = 0
  }

  root_block_device {
          delete_on_termination = false
          iops                  = 3000
          tags                  = {
              Name = "Test EBS Volume"
	    }
          throughput            = 125
          volume_size           = 15
          volume_type           = "gp3"
        }

  tags = {
    Name = "Netology"
  }
}

# Get Account ID, User ID, and ARN in which Terraform is authorized.
data "aws_caller_identity" "current" {}

# Get AWS Region
data "aws_region" "current" {}

