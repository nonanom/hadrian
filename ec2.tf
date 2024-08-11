# Add a data block to fetch the latest Ubuntu AMI as of August 2024
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical's AWS Account ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# Create a security group for the EC2 instance
resource "aws_security_group" "ec2_sg" {
  name_prefix = "${var.PROJECT_NAME}-ec2-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["107.197.174.39/32"]  # mikevincent's home IP
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["107.197.174.39/32"]  # mikevincent's home IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.PROJECT_NAME} EC2 Security Group"
  }
}

# Create the EC2 instance with the latest Ubuntu AMI and SSH key authentication
resource "aws_instance" "web" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = "t3.micro"
  security_groups = [aws_security_group.ec2_sg.name]

  user_data = <<-EOF
              #!/bin/bash
              exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
              echo "Starting user data script execution"

              apt-get update -y
              apt-get install -y docker.io docker-compose

              echo "Setting up SSH key"
              mkdir -p /home/ubuntu/.ssh
              echo "${var.EC2_PUBLIC_KEY}" >> /home/ubuntu/.ssh/authorized_keys
              chown -R ubuntu:ubuntu /home/ubuntu/.ssh
              chmod 700 /home/ubuntu/.ssh
              chmod 600 /home/ubuntu/.ssh/authorized_keys

              echo "Starting Docker"
              systemctl start docker
              systemctl enable docker

              echo "User data script completed"
              EOF

  tags = {
    Name = "${var.PROJECT_NAME} EC2 Instance"
  }

  monitoring           = true
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  depends_on = [aws_s3_bucket.ml_data_bucket]
}

# Create a CloudWatch log group for the EC2 instance logs
resource "aws_cloudwatch_log_group" "ec2_log_group" {
  name = "/ec2/${var.PROJECT_NAME}/logs"
}

# Create a CloudWatch log stream for the EC2 instance
resource "aws_cloudwatch_log_stream" "ec2_log_stream" {
  name           = "ec2-instance-log-stream"
  log_group_name = aws_cloudwatch_log_group.ec2_log_group.name
}

# Create a CloudWatch log resource policy
resource "aws_iam_role" "ec2_cloudwatch_agent_role" {
  name = "${var.PROJECT_NAME}-cloudwatch-agent-role"

  assume_role_policy = <<EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Principal": {
            "Service": "ec2.amazonaws.com"
          },
          "Effect": "Allow",
          "Sid": ""
        }
      ]
    }
  EOF
}

# Attach the CloudWatch log policy to the EC2 instance role
resource "aws_iam_role_policy_attachment" "ec2_cloudwatch_logs" {
  role       = aws_iam_role.ec2_cloudwatch_agent_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Create an instance profile to associate the IAM role with the EC2 instance
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.PROJECT_NAME}-ec2-instance-profile"
  role = aws_iam_role.ec2_cloudwatch_agent_role.name
}

variable "EC2_PUBLIC_KEY" {
  description = "EC2 public key"
  type        = string
  sensitive   = true
}

output "ec2_instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.web.public_ip
}

output "ssh_connection_string" {
  description = "SSH connection string to connect to the EC2 instance"
  value       = "ssh -i ~/.ssh/id_rsa ubuntu@${aws_instance.web.public_ip}"
}