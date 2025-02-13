# Hadrian Infrastructure

## Overview

This repository helps you build a scalable and secure data platform on AWS to support machine learning operations (MLOps). As part of an engineering team, you’ll find all the necessary tools here to create and manage a platform that includes:

- An S3 bucket for data storage
- An EC2 instance for running ETL jobs
- An RDS instance for storing processed data
- A CI/CD pipeline using GitHub Actions to automate infrastructure setup, data processing, and deployment tasks
- Monitoring and logging for all components

### Key Workflows

1. **Create AWS Infrastructure**:
   - **Workflow File**: `create-all-the-aws-infrastructure.yml`
   - **What It Does**: Sets up all the AWS resources needed for the platform: S3 bucket, EC2 instance, and RDS database.
   - **How to Use**:
     1. Trigger this workflow manually via GitHub Actions.
     2. It provisions the AWS resources.
     3. After running, add the `RDS_ENDPOINT` and `EC2_PUBLIC_DNS` values to your GitHub repository from the Terraform output.

2. **Upload Data to S3**:
   - **Workflow File**: `upload-data-csv-to-the-s3-bucket.yml`
   - **What It Does**: Uploads `data.csv` to the S3 bucket for later processing. This workflow runs a Python script directly on the GitHub Actions runner to upload the data to S3.
   - **How to Use**:
     1. Place your `data.csv` file in the `data/` directory.
     2. Trigger this workflow manually via GitHub Actions. The workflow will execute a Python script that uploads the data to the S3 bucket.

3. **Run ETL Job**:
   - **Workflow File**: `run-etl-job-on-the-ec2-instance.yml`
   - **What It Does**: Runs an ETL job on the EC2 instance. The workflow securely connects to the EC2 instance, copies the etl-job.py script via SCP, and runs it directly on the instance. The script downloads data from S3, processes it, and uploads the results to the RDS database.
   - **How to Use**:
     1. Edit `etl-job.py` in the `scripts/` directory to define your data processing steps.
     2. Trigger this workflow manually via GitHub Actions. The workflow will copy the Python script to the EC2 instance, run it, and handle the data processing tasks.

4. **Teardown AWS Resources**:
   - **Workflow File**: `teardown-everything-on-aws.yml`
   - **What It Does**: Removes all AWS resources created for the platform.
   - **How to Use**:
     1. Trigger this workflow manually via GitHub Actions to clean up your environment.

## Infrastructure Setup

The Terraform configuration in this repository builds a complete AWS platform:

### EC2 Instance

- **OS**: Latest Ubuntu 20.04
- **Instance Type**: `t3.micro`
- **Security**: Configured to allow SSH (port 22) and HTTP (powrt 80) access.
- **User Data**: Installs Docker, sets up SSH, and configures CloudWatch logging.

### RDS (PostgreSQL)

- **Version**: PostgreSQL 13
- **Instance Type**: `db.t3.micro`
- **Security**: Configured to allow access only from the EC2 instance.

### S3 Bucket

- **Name**: `<PROJECT_NAME>-hadrian-ml-data-bucket`
- **Versioning**: Enabled to keep track of object versions.

## Setting Up GitHub Secrets and Variables

Add these to your GitHub repository to configure the platform:

### AWS Setup

| **Name**               | **Type**  | **Required** | **Description**                                                                 |
|------------------------|-----------|--------------|---------------------------------------------------------------------------------|
| `AWS_ACCESS_KEY_ID`     | Secret    | Yes          | Your AWS Access Key ID. |
| `AWS_SECRET_ACCESS_KEY` | Secret    | Yes          | Your AWS Secret Access Key. |
| `AWS_DEFAULT_REGION`    | Variable  | Yes          | AWS region for resources (e.g., `us-east-1`).|

### RDS Setup

| **Name**          | **Type**  | **Required** | **Description**                        |
|-------------------|-----------|--------------|----------------------------------------|
| `DB_USERNAME`     | Variable  | Yes          | Database username. |
| `DB_PASSWORD`     | Secret    | Yes          | Database password. |

### EC2 Setup

| **Name**          | **Type**  | **Required** | **Description**                        |
|-------------------|-----------|--------------|----------------------------------------|
| `EC2_PUBLIC_KEY`  | Variable  | Yes          | Public SSH key for the EC2 instance. |
| `EC2_PRIVATE_KEY` | Secret    | Yes          | Private SSH key for the EC2 instance. |

### Project Tagging

| **Name**          | **Type**  | **Required** | **Description**                        |
|-------------------|-----------|--------------|----------------------------------------|
| `PROJECT_NAME`    | Variable  | Yes          | Name to tag and identify project resources. |

### Post-Setup Configuration

After you create the infrastructure using the `create-all-the-aws-infrastructure.yml` workflow, add the following variables to your GitHub repository:

| **Name**          | **Type**  | **Required** | **Description**                        |
|-------------------|-----------|--------------|----------------------------------------|
| `RDS_ENDPOINT`    | Variable  | Yes          | Enter the endpoint for the RDS instance. This value will be generated by the Terraform output when you run the infrastructure setup workflow. |
| `EC2_PUBLIC_DNS`  | Variable  | Yes          | Enter the public DNS for the EC2 instance. This value will also be generated by the Terraform output after running the infrastructure setup workflow. |
