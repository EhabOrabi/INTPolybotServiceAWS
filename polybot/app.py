import flask
from flask import request
import os
from bot import Bot, ObjectDetectionBot

app = flask.Flask(__name__)

dynamodb = boto3.resource('ehabo-PolybotService-DynamoDB', region_name='eu-west-3')
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
    return json.loads(secret)


TELEGRAM_TOKEN = get_secret()  # need to get the value by get method from json
TELEGRAM_APP_URL = "https://ehabo-PolybotService-lb-1648832162.eu-west-3.elb.amazonaws.com"


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
