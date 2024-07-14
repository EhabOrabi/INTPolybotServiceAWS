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
      Name = "ehabo-yolo5-instance-tf"
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

# Define DynamoDB table
resource "aws_dynamodb_table" "ehabo-PolybotService-DynamoDB" {
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
}

resource "aws_iam_role_policy_attachment" "dynamodb_policy" {
  role       = aws_iam_role.yolo5_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_role_policy_attachment" "s3_policy" {
  role       = aws_iam_role.yolo5_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "sqs_policy" {
  role       = aws_iam_role.yolo5_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}

resource "aws_iam_role_policy_attachment" "secretsmanager_policy" {
  role       = aws_iam_role.yolo5_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

resource "aws_iam_instance_profile" "yolo5_instance_profile" {
  name = "yolo5-instance-profile"
  role = aws_iam_role.yolo5_role.name
}