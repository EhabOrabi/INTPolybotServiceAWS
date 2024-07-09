resource "aws_instance" "polybot_instance" {
  count         = 2
  ami           = var.instance_ami
  instance_type = var.instance_type
  subnet_id     = element(var.public_subnet_cidrs, count.index % length(var.public_subnet_cidrs))
  security_groups = [aws_security_group.polybot_sg.id]

  tags = {
    Name       = "ehabo-polybot-tf"
    Terraform  = "true"
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
