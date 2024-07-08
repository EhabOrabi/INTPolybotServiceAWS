terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.0"
    }
  }

  backend "s3" {
    bucket = "ehabo-tf-state-files "
    key    = "path/to/my/key"
    region = "eu-west-3"
  }

  required_version = ">= 1.7.0"
}

provider "aws" {
  region  = var.region
}

module "app_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "ehabo-PolybotServiceVPC-tf"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-3a", "eu-west-3b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]

  enable_nat_gateway = false

  tags = {
    Name        = "ehabo-PolybotServiceVPC-tf"
    Env         = var.env
    Terraform   = true
  }
}

resource "aws_security_group" "polybotService_sg" {
  name        = "polybot-service-app-server-sg"
  description = "Allow SSH and HTTP traffic"
  vpc_id      = module.app_vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Internet Gateway
resource "aws_internet_gateway" "app_igw" {
  vpc_id = module.app_vpc.vpc_id

  tags = {
    Name = "app-igw"
  }
}

# Route Table
resource "aws_route_table" "public_route_table" {
  vpc_id = module.app_vpc.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app_igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Route Table Association for Public Subnets
resource "aws_route_table_association" "public_subnet_assoc_1" {
  subnet_id      = module.app_vpc.public_subnets[0]
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_assoc_2" {
  subnet_id      = module.app_vpc.public_subnets[1]
  route_table_id = aws_route_table.public_route_table.id
}
