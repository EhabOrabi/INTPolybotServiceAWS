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
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  tags = {
    Name      = "ehabo-PolybotServiceVPC-tf"
    Terraform = "true"
    Environment = "dev"
  }
}


