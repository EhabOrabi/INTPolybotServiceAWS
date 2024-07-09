resource "aws_instance" "polybot_instance1" {
  ami           = var.instance_ami_polybot
  instance_type = var.instance_type_polybot
  key_name = var.key_pair_name
  subnet_id     = var.public_subnet_cidrs[0]
  security_groups = [aws_security_group.polybot_sg.id]

  tags = {
    Name      = "ehabo-PolybotService1-polybot-tf"
    Terraform = "true"
  }
}

resource "aws_instance" "polybot_instance2" {
  ami           = var.instance_ami_polybot
  instance_type = var.instance_type_polybot
  key_name = var.key_pair_name
  subnet_id     = var.public_subnet_cidrs[1]
  security_groups = [aws_security_group.polybot_sg.id]

  tags = {
    Name      = "ehabo-PolybotService2-polybot-tf"
    Terraform = "true"
  }
}

resource "aws_security_group" "polybot_sg" {
  name        = "polybot-service-app-server-sg"
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