import json
import os
import urllib.parse

import boto3
from datetime import datetime

dynamodb = boto3.resource("dynamodb")
rekognition = boto3.client("rekognition")
sns = boto3.client("sns")

# עדכון שם ברירת המחדל ל-ImageMetadata-v2
TABLE_NAME = os.environ.get("TABLE_NAME", "ImageMetadata-v2")
SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN")
table = dynamodb.Table(TABLE_NAME)


def lambda_handler(event, context):
    # 1. API Gateway GET /images request
    if "requestContext" in event and "http" in event["requestContext"]:
        response = table.scan()
        items = response.get("Items", [])

        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            },
            "body": json.dumps(items),
        }

    # 2. S3 Bucket Object Created Trigger
    for record in event.get("Records", []):
        bucket_name = record["s3"]["bucket"]["name"]
        raw_key = record["s3"]["object"]["key"]
        file_name = urllib.parse.unquote_plus(raw_key)

        upload_time = str(datetime.now())

        # AI Label Detection via Rekognition
        response = rekognition.detect_labels(
            Image={"S3Object": {"Bucket": bucket_name, "Name": file_name}},
            MaxLabels=5,
            MinConfidence=70,
        )
        labels = [label["Name"] for label in response.get("Labels", [])]

        # Save metadata to DynamoDB
        table.put_item(
            Item={
                "ImageID": file_name,
                "BucketName": bucket_name,
                "UploadTimestamp": upload_time,
                "DetectedLabels": labels,
                "Status": "Analyzed",
            }
        )

        # Send alert via SNS if topic ARN is configured
        if SNS_TOPIC_ARN:
            sns.publish(
                TopicArn=SNS_TOPIC_ARN,
                Subject=f"AI Alert: Image Analyzed ({file_name})",
                Message=f"📸 File: {file_name}\nLabels: {', '.join(labels)}",
            )

    return {
        "statusCode": 200,
        "body": json.dumps("S3 Event Processed Successfully!"),
    }
