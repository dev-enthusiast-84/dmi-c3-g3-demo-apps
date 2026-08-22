#!/bin/bash
# CONFIGURATION - UPDATE THESE BEFORE PASTING INTO LAUNCH TEMPLATE
# MySQL Database Configuration
DB_ENDPOINT="your-db-endpoint.rds.amazonaws.com"
DB_USER="admin"
DB_PASSWORD="your-secure-password"
DB_NAME="hitcounter"
DB_PORT="3306"
APP_PORT=8000
APP_DIR="/opt/app"

set -e
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "=== Starting EC2 User Data Script (MySQL) ==="
date

apt-get update
apt-get upgrade -y

echo "=== Installing Node.js ==="
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
apt-get install -y nodejs

echo "=== Installing Nginx ==="
apt-get install -y nginx
systemctl enable nginx

echo "=== Setting Up Application Directory ==="
mkdir -p $APP_DIR
cd $APP_DIR

echo "=== Creating Node.js Application (MySQL) ==="

cat > package.json <<'PACKAGE_EOF'
{
  "name": "hit-counter-app",
  "version": "1.0.0",
  "description": "Simple hit counter application with database integration",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "mysql2": "^3.6.5",
    "dotenv": "^16.3.1"
  }
}
PACKAGE_EOF

cat > index.js <<'APP_EOF'
const express = require('express');
const mysql = require('mysql2/promise');
require('dotenv').config();

const app = express();
const port = process.env.APP_PORT || 8000;

const dbConfig = {
  host: process.env.DB_ENDPOINT || 'localhost',
  user: process.env.DB_USER || 'admin',
  password: process.env.DB_PASSWORD || 'changeme',
  database: process.env.DB_NAME || 'hitcounter',
  port: process.env.DB_PORT || 3306,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
};

let pool;

async function initializeDatabase() {
  try {
    pool = mysql.createPool(dbConfig);
    console.log('Database pool created successfully');
  } catch (error) {
    console.error('Error creating database pool:', error);
    process.exit(1);
  }
}

async function createTableIfNotExists() {
  try {
    const connection = await pool.getConnection();
    await connection.execute(`
      CREATE TABLE IF NOT EXISTS hits (
        id INT AUTO_INCREMENT PRIMARY KEY,
        hit_count INT DEFAULT 0,
        last_hit TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )
    `);
    await connection.release();
    console.log('Hits table initialized');
  } catch (error) {
    console.error('Error creating table:', error);
    process.exit(1);
  }
}

async function initializeHitCounter() {
  try {
    const connection = await pool.getConnection();
    const [rows] = await connection.execute('SELECT COUNT(*) as count FROM hits');

    if (rows[0].count === 0) {
      await connection.execute('INSERT INTO hits (hit_count) VALUES (0)');
      console.log('Hit counter initialized to 0');
    }

    await connection.release();
  } catch (error) {
    console.error('Error initializing hit counter:', error);
    process.exit(1);
  }
}

app.get('/health', async (req, res) => {
  try {
    const connection = await pool.getConnection();
    await connection.ping();
    await connection.release();
    res.status(200).json({ status: 'healthy', timestamp: new Date().toISOString() });
  } catch (error) {
    res.status(500).json({ status: 'unhealthy', error: error.message });
  }
});

app.get('/', async (req, res) => {
  try {
    const connection = await pool.getConnection();
    await connection.execute('UPDATE hits SET hit_count = hit_count + 1 WHERE id = 1');
    const [rows] = await connection.execute('SELECT hit_count, last_hit FROM hits WHERE id = 1');
    await connection.release();

    const hitCount = rows[0].hit_count;
    const lastHit = rows[0].last_hit;

    res.status(200).send(`
      <!DOCTYPE html>
      <html>
        <head>
          <title>Hit Counter App</title>
          <style>
            body { font-family: Arial, sans-serif; text-align: center; margin-top: 50px; background: #f5f5f5; }
            .container { background: #ffffff; padding: 40px; border-radius: 10px; width: 400px; margin: 0 auto; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
            .count { font-size: 56px; font-weight: bold; color: #2563eb; margin: 20px 0; }
            .label { font-size: 20px; color: #666; margin-bottom: 10px; }
            .timestamp { font-size: 14px; color: #999; margin-top: 30px; }
            .status { background: #d1fae5; color: #065f46; padding: 10px; border-radius: 5px; margin-top: 20px; font-size: 12px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="label">Total Page Hits</div>
            <div class="count">${hitCount}</div>
            <div class="timestamp">Last hit: ${new Date(lastHit).toLocaleString()}</div>
            <div class="status">✓ Database Connected (MySQL)</div>
          </div>
        </body>
      </html>
    `);
  } catch (error) {
    console.error('Error incrementing hit count:', error);
    res.status(500).send(`
      <html>
        <head><title>Error</title></head>
        <body style="font-family: Arial; text-align: center; margin-top: 50px;">
          <h1>Database Connection Error</h1>
          <p>${error.message}</p>
          <p><a href="/">Retry</a></p>
        </body>
      </html>
    `);
  }
});

async function startServer() {
  try {
    await initializeDatabase();
    await createTableIfNotExists();
    await initializeHitCounter();
    app.listen(port, () => {
      console.log(`Application listening on port ${port}`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

startServer();
APP_EOF

cat > .env <<EOF
DB_ENDPOINT=$DB_ENDPOINT
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_NAME=$DB_NAME
DB_PORT=$DB_PORT
APP_PORT=$APP_PORT
NODE_ENV=production
EOF

echo "=== Installing Dependencies ==="
npm install --production

echo "=== Configuring Nginx ==="

cat > /etc/nginx/sites-available/default <<'NGINX_EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /health {
        proxy_pass http://127.0.0.1:8000/health;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
    }
}
NGINX_EOF

nginx -t
systemctl reload nginx

echo "=== Creating Systemd Service ==="

cat > /etc/systemd/system/app.service <<SYSTEMD_EOF
[Unit]
Description=Hit Counter Node.js Application (MySQL)
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=$APP_DIR
Environment="PATH=/usr/bin"
Environment="DB_ENDPOINT=$DB_ENDPOINT"
Environment="DB_USER=$DB_USER"
Environment="DB_PASSWORD=$DB_PASSWORD"
Environment="DB_NAME=$DB_NAME"
Environment="DB_PORT=$DB_PORT"
Environment="APP_PORT=$APP_PORT"
Environment="NODE_ENV=production"
ExecStart=/usr/bin/node $APP_DIR/index.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SYSTEMD_EOF

systemctl daemon-reload

echo "=== Starting Services ==="

systemctl enable app
systemctl start app
systemctl restart nginx

echo "=== Performing Health Checks ==="
sleep 5

if systemctl is-active --quiet app; then
  echo "✓ Node.js application is running"
else
  echo "✗ Node.js application failed to start"
  systemctl status app
fi

if systemctl is-active --quiet nginx; then
  echo "✓ Nginx is running"
else
  echo "✗ Nginx failed to start"
fi

echo "=== User Data Script Completed ==="
echo "Database: MySQL on port 3306"
echo "Application will be available at http://<instance-ip> in 2-3 minutes"
echo "View logs: sudo journalctl -u app -f"
