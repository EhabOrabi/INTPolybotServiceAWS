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


module "polybot" {
  source            = "./modules/polybot"
  vpc_id            = module.app_vpc.vpc_id
  public_subnet_cidrs = module.app_vpc.public_subnets
  instance_ami_polybot = var.instance_ami_polybot
  instance_type_polybot = var.instance_type_polybot
  key_pair_name_polybot = var.key_pair_name_polybot
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
  lb_target_group_arn    = aws_lb_target_group.yolo5_tg.arn
}

resource "aws_lb" "yolo5_alb" {
  name               = "yolo5-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.yolo5_alb_sg.id]
  subnets            = module.app_vpc.public_subnets

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "yolo5_tg" {
  name     = "yolo5-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = module.app_vpc.vpc_id

  health_check {
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
}

resource "aws_security_group" "yolo5_alb_sg" {
  name        = "yolo5-alb-sg"
  description = "Allow HTTP traffic"
  vpc_id      = module.app_vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
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


