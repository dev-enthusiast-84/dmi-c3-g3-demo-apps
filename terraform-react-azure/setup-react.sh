#!/bin/bash


# Update and install dependencies
sudo apt update -y
sudo apt install -y git nginx curl build-essential


# Install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt update
sudo apt install -y nodejs


# Start and enable Nginx
sudo systemctl start nginx
sudo systemctl enable nginx


# Clone the React app repository
cd /home/ubuntu
git clone https://github.com/pravinmishraaws/my-react-app.git
cd my-react-app


# Modify App.js with your custom info
sed -i 's|<h2>Deployed by:.*</h2>|<h2>Deployed by: <strong>Anjana Muthunayake</strong></h2>|' src/App.js
sed -i 's|<p>Date:.*</p>|<p>Date: <strong>07/14/2026</strong></p>|' src/App.js


# Install app dependencies and build
npm install
npm run build


# Deploy build to Nginx
sudo rm -rf /var/www/html/*
sudo cp -r build/* /var/www/html/
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html


# Configure Nginx for React app routing
sudo bash -c 'cat > /etc/nginx/sites-available/default << EOF
server {
    listen 80;
    server_name _;


    root /var/www/html;
    index index.html;


    location / {
        try_files \$uri /index.html;
    }


    error_page 404 /index.html;
}
EOF'


# Restart Nginx
sudo systemctl restart nginx