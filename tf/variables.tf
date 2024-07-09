variable "region" {
  description = "AWS region"
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_azs" {
  description = "availability zones"
  default = ""
}

variable "availability_zone" {
  description = "availability zones"
  default = ""
}



variable "public_subnet_cidrs" {
  default = ""
}


variable "instance_ami_polybot" {
  description = "instance ami for the polybot"
  default = ""
}

variable "instance_type_polybot" {
  description = "instance type for the polybot"
  default = ""
}

variable "key_pair_name" {
  description = "EC2 Key Pair"
  default = ""
}