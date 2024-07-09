terraform {
   required_providers {
   aws = {
      source  = "hashicorp/aws"
      version = "5.30.0"
    }
  }

  backend "s3" {
    bucket = "ehabo-tf-state-files"
    key    = "tfstate.json"
    region = "eu-west-3"
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.region
}

module "app_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "ehabo-PolybotServiceVPC-tf"
  cidr = "10.0.0.0/16"

  azs             = var.vpc_azs
  public_subnets  = var.public_subnets


  tags = {
    Name      = "ehabo-PolybotServiceVPC-tf"
    Terraform = "true"
    Environment = "dev"
  }
}

resource "aws_subnet" "public_subnets" {
  count             = length(var.public_subnets)
  vpc_id            = module.app_vpc.vpc_id
  cidr_block        = var.public_subnets[count.index]
  availability_zone = element(var.vpc_azs, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name      = "ehabo-PolybotServicePublicSubnet-${count.index + 1}"
    Environment = "dev"
  }

}

module "polybot" {
  source            = "./modules/polybot"
  vpc_id            = module.app_vpc.vpc_id  # Pass the VPC ID to the module
  public_subnet_cidrs = module.app_vpc.public_subnets
  instance_ami_polybot = var.instance_ami_polybot
  instance_type_polybot = var.instance_type_polybot
  key_pair_name = var.key_pair_name
}


