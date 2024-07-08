resource "aws_launch_template" "yolo5_launch_template" {
  name_prefix   = "yolo5-launch-template"
  image_id      = var.instance_ami
  instance_type = var.instance_type

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name      = "ehabo-yolo5-tf"
      Terraform = "true"
    }
  }
}

resource "aws_autoscaling_group" "yolo5_asg" {
  launch_template {
    id      = aws_launch_template.yolo5_launch_template.id
    version = "$Latest"
  }

  vpc_zone_identifier = var.public_subnet_cidrs
  desired_capacity    = var.desired_capacity
  min_size            = var.min_size
  max_size            = var.max_size

  tag {
    key                 = "Name"
    value               = "ehabo-yolo5-tf"
    propagate_at_launch = true
  }
}

output "yolo5_instance_ids" {
  value = flatten([for instance in aws_autoscaling_group.yolo5_asg.instances : instance.id])
}
