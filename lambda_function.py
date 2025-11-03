import json
import boto3
import os
from datetime import datetime

s3_client = boto3.client('s3')

def lambda_handler(event, context):
    """
    Lambda function triggered by SQS messages.
    Creates a file in S3 with the name from the message body.
    """
    bucket_name = os.environ['S3_BUCKET']

    for record in event['Records']:
        try:
            # Get message body
            message_body = record['body']

            # Parse if it's JSON, otherwise use as-is
            try:
                message_data = json.loads(message_body)
                file_name = message_data.get('filename', message_body)
            except json.JSONDecodeError:
                file_name = message_body

            # Clean filename (remove invalid characters)
            file_name = file_name.strip().replace('/', '-').replace('\\', '-')

            # Add timestamp to make it unique
            timestamp = datetime.utcnow().strftime('%Y%m%d-%H%M%S')
            s3_key = f"{file_name}-{timestamp}.txt"

            # Create file content
            file_content = {
                'message': message_body,
                'timestamp': timestamp,
                'message_id': record['messageId']
            }

            # Upload to S3
            s3_client.put_object(
                Bucket=bucket_name,
                Key=s3_key,
                Body=json.dumps(file_content, indent=2),
                ContentType='application/json'
            )

            print(f"Successfully created file: {s3_key} in bucket: {bucket_name}")

        except Exception as e:
            print(f"Error processing message: {str(e)}")
            raise e

    return {
        'statusCode': 200,
        'body': json.dumps('Files created successfully')
    }
