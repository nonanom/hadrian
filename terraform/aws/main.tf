provider "aws" {
  region = var.AWS_DEFAULT_REGION
}

data "aws_caller_identity" "current" {}

locals {
  account_id  = data.aws_caller_identity.current.account_id
  bucket_name = "tf-${local.account_id}-${var.PROJECT_NAME}"
}

terraform {
  backend "s3" {
    bucket = local.bucket_name
    key    = "tfstate"
    region = "us-east-1"
  }
}

variable "PROJECT_NAME" {
  description = "Project name to be used in resource naming"
  type        = string
}

variable "AWS_DEFAULT_REGION" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}