output "yolo5_asg_name" {
  description = "The name of the Auto Scaling Group"
  value       = aws_autoscaling_group.ehabo_yolo5_asg_tf
}

output "yolo5_lt_id" {
  description = "The ID of the launch template"
  value       = aws_launch_template.ehabo_yolo5_lt-tf
}
