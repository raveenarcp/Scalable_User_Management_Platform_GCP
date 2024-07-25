from flask import Flask
from flask import request, Response, jsonify
from sqlalchemy import create_engine, exc ,text
from dotenv import load_dotenv
from flask_sqlalchemy import SQLAlchemy
from datetime import datetime
from flask_bcrypt import Bcrypt
import uuid
import base64
import re
import os
import traceback
load_dotenv()
import database
import app_logging
if not os.getenv("TEST_ENV", "False") == "True":
    from publish_message import send_verification_email 



logger = app_logging.app_log

try:
    database.start_db()
except Exception:
    logger.error(f'Failed to initialize database, exiting... Err: {traceback.format_exc()}')
    raise

app=Flask(__name__)

app.config['SQLALCHEMY_DATABASE_URI'] = f'mysql://{os.getenv("DB_USER")}:{os.getenv("DB_PASSWORD")}@{os.getenv("DB_URL")}/USER'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db=SQLAlchemy(app)

bcrypt=Bcrypt(app)

try:
    with app.app_context():
        db.create_all()
except Exception:
    logger.error(f'Failed to initialize database, exiting... Err: {traceback.format_exc()}')
    raise

class EmailVerification(db.Model):
    uuid = db.Column(db.String(36), primary_key=True)
    url = db.Column(db.String(3600), nullable=False)
    expiration_time = db.Column(db.DateTime, nullable=False)

HTTP_METHODS = ['GET', 'HEAD', 'POST', 'PUT', 'DELETE', 'CONNECT', 'OPTIONS', 'TRACE', 'PATCH']
class user_details(db.Model):
    id = db.Column(db.String(36), primary_key=True, default=str(uuid.uuid4()), unique=True, nullable=False)
    email = db.Column(db.String(120), nullable=False)
    passcode = db.Column(db.String(80), nullable=False)
    first_name = db.Column(db.String(50), nullable=False)
    last_name = db.Column(db.String(50), nullable=False)
    account_created=db.Column(db.DateTime, default=datetime.utcnow, nullable=True)
    account_updated=db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=True)  
    verified = db.Column(db.Boolean, default=False) 

    def toJson(self):
        data = {
            "id": self.id,
            "username": self.email,
            "first_name": self.first_name,
            "last_name": self.last_name,
            "account_created": self.account_created,
            "account_updated": self.account_updated
        }
        return jsonify(data)

# To Validate input Json
def validate_json(json_data):
    logger.debug("Validating the json data received")
    allowed_keys = set(['username', 'first_name', 'last_name', 'password', 'account_created', 'account_updated'])
    required_keys = set(['username', 'first_name', 'last_name', 'password'])

    if not required_keys.issubset(json_data.keys()):
        missing_keys = required_keys - json_data.keys()
        return {'message': f'Missing required keys: {missing_keys}'}, 400
    
    if not re.match(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$', json_data["username"]):
        return {'message': 'Invalid email format'}, 400

    
    extra_keys = set(json_data.keys()) - allowed_keys
    if extra_keys :
        return {'message': f'Extra keys present: {extra_keys}'}, 400
    
    return True , 200


# Response content
@app.after_request
def add_header(response):
    logger.debug("Adding no-cache in repsonse headers")
    response.headers['cache-control'] = 'no-cache' 
    return response



def verify_credentials(headers):
    logger.debug("Verifying credentials")
    if 'Authorization' not in headers:
        return {"message" : "No Authentication Given"}, 401, None
    try:
        token = headers['Authorization'].split()[1]
    except:
        return  {"message" :"Unable to fetch the authorization token"}, 401, None
    try:
        decoded_token = str(base64.b64decode(token).decode('utf-8'))
        email_id, password = decoded_token.split(":")
        if not email_id or not password:
            raise Exception
    except:
        return {"message" :"Unable to decode Authorization token"}, 401, None
    try:
        user = user_details.query.filter_by(email=email_id).first()
        if(user.verified == False):
            logger.error("Email not verified")
            return {"message":"Email not verified"}, 400, None
        if user:
            hashed_password = user.passcode 
            result = bcrypt.check_password_hash(hashed_password, password)
            if result:
                return {"message" :"Authentication Successful"}, 200, user
            else:
                return {"message" :"Invalid Credentials"}, 401, None
        else:
            return {"message" :"User not found"}, 401, None
    except:
        return {"message" :"Invalid credentials"}, 401, None


# Update
@app.route('/v1/user/self',methods=["PUT"])
def update_account_controller():
    logger.info("Received request to update user details")
    try:
        message, status_code, user = verify_credentials(request.headers)
        if status_code != 200:
            logger.error('Failed to update user account: %s', message)
            return message, status_code

        account = user_details.query.filter_by(email=user.email).first()
        if(account.verified == False):
            logger.error("Email not verified")
            return "Email not verified", 400

        json_data = request.get_json()
        allowed_keys = {'first_name', 'last_name', 'password', 'account_created' ,'account_updated'}
        extra_keys = set(json_data.keys()) - allowed_keys
        
        if 'password' in json_data and json_data['password'] is not None and json_data['password']!='':
            account.passcode = bcrypt.generate_password_hash(json_data.get('password')).decode('utf-8')
        elif 'password' in json_data:
            logger.error('Failed to update user account: Password is provided as null or an empty string')
            return jsonify({'message':'password is provided as null or is a empty string'}), 400


        if 'first_name' in json_data and json_data['first_name'] is not None and json_data['first_name']!='':
            account.first_name = json_data.get('first_name')
        elif 'first_name' in json_data:
            logger.error('Failed to update user account: first_name is provided as null or is a empty string')
            return jsonify({'message':'first_name is provided as null or is a empty string'}), 400
        
        if 'last_name' in json_data and json_data['last_name'] is not None and json_data['last_name']!='':
            account.last_name = json_data.get('last_name')
        elif 'last_name' in json_data:
            logger.error('Failed to update user account: last_name is provided as null or is a empty string')
            return jsonify({'message':'last_name is provided as null or is a empty string'}), 400
        
        
        if 'username' in json_data:
            logger.error('Failed to update user account: Username cannot be edited')
            return jsonify({'message':'Username cannot be edited'}), 400
        
        if extra_keys :
            logger.error('Failed to update user account: Extra keys present: %s', extra_keys)
            return jsonify({'message': f'Extra keys present {extra_keys}'}), 400
    
        db.session.commit()
        getUser = user_details.query.filter_by(email = user.email).first()
        logger.info('User account updated successfully')
        return '', 204
    except Exception:
        message = f'Failed to update user details. Err: {traceback.format_exc()}'
        logger.error(message)
        return jsonify({'message': message}), 500

# Add new user
@app.route('/v1/user',methods=["POST"])
def addUser():
    logger.info("Received request to add a user")
    resp=Response()
    try:
        message, status_code =validate_json(request.get_json())
        if status_code != 200:
            logger.error('Failed to add new user: %s', message)
            return jsonify(message), status_code
    
        request_data = request.get_json()
        emailid = request_data.get('username')
        password = request_data.get('password')
        hashed_password = bcrypt.generate_password_hash (password).decode('utf-8') 
        first_name = request_data.get('first_name')
        last_name = request_data.get('last_name')
        verified = False
        if(os.getenv("TEST_ENV", "False") == "True"):
            verified = True
        new_user = user_details(email=emailid, passcode=hashed_password, first_name=first_name, last_name=last_name,
                            id=str(uuid.uuid4()),verified=verified)
        user_set = user_details.query.all()
        for user in user_set:
            if user.email==new_user.email:
                logger.error('Failed to add new user: User with email %s already exists', new_user.email)
                resp.status_code = 400
                return resp
        
        db.session.add(new_user)
        db.session.commit()
        logger.info('New user added successfully')
        if not os.getenv("TEST_ENV", "False") == "True":
            send_verification_email(new_user.email, new_user.first_name, new_user.id)
        resp= (new_user.toJson())
        return resp, 201
    except Exception:
        message = f"Failed to add user. Err: {traceback.format_exc()}"
        logger.error(message)
        resp.status_code = 500
        return resp


# Retrieve user details
@app.route('/v1/user/self',methods=["GET"])
def get_user():
    logger.info("Received request to get user details")
    if request.get_data() or request.args:
        logger.error('Failed to get user details: Request cannot contain body')
        return jsonify({'message':'Request cannot contain body'}), 400
    message, status_code, user = verify_credentials(request.headers)
    
    if status_code != 200:
        #response = Response(message, status_code)
        # TODO : Check whether message should be populated
        logger.error('Failed to get user details: %s', message)
        return jsonify(message),status_code
    user_dict = user.toJson()
    logger.info('User details retrieved successfully')
    return user_dict, 200



@app.route('/v1/verify_email',methods=HTTP_METHODS)
def verify_email():
    resp = Response()
    if request.method!='GET':
        logger.error('Verify email failed: Method Not Allowed')
        resp.status_code = 405
        return resp
    
    if request.get_data() :
        logger.error('Verify email failed: Request contains data or arguments')
        resp.status_code = 400
        return resp
    logger.debug('Verification request recieved')
    try:
        # Get the UUID from the request
        verification_uuid = request.args.get('uuid')
        logger.debug('fetching data from database')
        getEmail = EmailVerification.query.filter_by(uuid = verification_uuid).first()
        user = user_details.query.filter_by(id=verification_uuid).first()
        
        if user:
            expiration_time = getEmail.expiration_time
            
            if datetime.utcnow()<=expiration_time:
                user.verified = True
                db.session.commit()
                logger.info('Email verified successfully!')

                return 'Email verified successfully!', 200
            else:
                logger.error('Verification link has expired')
                return 'Verification link has expired', 400
        else:
            logger.error('Invalid verification link')
            return 'Invalid verification link', 400
    except Exception as e:
        # Log the error
        logger.error(f'An unexpected error occurred: {e}')
        return 'An unexpected error occurred', 500 


def check_database_connection():
    logger.debug("Checking database connection")
    try:
        engine = create_engine(f'mysql+pymysql://{os.getenv("DB_USER")}:{os.getenv("DB_PASSWORD")}@{os.getenv("DB_URL")}/USER')
        with engine.connect() as connection:
            logger.info('Database connection successful')
            return True
    except exc.OperationalError as e:
        logger.error('Database connection failed: %s', e)
        return False


# By default we are allowing all the http methods but restricting API call to 
# only GET method inside the function. This is done because the default 405 
# method not allowed http reponse includes http code in the payload.  
# By restricting it inside the function, we are making sure that no payload is
# included in the response for any of the responses
@app.route('/healthz',methods=HTTP_METHODS)
def health_check():
    logger.info("Received request for health check")
    resp = Response()
    try:
        resp.headers['Cache-Control'] = 'no-cache , no-store , must-revalidate;'
        resp.headers['Pragma'] = 'no-cache'
        req_args = request.args

        if request.method!='GET':
            logger.error('Health check failed: Method Not Allowed')
            resp.status_code = 405
            return resp
        
        if request.get_data() or req_args:
            logger.error('Health check failed: Request contains data or arguments')
            resp.status_code = 400
            return resp
        
        if check_database_connection():
            logger.info('Health check successful: Database connection')
            resp.status_code = 200
            return  resp
        else:
            logger.error('Health check failed: Database connection error')
            resp.status_code = 503
            return resp
    except Exception:
        logger.error(f'Health check failed with exception: {traceback.format_exc()}')
        resp.status_code = 503
        return resp
        

@app.errorhandler(405)
def method_not_allowed(error):
    logger.error('Method Not Allowed')
    return jsonify({"message": "Method Not Allowed"}), 405


@app.errorhandler(404)
def page_not_found(error):
    logger.error('Page Not Found')
    return '', 404
    
if __name__=='__main__':
    with app.app_context():
        db.create_all()
    app.run(debug=True, host="0.0.0.0")