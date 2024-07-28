#!/bin/sh

# Source the get_current_region.sh script to set the environment variable
. /usr/src/app/get_current_region.sh

# Construct the SQS_QUEUE_URL dynamically
export SQS_QUEUE_URL="https://sqs.$REGION_NAME.amazonaws.com/019273956931/ehabo-PolybotServiceQueue-tf"
export BUCKET_NAME="ehaborabi-bucket-$REGION-tf"
export TELEGRAM_APP_URL="https://ehabo-polybot-$REGION.int-devops.click"

# Print the region and SQS_QUEUE_URL to verify
echo "Using region: $REGION_NAME"
echo "SQS Queue URL: $SQS_QUEUE_URL"
echo "Bucket Name: $BUCKET_NAME"
echo "Telegram App Url: $TELEGRAM_APP_URL"

# Start the application
exec python3 app.py