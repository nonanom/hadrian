provider "aws" {
  region = var.AWS_DEFAULT_REGION
}

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

terraform {
  backend "s3" {
    bucket = "tf-${local.account_id}"
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

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] 

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "etl_instance" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.etl_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y docker.io docker-compose
              systemctl start docker
              systemctl enable docker
              EOF

  tags = {
    Name = "${var.PROJECT_NAME} ETL Instance"
  }
}

resource "aws_security_group" "etl_sg" {
  name        = "${var.PROJECT_NAME}-etl-sg"
  description = "Security group for ETL instance"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.PROJECT_NAME} ETL Security Group"
  }
}

resource "aws_db_instance" "ml_data_rds" {
  identifier           = "${var.PROJECT_NAME}-ml-data-rds"
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "14.10"
  instance_class       = "db.t3.micro"
  db_name              = "mlopsdb"
  username             = "${var.DB_USERNAME}"
  password             = "${var.DB_PASSWORD}"
  skip_final_snapshot  = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  tags = {
    Name = "${var.PROJECT_NAME} MLOps RDS"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "${var.PROJECT_NAME}-rds-sg"
  description = "Security group for RDS instance"

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.etl_sg.id]
  }

  tags = {
    Name = "${var.PROJECT_NAME} RDS Security Group"
  }
}

resource "aws_cloudwatch_log_group" "etl_logs" {
  name = "/aws/ec2/${aws_instance.etl_instance.id}/logs"

  retention_in_days = 30

  tags = {
    Name = "${var.PROJECT_NAME} ETL Logs"
  }
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../../app/src/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "etl_trigger" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.PROJECT_NAME}-etl-trigger"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.8"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      EC2_INSTANCE_ID = aws_instance.etl_instance.id
      S3_BUCKET_NAME  = aws_s3_bucket.ml_data_bucket.id
      DB_HOST         = aws_db_instance.ml_data_rds.endpoint
      DB_NAME         = aws_db_instance.ml_data_rds.db_name
      DB_USERNAME     = var.DB_USERNAME
      DB_PASSWORD     = var.DB_PASSWORD
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name = "${var.PROJECT_NAME}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_ec2_policy" {
  name = "lambda_ec2_policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:StartInstances",
          "ssm:SendCommand"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.etl_trigger.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.ml_data_bucket.arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.ml_data_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.etl_trigger.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_function.etl_trigger, aws_lambda_permission.allow_s3_invoke]
}

variable "PROJECT_NAME" {
  description = "Project name to be used in resource naming"
  type        = string
}

variable "DB_PASSWORD" {
  description = "Password for the RDS PostgreSQL instance"
  type        = string
  sensitive   = true
}

variable "DB_USERNAME" {
  description = "Username for the RDS PostgreSQL instance"
  type        = string
  sensitive   = true
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

output "ec2_instance_id" {
  value       = aws_instance.etl_instance.id
  description = "The ID of the EC2 instance for running ETL jobs"
}

output "rds_endpoint" {
  value       = aws_db_instance.ml_data_rds.endpoint
  description = "The connection endpoint for the RDS instance"
}
