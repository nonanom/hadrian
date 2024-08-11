import os
import boto3
import psycopg2
import csv
from io import StringIO

# AWS and database connection details
PROJECT_NAME = os.environ.get('TF_VAR_PROJECT_NAME')
S3_BUCKET_NAME = f"{PROJECT_NAME}-hadrian-ml-data-bucket"
RDS_DB_NAME = 'mydb'
RDS_ENDPOINT = os.environ.get('RDS_ENDPOINT')
RDS_USERNAME = os.environ.get('DB_USERNAME')
RDS_PASSWORD = os.environ.get('DB_PASSWORD')

def download_from_s3(bucket_name, file_key):
    s3 = boto3.client('s3')
    response = s3.get_object(Bucket=bucket_name, Key=file_key)
    return response['Body'].read().decode('utf-8')

def process_data(data):
    # Simple transformation: Capitalize the city names
    reader = csv.DictReader(StringIO(data))
    processed_data = []
    for row in reader:
        row['city'] = row['city'].upper()
        processed_data.append(row)
    return processed_data

def upload_to_rds(data):
    conn = psycopg2.connect(
        host=RDS_ENDPOINT.split(':')[0],  # Extract hostname from endpoint
        port=5432,
        dbname=RDS_DB_NAME,
        user=RDS_USERNAME,
        password=RDS_PASSWORD
    )
    cur = conn.cursor()
    
    # Create table if it doesn't exist
    cur.execute("""
    CREATE TABLE IF NOT EXISTS processed_data (
        id INTEGER PRIMARY KEY,
        name VARCHAR(100),
        age INTEGER,
        city VARCHAR(100)
    )
    """)
    
    # Insert data
    for row in data:
        cur.execute("""
        INSERT INTO processed_data (id, name, age, city)
        VALUES (%s, %s, %s, %s)
        ON CONFLICT (id) DO UPDATE
        SET name = EXCLUDED.name, age = EXCLUDED.age, city = EXCLUDED.city
        """, (row['id'], row['name'], row['age'], row['city']))
    
    conn.commit()
    cur.close()
    conn.close()

def main():
    # Extract
    raw_data = download_from_s3(S3_BUCKET_NAME, 'data.csv')
    
    # Transform
    processed_data = process_data(raw_data)
    
    # Load
    upload_to_rds(processed_data)
    
    print("ETL job completed successfully!")

if __name__ == "__main__":
    main()