#!/bin/bash
# EC2 User Data Script - Modular Application Setup
# Installs Node.js and deploys modular hit-counter application
# Supports both PostgreSQL and MySQL

set -e
exec > >(tee /var/log/user-data.log)
exec 2>&1

# ============================================
# CONFIGURATION - UPDATE THESE VALUES
# ============================================
DB_TYPE="postgres"  # Set to "postgres" or "mysql"
DB_ENDPOINT="your-db-endpoint.rds.amazonaws.com"
DB_USER="postgres"  # Use "postgres" for PostgreSQL, "admin" for MySQL
DB_PASSWORD="your-secure-password"
DB_NAME="hitcounter"
DB_PORT="5432"      # Use 5432 for PostgreSQL, 3306 for MySQL
APP_PORT=8000
APP_DIR="/opt/app"

echo "=== Starting EC2 User Data Script ==="
echo "Database Type: $DB_TYPE"
echo "Database: $DB_ENDPOINT:$DB_PORT"
date

# ============================================
# UPDATE SYSTEM
# ============================================
echo "=== Updating System Packages ==="
apt-get update
apt-get upgrade -y

# ============================================
# INSTALL NODE.JS
# ============================================
echo "=== Installing Node.js 20.x ==="
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
apt-get install -y nodejs

node --version
npm --version

# ============================================
# INSTALL NGINX
# ============================================
echo "=== Installing Nginx ==="
apt-get install -y nginx
systemctl enable nginx

# ============================================
# CREATE APPLICATION DIRECTORY AND DEPLOY CODE
# ============================================
echo "=== Setting Up Application ==="
mkdir -p $APP_DIR
cd $APP_DIR

# Option A: Deploy from GitHub repository
# Uncomment and modify the URL to your repository
# echo "=== Cloning application from GitHub ==="
# git clone https://github.com/YOUR-USERNAME/YOUR-REPO.git .
# npm install --production

# Option B: Create application from inline code
echo "=== Creating modular application structure ==="

# Create package.json
cat > package.json <<'EOF'
{
  "name": "hit-counter-app",
  "version": "2.0.0",
  "description": "Simple hit counter application with database integration",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  },
  "keywords": ["express", "postgres", "mysql", "hit-counter"],
  "license": "MIT",
  "dependencies": {
    "express": "^4.18.2",
    "dotenv": "^16.3.1"
  },
  "optionalDependencies": {
    "pg": "^8.11.3",
    "mysql2": "^3.6.5"
  }
}
EOF

# Create config.js - Configuration management
cat > config.js <<'EOF'
require('dotenv').config();

const config = {
  app: {
    port: parseInt(process.env.APP_PORT || '8000'),
    env: process.env.NODE_ENV || 'production',
    name: 'hit-counter-app'
  },
  database: {
    type: process.env.DB_TYPE || 'postgres',
    endpoint: process.env.DB_ENDPOINT || 'localhost',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD,
    name: process.env.DB_NAME || 'hitcounter',
    port: parseInt(process.env.DB_PORT || '5432')
  }
};

function validateConfig() {
  const required = ['DB_ENDPOINT', 'DB_USER', 'DB_PASSWORD'];
  const missing = required.filter(key => !process.env[key]);
  if (missing.length > 0) {
    throw new Error(`Missing: ${missing.join(', ')}`);
  }
  if (!['postgres', 'mysql'].includes(config.database.type)) {
    throw new Error(`Invalid DB_TYPE: ${config.database.type}`);
  }
  return true;
}

module.exports = { config, validateConfig };
EOF

# Create logger.js - Logging utility
cat > logger.js <<'EOF'
const levels = { error: 0, warn: 1, info: 2, debug: 3 };
const colors = { error: '\x1b[31m', warn: '\x1b[33m', info: '\x1b[36m', debug: '\x1b[90m', reset: '\x1b[0m' };

function formatTime() { return new Date().toISOString(); }
function log(level, message) {
  if (levels[level] <= levels[process.env.LOG_LEVEL || 'info']) {
    const timestamp = formatTime();
    const levelStr = level.toUpperCase().padEnd(5);
    console.log(`${colors[level]}[${timestamp}] [${levelStr}]${colors.reset} ${message}`);
  }
}

module.exports = {
  error: (msg) => log('error', msg),
  warn: (msg) => log('warn', msg),
  info: (msg) => log('info', msg),
  debug: (msg) => log('debug', msg)
};
EOF

# Create db.js - Database abstraction layer
cat > db.js <<'EOF'
const { config } = require('./config');
const logger = require('./logger');

let pool = null;

async function initializePool() {
  try {
    if (config.database.type === 'postgres') {
      const { Pool } = require('pg');
      pool = new Pool({
        host: config.database.endpoint,
        user: config.database.user,
        password: config.database.password,
        database: config.database.name,
        port: config.database.port
      });
      logger.info('PostgreSQL pool created');
    } else if (config.database.type === 'mysql') {
      const mysql = require('mysql2/promise');
      pool = mysql.createPool({
        host: config.database.endpoint,
        user: config.database.user,
        password: config.database.password,
        database: config.database.name,
        port: config.database.port,
        connectionLimit: 10
      });
      logger.info('MySQL pool created');
    }
    return pool;
  } catch (error) {
    logger.error(`Database pool error: ${error.message}`);
    throw error;
  }
}

async function initializeTables() {
  try {
    if (config.database.type === 'postgres') {
      const client = await pool.connect();
      await client.query('CREATE TABLE IF NOT EXISTS hits (id SERIAL PRIMARY KEY, hit_count INT DEFAULT 0, last_hit TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');
      client.release();
    } else {
      const conn = await pool.getConnection();
      await conn.execute('CREATE TABLE IF NOT EXISTS hits (id INT AUTO_INCREMENT PRIMARY KEY, hit_count INT DEFAULT 0, last_hit TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP)');
      conn.release();
    }
    logger.info('Hits table initialized');
  } catch (error) {
    logger.error(`Table initialization error: ${error.message}`);
    throw error;
  }
}

async function initializeCounter() {
  try {
    if (config.database.type === 'postgres') {
      const client = await pool.connect();
      const result = await client.query('SELECT COUNT(*) as count FROM hits');
      if (parseInt(result.rows[0].count) === 0) {
        await client.query('INSERT INTO hits (hit_count) VALUES (0)');
      }
      client.release();
    } else {
      const conn = await pool.getConnection();
      const [rows] = await conn.execute('SELECT COUNT(*) as count FROM hits');
      if (rows[0].count === 0) {
        await conn.execute('INSERT INTO hits (hit_count) VALUES (0)');
      }
      conn.release();
    }
    logger.info('Hit counter initialized');
  } catch (error) {
    logger.error(`Counter initialization error: ${error.message}`);
    throw error;
  }
}

async function healthCheck() {
  try {
    if (config.database.type === 'postgres') {
      const client = await pool.connect();
      await client.query('SELECT NOW()');
      client.release();
    } else {
      const conn = await pool.getConnection();
      await conn.ping();
      conn.release();
    }
    return true;
  } catch (error) {
    logger.error(`Health check failed: ${error.message}`);
    return false;
  }
}

async function getHitData() {
  if (config.database.type === 'postgres') {
    const client = await pool.connect();
    const result = await client.query('SELECT hit_count, last_hit FROM hits WHERE id = 1');
    client.release();
    return result.rows[0];
  } else {
    const conn = await pool.getConnection();
    const [rows] = await conn.execute('SELECT hit_count, last_hit FROM hits WHERE id = 1');
    conn.release();
    return rows[0];
  }
}

async function incrementCounter() {
  if (config.database.type === 'postgres') {
    const client = await pool.connect();
    await client.query('UPDATE hits SET hit_count = hit_count + 1, last_hit = CURRENT_TIMESTAMP WHERE id = 1');
    client.release();
  } else {
    const conn = await pool.getConnection();
    await conn.execute('UPDATE hits SET hit_count = hit_count + 1 WHERE id = 1');
    conn.release();
  }
}

module.exports = { initializePool, initializeTables, initializeCounter, healthCheck, getHitData, incrementCounter };
EOF

# Create routes.js - HTTP route handlers
cat > routes.js <<'EOF'
const express = require('express');
const db = require('./db');
const { config } = require('./config');
const logger = require('./logger');
const router = express.Router();

router.get('/health', async (req, res) => {
  try {
    const isHealthy = await db.healthCheck();
    res.status(isHealthy ? 200 : 503).json({ status: isHealthy ? 'healthy' : 'unhealthy', db: config.database.type });
  } catch (error) {
    res.status(503).json({ status: 'unhealthy', error: error.message });
  }
});

router.get('/', async (req, res) => {
  try {
    await db.incrementCounter();
    const hitData = await db.getHitData();
    const dbLabel = config.database.type === 'postgres' ? 'PostgreSQL' : 'MySQL';

    res.status(200).send(`
      <!DOCTYPE html>
      <html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width"><title>Hit Counter</title>
      <style>body{font-family:Arial,sans-serif;text-align:center;margin-top:50px;background:#f5f5f5}.container{background:#fff;padding:40px;border-radius:10px;width:400px;margin:0 auto;box-shadow:0 2px 10px rgba(0,0,0,.1)}.count{font-size:56px;font-weight:bold;color:#2563eb;margin:20px 0}.label{font-size:20px;color:#666}.timestamp{font-size:14px;color:#999;margin-top:30px}.status{background:#d1fae5;color:#065f46;padding:10px;border-radius:5px;margin-top:20px;font-size:12px}</style>
      </head><body><div class="container"><div class="label">Total Page Hits</div><div class="count">${hitData.hit_count}</div><div class="timestamp">Last hit: ${new Date(hitData.last_hit).toLocaleString()}</div><div class="status">✓ ${dbLabel} Connected</div></div></body></html>
    `);
  } catch (error) {
    logger.error(`Route error: ${error.message}`);
    res.status(500).send(`<html><body style="text-align:center;margin-top:50px"><h1>Error</h1><p>${error.message}</p></body></html>`);
  }
});

router.get('/api/hits', async (req, res) => {
  try {
    const hitData = await db.getHitData();
    res.json({ hits: hitData.hit_count, database: config.database.type });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
EOF

# Create server.js - Express server setup
cat > server.js <<'EOF'
const express = require('express');
const { config } = require('./config');
const logger = require('./logger');

function createServer() {
  const app = express();
  app.use(express.json());
  app.use((req, res, next) => {
    const start = Date.now();
    res.on('finish', () => {
      logger.info(`${req.method} ${req.path} - ${res.statusCode} (${Date.now() - start}ms)`);
    });
    next();
  });
  app.use(require('./routes'));
  app.use((req, res) => { res.status(404).json({ error: 'Not Found' }); });
  app.use((err, req, res, next) => {
    logger.error(`Error: ${err.message}`);
    res.status(500).json({ error: 'Internal Server Error' });
  });
  return app;
}

module.exports = createServer;
EOF

# Create index.js - Main entry point
cat > index.js <<'EOF'
#!/usr/bin/env node
const { config, validateConfig } = require('./config');
const logger = require('./logger');
const db = require('./db');
const createServer = require('./server');

async function start() {
  try {
    logger.info('Starting Hit Counter Application');
    logger.info(`Database: ${config.database.type} (${config.database.endpoint}:${config.database.port})`);

    validateConfig();
    await db.initializePool();
    await db.initializeTables();
    await db.initializeCounter();
    logger.info('Database initialized');

    const app = createServer();
    const server = app.listen(config.app.port, () => {
      logger.info(`Server listening on port ${config.app.port}`);
    });

    process.on('SIGTERM', () => { server.close(() => process.exit(0)); });
    process.on('SIGINT', () => { server.close(() => process.exit(0)); });
  } catch (error) {
    logger.error(`Fatal error: ${error.message}`);
    process.exit(1);
  }
}

start();
EOF

# Create .env file
cat > .env <<ENVEOF
DB_TYPE=$DB_TYPE
DB_ENDPOINT=$DB_ENDPOINT
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_NAME=$DB_NAME
DB_PORT=$DB_PORT
APP_PORT=$APP_PORT
NODE_ENV=production
LOG_LEVEL=info
ENVEOF

# Install dependencies
echo "=== Installing Node.js Dependencies ==="
npm install --production

# ============================================
# CONFIGURE NGINX
# ============================================
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

# ============================================
# CREATE SYSTEMD SERVICE
# ============================================
echo "=== Creating Systemd Service ==="

cat > /etc/systemd/system/app.service <<SYSTEMD_EOF
[Unit]
Description=Hit Counter Node.js Application
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=$APP_DIR
Environment="DB_TYPE=$DB_TYPE"
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

# ============================================
# START SERVICES
# ============================================
echo "=== Starting Services ==="

systemctl enable app
systemctl start app
systemctl restart nginx

# ============================================
# HEALTH CHECKS
# ============================================
echo "=== Performing Health Checks ==="
sleep 5

if systemctl is-active --quiet app; then
  echo "✓ Node.js application is running"
else
  echo "✗ Node.js application failed"
  systemctl status app
fi

if systemctl is-active --quiet nginx; then
  echo "✓ Nginx is running"
fi

echo "=== User Data Script Completed Successfully ==="
echo "Database: $DB_TYPE on port $DB_PORT"
echo "Application will be available at http://<instance-ip>"
echo "View logs: sudo journalctl -u app -f"
