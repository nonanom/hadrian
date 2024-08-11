import boto3
import pandas as pd
from sqlalchemy import create_engine
import os

def get_latest_file(bucket_name):
    s3 = boto3.client('s3')
    objects = s3.list_objects_v2(Bucket=bucket_name)['Contents']
    latest = max(objects, key=lambda x: x['LastModified'])
    return latest['Key']

def main():
    # Get the latest file from S3
    s3 = boto3.client('s3')
    bucket_name = os.environ['S3_BUCKET_NAME']
    latest_file = get_latest_file(bucket_name)
    s3.download_file(bucket_name, latest_file, '/tmp/latest_data.csv')

    # Read and process the data
    df = pd.read_csv('/tmp/latest_data.csv')

    # Simple transformation: capitalize names
    df['name'] = df['name'].str.upper()

    # Connect to RDS and upload processed data
    db_host = os.environ['DB_HOST']
    db_name = os.environ['DB_NAME']
    db_user = "admin"  # Hardcoded as per request
    db_password = os.environ['DB_PASSWORD']

    engine = create_engine(f"postgresql://{db_user}:{db_password}@{db_host}:5432/{db_name}")
    df.to_sql('processed_data', engine, if_exists='replace', index=False)

    print(f"ETL process completed successfully for file: {latest_file}")

if __name__ == "__main__":
    main()