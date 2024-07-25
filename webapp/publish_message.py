import os
from dotenv import load_dotenv
from concurrent import futures
from google.cloud import pubsub_v1
from typing import Callable
import json
import app_logging



logger = app_logging.app_log

load_dotenv()

project_id = os.getenv("PROJECT_ID", "dev-gcp-project-414721")
topic_id = os.getenv("TOPIC_ID", "verify_email")

publisher = pubsub_v1.PublisherClient()
topic_path = publisher.topic_path(project_id, topic_id)
publish_futures = []

def get_callback(publish_future):
    def callback(publish_future):
        try:
            logger.info(publish_future.result(timeout=60))
        except futures.TimeoutError:
            logger.error(f"Publishing timed out.")
    return callback


def send_verification_email(email_id, first_name, unique_id):
    logger.debug("Received request to send verification email")
    message_schema = {
        "email_id": email_id,
        "first_name": first_name,
        "unique_id": unique_id
    }
    message_data = json.dumps(message_schema)
    message_data = message_data.encode("utf-8")
    publish_future = publisher.publish(topic_path, message_data)
    publish_future.add_done_callback(get_callback(publish_future))
    publish_futures.append(publish_future)
    futures.wait(publish_futures, return_when=futures.ALL_COMPLETED)
    logger.info(f"Published messages with error handler to {topic_path}.")