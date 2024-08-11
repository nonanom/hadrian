import os
import boto3
from datetime import datetime

def upload_to_s3(file_name, bucket, object_name=None):
    """Upload a file to an S3 bucket"""
    if object_name is None:
        object_name = file_name
    s3_client = boto3.client('s3')
    try:
        s3_client.upload_file(file_name, bucket, object_name)
    except Exception as e:
        print(f"Error uploading file to S3: {e}")
        return False
    return True

def main():
    # Get environment variables
    project_name = os.environ.get('TF_VAR_PROJECT_NAME')
    if not project_name:
        raise ValueError("PROJECT_NAME environment variable is not set")

    # Construct the bucket name
    bucket_name = f"{project_name}-hadrian-ml-data-bucket"

    # CSV file path
    csv_file = 'data.csv'

    # Check if the CSV file exists
    if not os.path.exists(csv_file):
        print(f"Error: {csv_file} not found in the current directory")
        return

    # Create a unique filename for the upload
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    object_name = f"data_{timestamp}.csv"
    
    # Upload the CSV file
    upload_success = upload_to_s3(csv_file, bucket_name, object_name)
    
    if upload_success:
        print(f"Successfully uploaded {csv_file} to {bucket_name} as {object_name}")
    else:
        print(f"Failed to upload {csv_file}")

if __name__ == "__main__":
    main()