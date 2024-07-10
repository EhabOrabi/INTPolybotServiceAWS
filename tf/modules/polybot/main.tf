resource "aws_instance" "polybot_instance1" {
  ami           = var.instance_ami_polybot
  instance_type = var.instance_type_polybot
  key_name = var.key_pair_name_polybot
  subnet_id     = var.public_subnet_cidrs[0]
  security_groups = [aws_security_group.polybot_sg.id]
  associate_public_ip_address = true
  tags = {
    Name      = "ehabo-PolybotService1-polybot-tf"
    Terraform = "true"
  }
}

resource "aws_instance" "polybot_instance2" {
  ami           = var.instance_ami_polybot
  instance_type = var.instance_type_polybot
  key_name = var.key_pair_name_polybot
  subnet_id     = var.public_subnet_cidrs[1]
  security_groups = [aws_security_group.polybot_sg.id]
  associate_public_ip_address = true
  tags = {
    Name      = "ehabo-PolybotService2-polybot-tf"
    Terraform = "true"
  }
}

resource "aws_security_group" "polybot_sg" {
  name        = "ehabo-polybot-service-app-server-sg-tf"
  description = "Allow SSH and HTTP traffic"
  vpc_id      = var.vpc_id # Use the VPC ID variable passed from the main configuration

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

resource "aws_lb" "polybot_alb" {
  name               = "ehabo-polybot-alb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.polybot_sg.id]
  subnets            = var.public_subnet_cidrs

  tags = {
    Name      = "ehabo-polybot-alb-tf"
    Terraform = "true"
  }
}

resource "aws_lb_target_group" "polybot_tg" {
  name        = "ehabo-polybot-target-group-tf"
  port        = 8080  // Example port where Polybot instances listen
  protocol    = "HTTP"
  vpc_id      = var.vpc_id

  health_check {
    path                = "/healthcheck"  // Example health check path
    interval            = 30
    timeout             = 10
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Name      = "ehabo-polybot-target-group-tf"
    Terraform = "true"
  }
}

resource "aws_lb_listener" "polybot_listener" {
  load_balancer_arn = aws_lb.polybot_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.polybot_tg.arn
  }
}

