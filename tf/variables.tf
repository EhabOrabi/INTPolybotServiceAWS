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

variable "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "azs" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["eu-west-3a", "eu-west-3b"]
}

variable "instance_ami" {
  description = "AMI ID for the instances"
  type        = string
  default     = "ami-09d83d8d719da9808"
}

variable "instance_type" {
  description = "Instance type for the instances"
  type        = string
  default     = "t2.micro"
}

variable "env" {
  description = "Environment (e.g., dev, prod)"
  type        = string
  default     = "dev"
}

variable "desired_capacity" {
  description = "Desired number of instances in the auto-scaling group"
  type        = number
  default     = 1
}

variable "min_size" {
  description = "Minimum number of instances in the auto-scaling group"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances in the auto-scaling group"
  type        = number
  default     = 3
}
