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
output "s3_bucket_name" {
  value       = aws_s3_bucket.ml_data_bucket.id
  description = "The name of the S3 bucket for MLOps data storage"
}
