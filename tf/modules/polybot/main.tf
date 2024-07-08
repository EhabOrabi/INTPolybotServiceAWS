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

output "polybot_instance_ids" {
  value = aws_instance.polybot_instance[*].id
}
