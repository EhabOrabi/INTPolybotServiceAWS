variable "vpc_id" {
  description = "The ID of the VPC where the security group should be created."
}
variable "public_subnet_cidrs" {
  description = "List of public subnet CIDRs."
  type        = list(string)
}

variable "instance_ami_polybot" {
  description = "AMI ID for the instance."
  type        = string
}

variable "instance_type_polybot" {
  description = "Instance type for the instance."
  type        = string
}

variable "key_pair_name_polybot" {
  description = "Key pair name for SSH access."
  type        = string
}

variable "iam_role_name" {
  description = "IAM Role name for the instance"
  type = string
  default = "ehabo-role-tf"
}

variable "certificate_arn" {
  default = ""
  type        = string
}
# Route 53 Records
variable "domain_name" {
  description = "domain name for the route 53"
  type        = string
  default = "ehabo-polybot4.int-devops.click"
}

