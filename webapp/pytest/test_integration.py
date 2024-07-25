import sys
import os
import requests
from dotenv import load_dotenv
from flask_sqlalchemy import SQLAlchemy
sys.path.insert(1, os.path.join(sys.path[0], '..'))
from app import app, db
from flask_testing import TestCase
import base64
import database

load_dotenv()
CREATE_URL = "http://localhost:5000/v1/user"
GET_URL = "http://localhost:5000/v1/user/self"
PUT_URL = "http://localhost:5000/v1/user/self"

app.config['SQLALCHEMY_DATABASE_URI'] = f'mysql://{os.getenv("DB_USER")}:{os.getenv("DB_PASSWORD")}@localhost/USER'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
#db=SQLAlchemy(app)

with app.app_context():
    db.create_all()


def generate_base64_str(username, password):
    return base64.b64encode(bytes(f"{username}:{password}", "utf-8")).decode("utf-8")


class BaseTestCase(TestCase):
    def create_app(self):
        #app.app.config['TESTING'] = True
        return app

class IntegrationTest(BaseTestCase):
    def test_create_user(self):
        first_name = "Peter"
        last_name = "Villa"
        password = "password"
        username = "Peter.Villa@example.com"
        request_data = {
            "first_name": first_name,
            "last_name": last_name,
            "password": password,
            "username": username
        }

        headers = {"Content-Type": "application/json"}
        response = self.client.post(CREATE_URL, json=request_data, headers=headers)
        self.assertEqual(response.status_code, 201)
        response_data = response.json
        assert "id" in response_data
        assert ("first_name" in response_data and response_data["first_name"] == "Peter")
        assert ("last_name" in response_data and response_data["last_name"] == "Villa")
        assert ("username" in response_data and response_data["username"] == "Peter.Villa@example.com")
        assert ("account_created" in response_data)
        assert ("account_updated" in response_data)
        assert ("password" not in response_data)

        # Make a GET API call to fetch the user details
        encode_credentials = generate_base64_str(username, password)
        headers = {"Authorization": f"Basic {encode_credentials}"}
        response = self.client.get(GET_URL, headers=headers)
        response_data = response.json
        self.assert200(response)
        assert "id" in response_data
        assert ("first_name" in response_data and response_data["first_name"] == "Peter")
        assert ("last_name" in response_data and response_data["last_name"] == "Villa")
        assert ("username" in response_data and response_data["username"] == "Peter.Villa@example.com")
        assert ("account_created" in response_data)
        assert ("account_updated" in response_data)
        assert ("password" not in response_data)

    def test_update_user(self):
        first_name = "Peter_Update_First_Name"
        last_name = "Villa"
        password = "password"
        username = "Peter.Villa@example.com"
        request_data = {
            "first_name": first_name,
            "last_name": last_name,
            "password": password
        }

        encode_credentials = generate_base64_str(username, password)
        headers = {"Content-Type": "application/json",
                   "Authorization": f"Basic {encode_credentials}"}
        
        response = self.client.put(PUT_URL, json=request_data, headers=headers)

        self.assertEqual(response.status_code, 204)
        response_data = response.text
        assert response_data == ''

        # Make a GET API call to fetch the user details
        
        headers = {"Authorization": f"Basic {encode_credentials}"}
        response = self.client.get(GET_URL, headers=headers)
        self.assert200(response)
        response_data = response.json
        assert "id" in response_data
        assert ("first_name" in response_data and response_data["first_name"] == "Peter_Update_First_Name")
        assert ("last_name" in response_data and response_data["last_name"] == "Villa")
        assert ("username" in response_data and response_data["username"] == "Peter.Villa@example.com")
        assert ("account_created" in response_data)
        assert ("account_updated" in response_data)
        assert ("password" not in response_data)