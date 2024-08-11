# Create a security group for the RDS instance
resource "aws_security_group" "rds_sg" {
  name_prefix = "${var.PROJECT_NAME}-rds-sg"
  description = "Security group for RDS instance"

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.PROJECT_NAME} RDS Security Group"
  }
}

# Create the RDS instance
resource "aws_db_instance" "default" {
  identifier        = "${var.PROJECT_NAME}-db"
  engine            = "postgres"
  engine_version    = "13"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name  = "mydb"
  username = var.DB_USERNAME
  password = var.DB_PASSWORD

  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  backup_retention_period = 1
  backup_window           = "03:00-03:30"

  skip_final_snapshot     = true
  multi_az                = false
  publicly_accessible     = false

  performance_insights_enabled = false
  storage_encrypted           = false

  maintenance_window = "Sun:04:00-Sun:04:30"

  deletion_protection = false

  tags = {
    Name = "${var.PROJECT_NAME} RDS Instance"
  }
}

variable "DB_USERNAME" {
  description = "DB username"
  type        = string
  sensitive   = true
}

variable "DB_PASSWORD" {
  description = "DB password"
  type        = string
  sensitive   = true
}

# Output the RDS instance endpoint
output "rds_endpoint" {
  value       = aws_db_instance.default.endpoint
  description = "The connection endpoint for the RDS instance"
}

# Output the RDS instance port
output "rds_port" {
  value       = aws_db_instance.default.port
  description = "The port the RDS instance is listening on"
}