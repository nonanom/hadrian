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
  engine_version    = "13"  # Using a stable, but not the latest version
  instance_class    = "db.t3.micro"  # Cheapest instance class
  allocated_storage = 20  # Minimum storage in GB

  db_name  = "mydb"
  username = var.DB_USERNAME
  password = var.DB_PASSWORD

  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  # Disable features to reduce costs
  backup_retention_period = 0
  skip_final_snapshot     = true
  multi_az                = false
  publicly_accessible     = false

  # Disable performance insights
  performance_insights_enabled = false

  # Disable encryption (Note: not recommended for real-world scenarios)
  storage_encrypted = false

  # Disable automated backups
  backup_window = "00:00-00:00"

  # Disable maintenance window
  maintenance_window = "Sun:00:00-Sun:00:00"

  # Disable deletion protection for easy cleanup
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