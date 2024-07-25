#!/bin/bash

sudo yum install -y unzip
sudo unzip /tmp/webapp.zip -d /opt/webapp/
sudo ln -s /usr/local/bin/python3.9 /usr/bin/python3.9
sudo /usr/local/bin/python3.9 -m pip install --upgrade pip wheel

sudo yum install -y mysql-devel
sudo /usr/local/bin/python3.9 -m pip install -r /opt/webapp/requirements.txt

#curl -sSO https://dl.google.com/cloudagents/add-monitoring-agent-repo.sh
#sudo bash add-monitoring-agent-repo.sh --also-install


