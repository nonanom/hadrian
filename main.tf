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

resource "aws_s3_bucket" "ml_data_bucket" {
  bucket = "${var.PROJECT_NAME}-hadrian-ml-data-bucket"

  tags = {
    Name = "${var.PROJECT_NAME} MLOps S3 Bucket"
  }
}

resource "aws_s3_bucket_versioning" "ml_data_bucket_versioning" {
  bucket = aws_s3_bucket.ml_data_bucket.id

  versioning_configuration {
    status = "Enabled"
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

output "s3_bucket_name" {
  value       = aws_s3_bucket.ml_data_bucket.id
  description = "The name of the S3 bucket for MLOps data storage"
}
