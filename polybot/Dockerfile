FROM python:3.10-alpine
WORKDIR /usr/src/app
COPY requirements.txt .
RUN pip install --upgrade pip
RUN pip install -r requirements.txt

COPY . .
ENV TELEGRAM_APP_URL="https://ehabo-polybot.int-devops.click"
CMD ["python3", "app.py"]



