#!/bin/bash

# Install the Ops Agent
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh && sudo bash add-google-cloud-ops-agent-repo.sh --also-install

# Create Ops Agent configuration directory if it doesn't exist
sudo mkdir -p /etc/google-cloud-ops-agent/config.d/
sudo chown -R csye6225:csye6225 /etc/google-cloud-ops-agent/
sudo chmod -R 755 /etc/google-cloud-ops-agent/config.d/

# Configure the Ops Agent to collect application logs
sudo mv /tmp/config.yaml /etc/google-cloud-ops-agent/

# Restart the Ops Agent to apply the configuration
sudo systemctl restart google-cloud-ops-agent