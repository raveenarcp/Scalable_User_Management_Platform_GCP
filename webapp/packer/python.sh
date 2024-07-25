#!/bin/bash

# Update package repositories and install necessary dependencies
sudo yum update -y
sudo yum install -y epel-release
sudo yum groupinstall -y 'Development Tools'
sudo yum install -y openssl-devel libffi-devel bzip2-devel wget
# sudo yum install -y python39
# sudo yum install -y python3-devel mysql-devel

# Download Python 3.9.18 source tarball
wget https://www.python.org/ftp/python/3.9.18/Python-3.9.18.tgz

# Extract the Python source tarball
tar xzf Python-3.9.18.tgz

# Change to the Python source directory
cd Python-3.9.18/

# Configure Python build process
sudo ./configure --enable-optimizations --prefix=/usr/local --enable-shared LDFLAGS="-Wl,-rpath /usr/local/lib"

# Compile and install Python
sudo make altinstall
