# webapp

This application is used to check Health Check of a database (MySQL) and 
provide basic Create,Read, Update operations on User entity.

The server exposes an API with the endpoint /healthz 
The client can call this API with GET method to verify health check of the database.
Also the web application exposes multiple APIs to support the operations mentioned above.

# Technologies used :
    
    Programming Language: Python
    Relational Database: MySQL
    Backend Framework: Flask
    ORM Framework:
        Python: SQLAlchemy
    
# How to run?
Make sure unzip module is installed on the vm 
To install this module, run the command

    yum install unzip
To install python in vm:

    sudo yum -y update
    sudo yum -y install epel-release
    sudo yum install wget make cmake gcc bzip2-devel libffi-devel zlib-devel
    sudo yum -y groupinstall "Development Tools"
    
    cd /usr/src 
    wget https://www.python.org/ftp/python/3.11.3/Python-3.11.3.tgz 
    tar xzf Python-3.11.3.tgz 
    cd Python-3.11.3 
    sudo ./configure --enable-optimizations 
    sudo make altinstall 
To install mysql on vm:

    sudo dnf install mysql-server
    sudo systemctl start mysqld.service
    sudo systemctl enable mysqld
To run the server, we need to first create virtual environment. This can be done
using below command

    python3 -m venv env

We then need to install all the required modules.
For this purpose, we have created requirements.txt file which will contain 
all the necessary modules.
Run this command to install the requirements

    pip3 install -r requirements.txt

Once the required modules are installed we need to run the server using 
the following command :

    python app.py

Once the server is running client can make API calls.

# Integration Testing
To run the integration tests, run the following command from the repository

    pytest
This will search for all the testcases in the files and run them.
At present, we have 2 testcases, one is creating a user and second is 
updating a user. In the first testcase, we create the user using the POST
API call and check whether the status code returned is 201. After that, we 
make a GET API call to fetch the user details. Then we check if the user details
and other fields are present. Similarly, we make a PUT API call to update the 
details of a user and then check the status code is 204. After that we make a
GET API call to check if the details are updated correctly or not.
