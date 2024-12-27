import os
import json
import logging
import urllib.parse
import urllib.request
import boto3
from botocore.client import Config
from botocore.exceptions import ClientError

logger = logging.getLogger()
region = os.environ['AWS_REGION']

s3 = boto3.client(
    's3',
    region_name=region,
    # config=Config(signature_version='s3v4')
    config=Config(signature_version='s3v4',s3={'addressing_style': 'virtual'})
)

def lambda_handler(event, context):
    try:
        bucket = event['Records'][0]['s3']['bucket']['name']
        key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'], encoding='utf-8')
        url = s3.generate_presigned_url(
            ClientMethod = 'get_object',
            Params = {'Bucket' : bucket, 'Key' : key},
            ExpiresIn = 3600,
            HttpMethod = 'GET'
        )
        logger.info("Got presigned URL: %s", url)
    except ClientError:
        logger.exception(
            "Couldn't get a presigned URL."
        )
        raise
    return url