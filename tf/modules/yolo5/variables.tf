variable "instance_ami" {
  description = "AMI ID for the instance"
  type        = string
}

variable "instance_type" {
  description = "Instance type for the instance"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
}

variable "desired_capacity" {
  description = "Desired number of instances in the auto-scaling group"
  type        = number
}

variable "min_size" {
  description = "Minimum number of instances in the auto-scaling group"
  type        = number
}

variable "max_size" {
  description = "Maximum number of instances in the auto-scaling group"
  type        = number
}
