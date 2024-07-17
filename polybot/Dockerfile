FROM python:3.10-alpine
WORKDIR /usr/src/app
COPY requirements.txt .
RUN pip install --upgrade pip
RUN pip install -r requirements.txt

COPY . .
ENV TELEGRAM_APP_URL="https://ehabo-polybot5.int-devops.click"
ENV BUCKET_NAME="ehaborabi-bucket-tf"
ENV REGION_NAME="eu-west-3"
ENV SQS_QUEUE_NAME="ehabo-PolybotServiceQueue-tf"
ENV SQS_QUEUE_URL="https://sqs.eu-west-3.amazonaws.com/019273956931/ehabo-PolybotServiceQueue-tf"
CMD ["python3", "app.py"]
