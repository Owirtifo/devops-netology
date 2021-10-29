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

# Adding Variable with Set IP address
locals {
  private_ips = toset(["10.10.1.5", "10.10.1.6"])
}


# Create Network Interface
resource "aws_network_interface" "ni_test" {
  for_each = local.private_ips
  subnet_id   = aws_subnet.subnet_test.id
  private_ips = [each.key] 
  #private_ips = ["10.10.1.5"]
  security_groups = [aws_security_group.sg-test.id]

  tags = {
    Name = "AWS NI Test"
  }
}

# Adding the Instance Type dependency on workspace
locals {
  netology_instance_type = {
    stage = "t2.micro"
    prod = "t3.large"
  }
}

# Adding the Count dependency on workspace
locals {
  netology_instance_count = {
    stage = 1
    prod = 2
  }
}


# Create Instace
resource "aws_instance" "netology" {
  #ami            = "ami-0964546d3da97e3ab"
  ami           = data.aws_ami.ubuntu.id
  instance_type = local.netology_instance_type[terraform.workspace]
  count = local.netology_instance_count[terraform.workspace]
  #instance_type = "t2.micro"
  vpc_security_group_ids = [aws_vpc.vpc-test.default_security_group_id]
  subnet_id = aws_subnet.subnet_test.id
  security_groups = [aws_security_group.sg-test.id]

  #network_interface {
   # network_interface_id = aws_network_interface.ni_test1.id
    #device_index         = 0
  #}

  root_block_device {
          delete_on_termination = true
          #iops                  = 3000
          tags                  = {
              Name = "Test EBS Volume"
	    }
          #throughput            = 125
          volume_size           = 8
          volume_type           = "gp2"
        }

  tags = {
    Name = "Netology-${count.index + 1}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Create Instace For_Each
resource "aws_instance" "netology_for_each" {
  for_each = aws_network_interface.ni_test
  ami           = data.aws_ami.ubuntu.id
  instance_type = local.netology_instance_type[terraform.workspace]
 
  network_interface {
    network_interface_id = each.value.id
    device_index         = 0
   }

  root_block_device {
          delete_on_termination = true
          tags                  = {
              Name = "Test EBS Volume"
            }
          volume_size           = 8
          volume_type           = "gp2"
        }

  tags = {
    Name = "Netology-${each.key}"
  }
}


# Get Account ID, User ID, and ARN in which Terraform is authorized.
data "aws_caller_identity" "current" {}

# Get AWS Region
data "aws_region" "current" {}

terraform {
  backend "s3" {
    bucket = "netologybucket"
    key    = "netology/terraform.tfstate"
    region = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-locks"
    workspace_key_prefix = "workspaces"
  }
}

#data "aws_network_interface" "bar" {
# id = "eni-0d94a7c8ca6cebd5d"
#}

#data "aws_security_group" "sg_data" {
#  id = "sg-6340b568"
#}

#data "aws_instance" "foo" {
#  instance_id = "i-01caea43f6e888246"
#}
