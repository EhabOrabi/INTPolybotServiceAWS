

resource "aws_instance" "app_server_1" {
  ami           = "ami-09d83d8d719da9808"
  instance_type = "t2.micro"
  subnet_id     = module.app_vpc.public_subnets[0]
  security_groups = [aws_security_group.polybotService_sg.id]


  tags = {
    Name       = "ehabo-PolybotService1-polybot-tf"
    Terraform  = "true"
  }
}

resource "aws_instance" "app_server_2" {
  ami           = "ami-09d83d8d719da9808"
  instance_type = "t2.micro"
  subnet_id     = module.app_vpc.public_subnets[1]
  security_groups = [aws_security_group.polybotService_sg.id]

  tags = {
    Name       = "ehabo-PolybotService2-polybot-tf"
    Terraform  = "true"
  }
}

