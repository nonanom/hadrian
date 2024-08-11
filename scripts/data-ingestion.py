import os
import sys
import boto3

def upload_to_s3(file_name, bucket, object_name):
    """Upload a file to an S3 bucket"""
    s3_client = boto3.client('s3')
    try:
        s3_client.upload_file(file_name, bucket, object_name)
        return True
    except Exception as e:
        print(f"Error uploading file to S3: {e}")
        return False

def main():
    # Get environment variables
    project_name = os.environ.get('TF_VAR_PROJECT_NAME')
    
    if not project_name:
        raise ValueError("PROJECT_NAME environment variable is not set")

    # Construct the bucket name
    bucket_name = f"{project_name}-hadrian-ml-data-bucket"

    # CSV file path and S3 object name
    csv_file = 'data/data.csv'
    object_name = 'data.csv'  # Same name in S3

    # Check if the CSV file exists locally
    if not os.path.exists(csv_file):
        print(f"Error: {csv_file} not found in the current directory")
        sys.exit(1)

    # Upload the CSV file
    upload_success = upload_to_s3(csv_file, bucket_name, object_name)
    
    if upload_success:
        print(f"Successfully uploaded {csv_file} to {bucket_name}")
    else:
        print(f"Failed to upload {csv_file}")
        sys.exit(1)

if __name__ == "__main__":
    main()