resource "aws_launch_template" "yolo5" {
  name_prefix   = "ehabo-PolybotService-LaunchTemplate-yolo5-tf"
  image_id      = var.instance_ami_yolo5
  instance_type = var.instance_type_yolo5
  key_name      = var.key_pair_name_yolo5

  network_interfaces {
    associate_public_ip_address = true
    subnet_id                   = element(var.public_subnet_ids, 0)
    security_groups             = [aws_security_group.yolo5_sg.id]
  }

  lifecycle {
    create_before_destroy = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name      = "yolo5-instance"
      Terraform = "true"
    }
  }

  user_data = base64encode(file("${path.module}/user_data.sh"))
}

resource "aws_security_group" "yolo5_sg" {
  name        = "yolo5-service-app-server-sg"
  description = "Allow SSH and HTTP traffic"
  vpc_id      = var.vpc_id

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

resource "aws_autoscaling_group" "yolo5_asg" {
  desired_capacity     = var.asg_desired_capacity
  max_size             = var.asg_max_size
  min_size             = var.asg_min_size
  vpc_zone_identifier  = var.public_subnet_ids
  launch_template {
    id      = aws_launch_template.yolo5.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "ehabo-PolybotService-LaunchTemplate-yolo5-tf"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.yolo5_asg.name
  lb_target_group_arn    = var.lb_target_group_arn
}

resource "aws_autoscaling_policy" "scale_up_policy" {
  name                   = "scale-up-policy"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.yolo5_asg.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 60.0  // Scale up if CPU utilization exceeds 60%
  }
}

resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  alarm_name          = "scale-up-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120  // 2 minutes
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Alarm if CPU exceeds 70% for 2 consecutive periods."
  alarm_actions       = [aws_autoscaling_policy.scale_up_policy.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.yolo5_asg.name
  }
}

