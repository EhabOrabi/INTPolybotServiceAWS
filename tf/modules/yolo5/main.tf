# Launch Template

resource "aws_launch_template" "ehabo_yolo5_lt-tf" {
  name_prefix   = "ehabo-yolo5-lt-tf"
  image_id      = var.instance_ami_yolo5
  instance_type = var.instance_type_yolo5

  key_name = var.key_pair_name_yolo5

  iam_instance_profile {
    name = aws_iam_instance_profile.yolo5_instance_profile.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.yolo5_sg.id]
  }

  lifecycle {
    create_before_destroy = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "ehabo-yolo5-instance-tf"
    }
  }
   user_data = base64encode(file("${path.module}/user_data.sh"))
}
# Security Group for the instances
resource "aws_security_group" "yolo5_sg" {
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


resource "aws_autoscaling_policy" "scale_out" {
  name                   = "yolo5-scale-out"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = var.scale_out_cooldown
  autoscaling_group_name = aws_autoscaling_group.yolo5_asg.name
}


resource "aws_autoscaling_policy" "scale_in" {
  name                   = "yolo5-scale-in"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = var.scale_in_cooldown
  autoscaling_group_name = aws_autoscaling_group.yolo5_asg.name
}


resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "yolo5-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_utilization_high_threshold
  alarm_actions       = [aws_autoscaling_policy.scale_out.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.yolo5_asg.name
  }
}


resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "yolo5-low-cpu"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_utilization_low_threshold
  alarm_actions       = [aws_autoscaling_policy.scale_in.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.yolo5_asg.name
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "yolo5_asg" {
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

# Define DynamoDB table
resource "aws_dynamodb_table" "PolybotService-DynamoDB" {
  name           = "ehabo-PolybotService-DynamoDB-tf"
  billing_mode   = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "prediction_id"
  attribute {
    name = "prediction_id"
    type = "S"
  }

  tags = {
    Name = "ehabo-PolybotService-DynamoDB-tf"
  }
}

resource "aws_iam_role" "yolo5_role" {
  name = var.iam_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
    lifecycle {
    ignore_changes = [name]
  }
}

resource "aws_iam_role_policy_attachment" "dynamodb_policy" {
  role       = aws_iam_role.yolo5_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
    lifecycle {
    ignore_changes = [
      # Ignore policy ARN changes if it's updated externally
      policy_arn
    ]
  }
}

resource "aws_iam_role_policy_attachment" "s3_policy" {
  role       = aws_iam_role.yolo5_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
    lifecycle {
    ignore_changes = [
      # Ignore policy ARN changes if it's updated externally
      policy_arn
    ]
  }
}

resource "aws_iam_role_policy_attachment" "sqs_policy" {
  role       = aws_iam_role.yolo5_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
    lifecycle {
    ignore_changes = [
      # Ignore policy ARN changes if it's updated externally
      policy_arn
    ]
  }
}

resource "aws_iam_role_policy_attachment" "secretsmanager_policy" {
  role       = aws_iam_role.yolo5_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
    lifecycle {
    ignore_changes = [
      # Ignore policy ARN changes if it's updated externally
      policy_arn
    ]
  }
}


resource "aws_iam_instance_profile" "yolo5_instance_profile" {
  name = "yolo5-instance-profile1-${var.region}"
  role = aws_iam_role.yolo5_role.name
    lifecycle {
    ignore_changes = [role]
  }
}