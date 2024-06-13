import json
import time
import uuid
from pathlib import Path
import requests
from detect import run
import yaml
from loguru import logger
import os
import boto3

images_bucket = os.environ['BUCKET_NAME']
queue_name = os.environ['SQS_QUEUE_NAME']

sqs_client = boto3.client('sqs', region_name='YOUR_REGION_HERE')

with open("data/coco128.yaml", "r") as stream:
    names = yaml.safe_load(stream)['names']


def consume():
    # The function runs in an infinite loop, continually polling the SQS queue for new messages.
    while True:
        # Receive Message from SQS
        response = sqs_client.receive_message(QueueUrl=queue_name, MaxNumberOfMessages=1, WaitTimeSeconds=5)
        # Check for Messages:
        if 'Messages' in response:
            # Extract message details
            message_body = response['Messages'][0]['Body']
            receipt_handle = response['Messages'][0]['ReceiptHandle']
            # Parses the message body from JSON format to a Python dictionary and retrieves the message ID
            message = json.loads(message_body)
            prediction_id = response['Messages'][0]['MessageId']
            logger.info(f'Prediction: {prediction_id}. Start processing')
            # Retrieve Chat ID and Image Name
            chat_id = message.get('chat_id')
            img_name = message.get('imgName')
            if not img_name or not chat_id:
                logger.error('Invalid message format: chat_id or imgName missing')
                sqs_client.delete_message(QueueUrl=queue_name, ReceiptHandle=receipt_handle)
                continue

            logger.info(f'img_name received: {img_name}')
            photo_s3_name = img_name.split("/")
            file_path_pic_download = os.path.join(os.getcwd(), photo_s3_name[1])
            logger.info(f'Download path: {file_path_pic_download}')
            # Download Image from S3
            s3_client = boto3.client('s3')
            s3_client.download_file(images_bucket, photo_s3_name[1], file_path_pic_download)

            original_img_path = file_path_pic_download
            logger.info(f'Prediction: {prediction_id}/{original_img_path}. Download img completed')
            # Run YOLOv5 Object Detection
            # Predicts the objects in the image
            run(
                weights='yolov5s.pt',
                data='data/coco128.yaml',
                source=original_img_path,
                project='static/data',
                name=prediction_id,
                save_txt=True
            )

            logger.info(f'Prediction: {prediction_id}/{original_img_path}. done')

            # Path for the predicted image with labels
            predicted_img_path = Path(f'static/data/{prediction_id}/{photo_s3_name[1]}')
            predicted_img_path.parent.mkdir(parents=True, exist_ok=True)

            # Upload predicted image to S3
            unique_filename = str(uuid.uuid4()) + '.jpeg'
            s3_client.upload_file(str(predicted_img_path), images_bucket, unique_filename)

            # Parse prediction labels and create a summary
            pred_summary_path = Path(f'static/data/{prediction_id}/labels/{photo_s3_name[1].split(".")[0]}.txt')
            if pred_summary_path.exists():
                with open(pred_summary_path) as f:
                    labels = f.read().splitlines()
                    labels = [line.split(' ') for line in labels]
                    labels = [{
                        'class': names[int(l[0])],
                        'cx': float(l[1]),
                        'cy': float(l[2]),
                        'width': float(l[3]),
                        'height': float(l[4]),
                    } for l in labels]
                    logger.info(f'Prediction: {prediction_id}/{photo_s3_name[1]}. prediction summary:\n\n{labels}')
                    prediction_summary = {
                        'prediction_id': prediction_id,
                        'original_img_path': photo_s3_name[1],
                        'predicted_img_path': unique_filename,
                        'labels': labels,
                        'time': time.time()
                    }

                    # Store the prediction_summary in a DynamoDB table
                    dynamodb = boto3.resource('dynamodb', region_name='eu-west-3')
                    table = dynamodb.Table('ehabo-PolybotService-DynamoDB')
                    table.put_item(Item=prediction_summary)

                    # Notify Polybot of Results
                    polybot_url = 'http://polybot-url/results'
                    response = requests.get(polybot_url, params={
                        'predictionId': json.dumps({'chat_id': chat_id, 'prediction_id': prediction_id})})
                    if response.status_code == 200:
                        logger.info('GET request to Polybot /results endpoint successful')
                    else:
                        logger.error(
                            f'Error: GET request to Polybot /results endpoint failed with status code {response.status_code}')
            else:
                logger.error(f'Prediction: {prediction_id}/{original_img_path}. prediction result not found')
                sqs_client.delete_message(QueueUrl=queue_name, ReceiptHandle=receipt_handle)
                continue

            # Delete the message from the queue as the job is considered as DONE
            sqs_client.delete_message(QueueUrl=queue_name, ReceiptHandle=receipt_handle)


if __name__ == "__main__":
    consume()
