#-------------------------------------
# Configure the AWS Provider
#-------------------------------------
provider "aws" {
  region = "eu-central-1"
}

#-------------------------------------
# Create VPC and Subnets
#-------------------------------------

# Create a VPC
resource "aws_vpc" "My_VPC" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "My_VPC"
  }
}

# Create a Public Subnet
resource "aws_subnet" "Public" {
  vpc_id     = aws_vpc.My_VPC.id
  cidr_block = "10.0.10.0/24"
  map_public_ip_on_launch = "true"
  tags = {
    Name = "Public"
  }
}

# Create a Privat Subnet
resource "aws_subnet" "Privat" {
  vpc_id     = aws_vpc.My_VPC.id
  cidr_block = "10.0.20.0/24"
  map_public_ip_on_launch = "false"
  tags = {
    Name = "Privat"
  }
}

#-------------------------------------
# Creating securety groups
#-------------------------------------

# Creating securety groups for public subnet
resource "aws_security_group" "public_subnet" {
  name        = "public_subnet"
  description = "Allow ssh and http traffic"

  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "http"
    from_port           = 80
    to_port             = 80
    protocol            = "tcp"
    cidr_blocks    = ["0.0.0.0/0"]
  }    
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
 }

# Creating securety groups for privat subnet
resource "aws_security_group" "privat_subnet" {
  name        = "privat_subnet"
  description = "Allow all inbound traffic"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.10.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
 }

# Create internet gateway
resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.My_VPC.id

  tags = {
    Name = "IGW"
  }
}

# Creating route table for Public subnet
resource "aws_route_table" "route_table_public" {
    vpc_id = aws_vpc.My_VPC.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.IGW.id
    }
    tags = {
        Name       = "internet_gateway_public"
    }
}

#-------------------------------------
# Creating Elastic IP and NAT gatewey
#-------------------------------------

# Creating Elastic IP
resource "aws_eip" "aws_eip" {
    vpc         = true
    depends_on = [aws_internet_gateway.IGW]
}
# Create NAT-gateway
resource "aws_nat_gateway" "nat_gateway" {
    allocation_id = aws_eip.aws_eip.id
    subnet_id     = aws_subnet.Public.id
    depends_on    = [aws_internet_gateway.IGW]

tags = {
        Name       = "nat_gateway"
         }    
}

# Create private route table and the route to the internet
resource "aws_route_table" "route_table_privat" {
    vpc_id     = aws_vpc.My_VPC.id
    depends_on = [aws_nat_gateway.nat_gateway]
    route {
        cidr_block = "0.0.0.0/0"
#       gateway_id = aws_internet_gateway.IGW.id
        gateway_id = aws_nat_gateway.nat_gateway.id
    }
    tags = {
        Name       = "aws_internet_gateway_privat"
         }
}

#---------------------------------------------------
# Route Table Associations
#---------------------------------------------------

# private
resource "aws_route_table_association" "route_table_association_privat" {
    subnet_id       = aws_subnet.Privat.id
    route_table_id  = aws_route_table.route_table_privat.id
}
# public
resource "aws_route_table_association" "route_table_association_public" {
    subnet_id = aws_subnet.Public.id
    route_table_id = aws_route_table.route_table_public.id
#   route_table_id = aws_vpc.My_VPC.main_route_table_id
}
