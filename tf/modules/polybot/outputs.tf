
output "polybot_instance_ids" {
  value = aws_instance.polybot_instance[*].id
}
