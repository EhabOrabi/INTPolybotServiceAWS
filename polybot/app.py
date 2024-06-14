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
logger.info(TELEGRAM_APP_URL)


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

    prediction_id = request.args.get('predictionId')
    # Extract chat_id from prediction_id (assuming prediction_id is JSON string)
    try:
        prediction_data = json.loads(prediction_id)
        chat_id = prediction_data.get("chat_id")
        if not chat_id:
            return 'Invalid chat_id', 400
    except json.JSONDecodeError:
        return 'Invalid predictionId format', 400

    # Retrieve results from DynamoDB
    try:
        response = table.get_item(Key={'predictionId': prediction_id})
        item = response.get('Item')
        if not item:
            return 'No results found for the given predictionId', 404

        text_results = item.get('results')  # Replace 'results' with the actual attribute name
        if not text_results:
            return 'No results found in the item', 404
    except Exception as e:
        return f'Error retrieving results: {str(e)}', 500

    # Send results to the end-user
    bot.send_text(chat_id, text_results)
    return 'Ok'


@app.route(f'/loadTest/', methods=['POST'])
def load_test():
    req = request.get_json()
    bot.handle_message(req['message'])
    return 'Ok'


if __name__ == "__main__":
    bot = ObjectDetectionBot(TELEGRAM_TOKEN, TELEGRAM_APP_URL)

    app.run(host='0.0.0.0', port=8443)
