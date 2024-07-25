import requests
import os
import base64
import json
from datetime import datetime, timedelta
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from flask_sqlalchemy import SQLAlchemy
import functions_framework


db = SQLAlchemy()

class EmailVerification(db.Model):
    uuid = db.Column(db.String(36), primary_key=True)
    url = db.Column(db.String(3600), nullable=False)
    expiration_time = db.Column(db.DateTime, nullable=False)


def insert_into_email_verification(uuid, url, expiration_time):
   
    db_user = os.environ.get('DB_USER')
    db_password = os.environ.get('DB_PASSWORD')
    db_url = os.environ.get('DB_URL')
    db_port = os.environ.get('DB_PORT')

    engine = create_engine(f'mysql://{db_user}:{db_password}@{db_url}:{db_port}/USER')
    Session = sessionmaker(bind=engine)
    session = Session()

    
    new_record = EmailVerification(uuid=uuid, url=url, expiration_time=expiration_time)
    session.add(new_record)
    session.commit()
    session.close()

def verify_mail_delivery(domain_name, auth, message_id):
    url = f"https://api.mailgun.net/v3/{domain_name}/events?message-id={message_id}"
    response = requests.get(url, auth=auth)
    if response.status_code != 200:
        return False, "Failed to send email"
    
    res = response.json()
    data = res['items']
    if data == []:
        return True, "Email sent successfully"
    

    return False, "Email couldnt be sent"


@functions_framework.cloud_event
def send_verification_email(cloud_event):
   
    data = base64.b64decode(cloud_event.data["message"]["data"]).decode()
    data = json.loads(data)
    email_id = data["email_id"]
    first_name = data["first_name"]
    unique_id = data["unique_id"]

    domain_name = os.getenv('DOMAIN_NAME')
    application_port = os.getenv('APPLICATION_PORT')
  
    verification_url = f"https://{domain_name}/v1/verify_email?uuid={unique_id}"

    email_from = f"Excited User <mailgun@{domain_name}>"
    email_to = [email_id]
    subject = "Hello, verify your email"
    expiration_time = datetime.utcnow() + timedelta(minutes=2) 
    email_text = f"Hello {first_name},\n\nPlease verify your email by clicking on the following link: {verification_url}.\n\nThis link will expire in 2 minutes ({expiration_time.strftime('%Y-%m-%d %H:%M:%S UTC')}).\n\nRegards,\nYour App Team"

   
    url = f"https://api.mailgun.net/v3/{domain_name}/messages"
    auth = ("api", "fe83fc0e16f08adfd978245fbef7ee41-f68a26c9-2b18a0f0")
    data = {
        "from": email_from,
        "to": email_to,
        "subject": subject,
        "text": email_text
    }
    response = requests.post(url, auth=auth, data=data)

    if response.status_code != 200:
        raise Exception(f"Unable to send email. Err: {response.text}")

    message_id = response.json()['id'][1:-1]
    status, msg = verify_mail_delivery(domain_name, auth, message_id)
    if not status:
        raise Exception(msg)

    insert_into_email_verification(unique_id, verification_url, expiration_time)

    
    
    return response


