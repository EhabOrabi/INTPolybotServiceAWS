import json
import os
from loguru import logger
import boto3
import flask
from botocore.exceptions import ClientError
from flask import request
from bot import ObjectDetectionBot

app = flask.Flask(__name__)

dynamodb = boto3.resource('dynamodb', region_name='eu-west-3')
table = dynamodb.Table('ehabo-PolybotService-DynamoDB')


# TODO load TELEGRAM_TOKEN value from Secret Manager


def get_secret():
    secret_name = "TELEGRAM_BOT_TOKEN"
    region_name = "eu-west-3"

    # Create a Secrets Manager client
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
    except ClientError as e:
        # For a list of exceptions thrown, see
        # https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_GetSecretValue.html
        raise e

    secret = get_secret_value_response['SecretString']
    return secret


secret_json_str = get_secret()
if secret_json_str:
    secret_dict = json.loads(secret_json_str)
    TELEGRAM_TOKEN = secret_dict.get('TELEGRAM_BOT_TOKEN')
else:
    print("Failed to retrieve the secret")

TELEGRAM_APP_URL = os.environ['TELEGRAM_APP_URL']


@app.route('/health_check', methods=['GET'])
def health_checks():
    return 'Ok', 200


@app.route('/', methods=['GET'])
def index():
    return 'Ok'


@app.route(f'/{TELEGRAM_TOKEN}/', methods=['POST'])
def webhook():
    req = request.get_json()
    bot.handle_message(req['message'])
    return 'Ok'


@app.route(f'/results', methods=['POST'])
def results():
    # TODO use the prediction_id to retrieve results from DynamoDB and send to the end-user

    logger.info("Received request at /results endpoint")
    try:
        prediction_id = flask.request.args.get('predictionId')
        if not prediction_id:
            prediction_id = flask.request.json.get('predictionId')

        if not prediction_id:
            return 'predictionId is required', 400

        response = table.get_item(Key={'prediction_id': prediction_id})
        if 'Item' in response:
            item = response['Item']
            chat_id = item['chat_id']
            labels = item['labels']
            unique_filename = item['unique_filename']

            text_results = f"Prediction results for image {item['original_img_path']}:\n"
            for label in labels:
                text_results += f"- {label['class']} at ({label['cx']:.2f}, {label['cy']:.2f}) with size ({label['width']:.2f}, {label['height']:.2f})\n"

            bot.send_text(chat_id, text_results)

            return 'Ok'
        else:
            return 'No results found', 404
    except Exception as e:
        print(f"Error processing results: {str(e)}")
        return 'Error', 500


@app.route(f'/loadTest/', methods=['POST'])
def load_test():
    req = request.get_json()
    bot.handle_message(req['message'])
    return 'Ok'


if __name__ == "__main__":
    bot = ObjectDetectionBot(TELEGRAM_TOKEN, TELEGRAM_APP_URL)
    app.run(host='0.0.0.0', port=8443)
