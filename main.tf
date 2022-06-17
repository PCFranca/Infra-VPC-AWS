provider "aws" {
  region = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "vpc_pedro" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_subnet" "public_subnet_a" {
  vpc_id     = aws_vpc.vpc_pedro.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id = aws_vpc.vpc_pedro.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_subnet" "private_subnet_a" {
  vpc_id     = aws_vpc.vpc_pedro.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id = aws_vpc.vpc_pedro.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_db_instance" "bancopedro" {
  allocated_storage = 10
  engine = "mysql"
  engine_version = "5.7"
  instance_class = "db.t2.micro"
  db_name = "bancopedro"
  username = "admin"
  password = "12qwaszx"
  skip_final_snapshot = true
  db_subnet_group_name = aws_db_subnet_group.db_subnet.id
}

resource "aws_db_subnet_group" "db_subnet" {
  name = "dbsubnet"
  subnet_ids = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
}

resource "aws_instance" "webserver" {
  ami = "ami-0022f774911c1d690"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public_subnet_a.id
}

resource "aws_eip" "nat" {
  vpc = true

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_pedro.id
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat.id
  subnet_id = aws_subnet.private_subnet_a.id

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "router" {
  vpc_id = aws_vpc.vpc_pedro.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gw.id
  }
  
}

resource "aws_route_table_association" "assoc" {
  subnet_id = aws_subnet.private_subnet_a.id
  route_table_id = aws_route_table.router.id
}