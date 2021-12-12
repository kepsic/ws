## Create main.tf
# ref https://cloudaffaire.com/how-to-deploy-a-lamp-stack-in-aws-using-terraform/
#creates VPC, one public subnet, two private subnets, one EC2 instance and one MYSQL RDS instance

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

  owners = ["099720109477"] # Canonical
}


# Create (and display) an SSH key
resource "tls_private_key" "emonstack_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "web" {
  key_name   = "emonstack-key"
  public_key = tls_private_key.emonstack_ssh.public_key_openssh
}

# get AZ's details
data "aws_availability_zones" "availability_zones" {}

# create VPC
resource "aws_vpc" "emonstack_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name = "emonstack_vpc"
  }
}

# create public subnet
resource "aws_subnet" "emonstack_vpc_public_subnet" {
  vpc_id                  = aws_vpc.emonstack_vpc.id
  cidr_block              = var.subnet_one_cidr
  availability_zone       = data.aws_availability_zones.availability_zones.names[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "emonstack_vpc_public_subnet"
  }
}
# create private subnet one
resource "aws_subnet" "emonstack_vpc_private_subnet_one" {
  vpc_id            = aws_vpc.emonstack_vpc.id
  cidr_block        = element(var.subnet_two_cidr, 0)
  availability_zone = data.aws_availability_zones.availability_zones.names[0]
  tags = {
    Name = "emonstack_vpc_private_subnet_one"
  }
}
# create private subnet two
resource "aws_subnet" "emonstack_vpc_private_subnet_two" {
  vpc_id            = aws_vpc.emonstack_vpc.id
  cidr_block        = element(var.subnet_two_cidr, 1)
  availability_zone = data.aws_availability_zones.availability_zones.names[1]
  tags = {
    Name = "emonstack_vpc_private_subnet_two"
  }
}
# create internet gateway
resource "aws_internet_gateway" "emonstack_vpc_internet_gateway" {
  vpc_id = aws_vpc.emonstack_vpc.id
  tags = {
    Name = "emonstack_vpc_internet_gateway"
  }
}

# create public route table (assosiated with internet gateway)
resource "aws_route_table" "emonstack_vpc_public_subnet_route_table" {
  vpc_id = aws_vpc.emonstack_vpc.id
  route {
    cidr_block = var.route_table_cidr
    gateway_id = aws_internet_gateway.emonstack_vpc_internet_gateway.id
  }
  tags = {
    Name = "emonstack_vpc_public_subnet_route_table"
  }

}

# create private subnet route table
resource "aws_route_table" "emonstack_vpc_private_subnet_route_table" {
  vpc_id = aws_vpc.emonstack_vpc.id
  tags = {
    Name = "emonstack_vpc_private_subnet_route_table"
  }
}
# create default route table
resource "aws_default_route_table" "emonstack_vpc_main_route_table" {
  default_route_table_id = aws_vpc.emonstack_vpc.default_route_table_id
  tags = {
    Name = "emonstack_vpc_main_route_table"
  }
}
# assosiate public subnet with public route table
resource "aws_route_table_association" "emonstack_vpc_public_subnet_route_table" {
  subnet_id      = aws_subnet.emonstack_vpc_public_subnet.id
  route_table_id = aws_route_table.emonstack_vpc_public_subnet_route_table.id
}
# assosiate private subnets with private route table
resource "aws_route_table_association" "emonstack_vpc_private_subnet_one_route_table_assosiation" {
  subnet_id      = aws_subnet.emonstack_vpc_private_subnet_one.id
  route_table_id = aws_route_table.emonstack_vpc_private_subnet_route_table.id
}
resource "aws_route_table_association" "emonstack_vpc_private_subnet_two_route_table_assosiation" {
  subnet_id      = aws_subnet.emonstack_vpc_private_subnet_two.id
  route_table_id = aws_route_table.emonstack_vpc_private_subnet_route_table.id
}

