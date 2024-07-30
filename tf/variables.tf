variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zone" {
  description = "availability zones"
  default = ""
}

variable "dynamodb_table_name" {
  description = "The name of the DynamoDB table"
  type        = string
  default     = "polybot_predictions"
}


variable "public_subnets" {
  description = "Public Subnet for PolyBot instances"
  type    = list(string)
  default = ["10.0.101.0/24", "10.0.102.0/24"]
}


variable "instance_ami_polybot" {
  description = "instance ami for the polybot"
  default = ""
}

variable "instance_type_polybot" {
  description = "instance type for the polybot"
  default = ""
}

variable "key_pair_name_polybot" {
  description = "EC2 Key Pair for polybot Paris"
  default = ""
}

# S3 Bucket
variable "bucket_name" {
  description = "S3 Bucket"
  type = string
}

variable "my_queue" {
  description = "polybot queue"
  type = string
}

variable "instance_ami_yolo5" {
  description = "instance ami for the yolo5"
  type = string
  default = ""
}

variable "instance_type_yolo5" {
  description = "instance type for the yolo5"
  type = string
  default = ""
}

variable "key_pair_name_yolo5" {
  description = "EC2 Key Pair for yolo5 Paris"
  type = string
  default = ""
}

variable "certificate_arn" {
  description = "The ARN of the ACM certificate for HTTPS"
  type        = string
}

variable "cpu_utilization_high_threshold" {
  default = ""
}
variable "cpu_utilization_low_threshold" {
  default = ""
}
variable "scale_out_cooldown" {
  default = ""
}
variable "scale_in_cooldown" {
  default = ""
}

