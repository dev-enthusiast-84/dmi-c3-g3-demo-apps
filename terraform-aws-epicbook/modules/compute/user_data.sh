#!/bin/bash
set -e

apt-get update -y
apt-get upgrade -y

curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt-get install -y nodejs git nginx mysql-client curl

npm install -g npm@latest

systemctl enable nginx
systemctl start nginx