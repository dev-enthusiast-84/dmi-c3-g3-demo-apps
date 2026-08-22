#!/bin/bash
set -e
exec > >(tee /var/log/user-data.log)
exec 2>&1

DB_TYPE="postgres"
DB_ENDPOINT="your-db-endpoint.rds.amazonaws.com"
DB_USER="postgres"
DB_PASSWORD="your-secure-password"
DB_NAME="ha-tt-db"
DB_PORT="5432"
APP_PORT=8000
APP_DIR="/opt/app"
GITHUB_REPO="https://github.com/dev-enthusiast-84/dmi-c3-g3-demo-apps.git"
GITHUB_BRANCH="main"
GITHUB_APP_PATH="ha-tt-app/app-structure"

echo "=== EC2 Setup Starting ==="
echo "DB: $DB_TYPE, Endpoint: $DB_ENDPOINT, App: $APP_DIR"
date

echo "=== Section 1: System Setup ==="
apt-get update && apt-get upgrade -y
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - && apt-get install -y nodejs
apt-get install -y nginx git && systemctl enable nginx
echo "✓ System setup complete"

echo "=== Section 2: Application Deployment ==="
mkdir -p $APP_DIR && cd $APP_DIR
echo "Cloning from GitHub: $GITHUB_REPO (branch: $GITHUB_BRANCH)"
git clone --branch "$GITHUB_BRANCH" --depth 1 "$GITHUB_REPO" temp-repo || { echo "✗ Clone failed"; exit 1; }
if [ -d "temp-repo/$GITHUB_APP_PATH" ]; then
  cp -r temp-repo/$GITHUB_APP_PATH/* . && rm -rf temp-repo
  echo "✓ Application cloned from GitHub"
else
  echo "✗ Error: $GITHUB_APP_PATH not found in repository"
  rm -rf temp-repo && exit 1
fi

echo "Installing npm dependencies..."
npm install --production
echo "✓ Application deployment complete"

echo "=== Section 3: Environment Configuration ==="
cat > .env <<ENV_EOF
DB_TYPE=$DB_TYPE
DB_ENDPOINT=$DB_ENDPOINT
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_NAME=$DB_NAME
DB_PORT=$DB_PORT
APP_PORT=$APP_PORT
NODE_ENV=production
ENV_EOF

chmod 600 .env
echo "✓ Environment configured"

echo "=== Section 4: Nginx Configuration ==="
cat > /etc/nginx/sites-available/default <<'NGINX_EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
    location /health {
        proxy_pass http://127.0.0.1:8000/health;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
    }
}
NGINX_EOF

nginx -t && systemctl reload nginx
echo "✓ Nginx configured"

echo "=== Section 5: Systemd Service ==="
cat > /etc/systemd/system/app.service <<'SERVICE_EOF'
[Unit]
Description=Hit Counter Web Application
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/app
EnvironmentFile=/opt/app/.env
ExecStart=/usr/bin/node /opt/app/index.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SERVICE_EOF

systemctl daemon-reload && systemctl enable app && systemctl start app
sleep 2

systemctl is-active --quiet app && echo "✓ Application service is running" || { echo "✗ Application service failed"; systemctl status app; }
systemctl restart nginx
systemctl is-active --quiet nginx && echo "✓ Nginx is running" || echo "✗ Nginx failed"

echo ""
echo "=== EC2 Setup Complete ==="
INSTANCE_IP=$(curl -s --max-time 2 http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "")
INSTANCE_IP="${INSTANCE_IP:-[Get from AWS Console]}"
echo "Application: http://${INSTANCE_IP}"
echo "Health: http://${INSTANCE_IP}/health"
