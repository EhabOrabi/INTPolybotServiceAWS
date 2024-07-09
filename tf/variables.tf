variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-3"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}


variable "min_size" {
  description = "Minimum number of instances in the auto-scaling group"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances in the auto-scaling group"
  type        = number
  default     = 2
}
