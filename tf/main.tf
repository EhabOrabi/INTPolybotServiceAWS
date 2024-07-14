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

# S3 Bucket
resource "aws_s3_bucket" "polybot_bucket" {
  bucket = "ehaborabi-bucket-tf"

  tags = {
    Name      = "ehaborabi-bucket-tf"
    Terraform = "true"
  }
}

module "polybot" {
  source            = "./modules/polybot"
  vpc_id            = module.app_vpc.vpc_id
  public_subnet_cidrs = module.app_vpc.public_subnets
  instance_ami_polybot = var.instance_ami_polybot
  instance_type_polybot = var.instance_type_polybot
  key_pair_name_polybot = var.key_pair_name_polybot
  iam_role_name         = var.iam_role_name_polybot
  TF_VAR_certificate_arn   = var.TF_VAR_certificate_arn
}

module "yolo5" {
  source = "./modules/yolo5"

  instance_ami_yolo5     = var.instance_ami_yolo5
  instance_type_yolo5    = var.instance_type_yolo5
  key_pair_name_yolo5    = var.key_pair_name_yolo5
  vpc_id                 = module.app_vpc.vpc_id
  public_subnet_ids      = module.app_vpc.public_subnets
  asg_min_size           = 1
  asg_max_size           = 2
  asg_desired_capacity   = 1
}
