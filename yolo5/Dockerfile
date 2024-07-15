FROM ultralytics/yolov5:latest-cpu
WORKDIR /usr/src/app
RUN pip install --upgrade pip
COPY requirements.txt .
RUN pip install -r requirements.txt
RUN curl -L https://github.com/ultralytics/yolov5/releases/download/v6.1/yolov5s.pt -o yolov5s.pt

ENV BUCKET_NAME="ehaborabi-bucket"
ENV REGION_NAME="eu-west-3"
ENV SQS_QUEUE_NAME="ehabo-PolybotService-Queue-tf"
COPY . .

CMD ["python3", "app.py"]
