resource "aws_vpc" "vpc_master" {
  provider             = aws.region_master
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  tags = {
    Name = "master_vpc_jenkins"
  }
}

resource "aws_vpc" "vpc_worker" {
  provider             = aws.region_worker
  cidr_block           = "192.168.0.0/16"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  tags = {
    Name = "worker_vpc_jenkins"
  }
}

resource "aws_internet_gateway" "igw" {
  provider = aws.region_master
  vpc_id   = aws_vpc.vpc_master.id
}

resource "aws_internet_gateway" "igw_oregon" {
  provider = aws.region_worker
  vpc_id   = aws_vpc.vpc_worker.id
}

data "aws_availability_zones" "azs" {
  provider = aws.region_master
  state    = "available"
}

resource "aws_subnet" "subnet_1" {
  provider          = aws.region_master
  availability_zone = element(data.aws_availability_zones.azs.names, 0)
  vpc_id            = aws_vpc.vpc_master.id
  cidr_block        = "10.0.1.0/24"
}

resource "aws_subnet" "subnet_2" {
  provider          = aws.region_master
  availability_zone = element(data.aws_availability_zones.azs.names, 1)
  vpc_id            = aws_vpc.vpc_master.id
  cidr_block        = "10.0.2.0/24"
}

resource "aws_subnet" "subnet_1_oregon" {
  provider   = aws.region_worker
  vpc_id     = aws_vpc.vpc_worker.id
  cidr_block = "192.168.1.0/24"
}

resource "aws_vpc_peering_connection" "useast1_uswest2" {
  provider    = aws.region_master
  peer_vpc_id = aws_vpc.vpc_worker.id
  vpc_id      = aws_vpc.vpc_master.id
  peer_region = var.region_worker
}

resource "aws_vpc_peering_connection_accepter" "peering_accepter" {
  provider                  = aws.region_worker
  vpc_peering_connection_id = aws_vpc_peering_connection.useast1_uswest2.id
  auto_accept               = true
}

resource "aws_route_table" "internet_route" {
  provider = aws.region_master
  vpc_id   = aws_vpc.vpc_master.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  route {
    cidr_block                = "192.168.1.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.useast1_uswest2.id
  }
  lifecycle {
    ignore_changes = all
  }
  tags = {
    Name = "Master-Region-RT"
  }
}

resource "aws_main_route_table_association" "set_master_default_rt_association" {
  provider       = aws.region_master
  vpc_id         = aws_vpc.vpc_master.id
  route_table_id = aws_route_table.internet_route.id
}

resource "aws_route_table" "internet_route_oregon" {
  provider = aws.region_worker
  vpc_id   = aws_vpc.vpc_worker.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_oregon.id
  }
  route {
    cidr_block                = "10.0.1.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.useast1_uswest2.id
  }
  lifecycle {
    ignore_changes = all
  }
  tags = {
    Name = "Worker-Region-RT"
  }
}

resource "aws_main_route_table_association" "set_worker_default_rt_association" {
  provider       = aws.region_worker
  vpc_id         = aws_vpc.vpc_worker.id
  route_table_id = aws_route_table.internet_route_oregon.id
}