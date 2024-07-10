# Launch Template
resource "aws_launch_template" "ehabo_yolo5_lt-tf" {
  name_prefix   = "ehabo-yolo5-lt-tf"
  image_id      = var.instance_ami_yolo5
  instance_type = var.instance_type_yolo5

  key_name = var.key_pair_name_yolo5

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ehabo_yolo5_sg_tf.id]
  }

  lifecycle {
    create_before_destroy = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "yolo5-instance-tf"
    }
  }
   user_data = base64encode(file("${path.module}/user_data.sh"))
}
# Security Group for the instances
resource "aws_security_group" "ehabo_yolo5_sg_tf" {
  name        = "ehabo_yolo5_sg-tf"
  description = "Security group for YOLO5 instances"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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

  tags = {
    Name = "ehabo-yolo5-sg-tf"
  }
}



# Auto Scaling Group
resource "aws_autoscaling_group" "ehabo_yolo5_asg_tf" {
  desired_capacity     = var.asg_desired_capacity
  max_size             = var.asg_max_size
  min_size             = var.asg_min_size
  launch_template {
    id      = aws_launch_template.ehabo_yolo5_lt-tf.id
    version = "$Latest"
  }
  vpc_zone_identifier = var.public_subnet_ids

  tag {
    key                 = "Name"
    value               = "ehabo-yolo5-instance-tf"
    propagate_at_launch = true
  }

  health_check_type         = "EC2"
  health_check_grace_period = 300

  force_delete = true
}