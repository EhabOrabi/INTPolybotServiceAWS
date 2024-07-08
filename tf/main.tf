provider "aws" {
  region = var.region
}

module "app_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "ehabo-PolybotServiceVPC-tf"
  cidr = var.vpc_cidr

  azs             = var.azs
  public_subnets  = var.public_subnet_cidrs

  enable_nat_gateway = false

  tags = {
    Name        = "ehabo-PolybotServiceVPC-tf"
    Env         = var.env
    Terraform   = true
  }
}

resource "aws_security_group" "polybot_sg" {
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

module "polybot" {
  source         = "./modules/polybot"
  instance_ami   = var.instance_ami
  instance_type  = var.instance_type
  public_subnet_cidrs = []
}

module "yolo5" {
  source            = "./modules/yolo5"
  instance_ami      = var.instance_ami
  instance_type     = var.instance_type
  desired_capacity  = var.desired_capacity
  min_size          = var.min_size
  max_size          = var.max_size
  public_subnet_cidrs = []
}

resource "aws_security_group" "lb_sg" {
  name        = "lb-sg"
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

resource "aws_lb" "app_lb" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = module.app_vpc.public_subnets

  enable_deletion_protection = false

  tags = {
    Name = "app-lb"
  }
}

resource "aws_lb_target_group" "app_tg" {
  name     = "app-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = module.app_vpc.vpc_id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    protocol            = "HTTP"
    matcher             = "200"
  }

  tags = {
    Name = "app-tg"
  }
}

resource "aws_lb_target_group_attachment" "polybot_attachment_1" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = module.polybot.polybot_instance_ids[0]
  port             = 8080
}

resource "aws_lb_target_group_attachment" "polybot_attachment_2" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = module.polybot.polybot_instance_ids[1]
  port             = 8080
}

resource "aws_lb_target_group_attachment" "yolo5_attachment" {
  for_each = toset(module.yolo5.yolo5_instance_ids)
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = each.value
  port             = 8080
}

resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}
