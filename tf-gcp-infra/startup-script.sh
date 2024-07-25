#!/bin/bash
echo DB_USER="${DB_USER}" > /opt/webapp/.env
echo DB_PASSWORD="${DB_PASSWORD}" >> /opt/webapp/.env
echo DB_URL="${DB_URL}" >> /opt/webapp/.env
echo PROJECT_ID="${PROJECT_ID}" >> /opt/webapp/.env
echo TOPIC_ID="${TOPIC_ID}" >> /opt/webapp/.env
echo APP_LOG_FILE="/opt/webapp/app_log_file.log" >> /opt/webapp/.env
sleep 5
sudo systemctl restart webapp

