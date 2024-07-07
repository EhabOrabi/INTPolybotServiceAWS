terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.0"
    }
  }

  backend "s3" {
    bucket = "ehabo-tf-state-files "
    key    = "path/to/my/key"
    region = "eu-west-3"
  }

  required_version = ">= 1.7.0"
}

provider "aws" {
  region  = var.region
}