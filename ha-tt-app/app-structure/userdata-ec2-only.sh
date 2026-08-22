#!/bin/bash
# ============================================
# EC2 User Data Script - Web Server Setup
# ============================================
# PURPOSE: Set up EC2 instance with Node.js + App
# USES: Application code from GitHub or local package
# CONFIG: Database credentials passed via environment

set -e
exec > >(tee /var/log/user-data.log)
exec 2>&1

# ============================================
# CONFIGURATION
# ============================================
DB_TYPE="postgres"
DB_ENDPOINT="your-db-endpoint.rds.amazonaws.com"
DB_USER="postgres"
DB_PASSWORD="your-secure-password"
DB_NAME="ha-tt-db"
DB_PORT="5432"
APP_PORT=8000
APP_DIR="/opt/app"

# GitHub repository configuration
# Set to clone from repo, or leave empty to use embedded code
GITHUB_REPO="https://github.com/dev-enthusiast-84/dmi-c3-g3-demo-apps.git"
GITHUB_BRANCH="main"
GITHUB_APP_PATH="ha-tt-app/app-structure"

echo "=== EC2 User Data Script - Web Server Setup ==="
echo "Configuration:"
echo "  Database Type: $DB_TYPE"
echo "  Database Endpoint: $DB_ENDPOINT"
echo "  App Directory: $APP_DIR"
echo "  App Port: $APP_PORT"
date

# ============================================
# SECTION 1: System Setup
# ============================================
echo "=== Section 1: System Setup ==="

echo "Updating system packages..."
apt-get update
apt-get upgrade -y

echo "Installing Node.js 20.x..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
apt-get install -y nodejs

echo "Installing Nginx..."
apt-get install -y nginx
systemctl enable nginx

echo "✓ System setup complete"

# ============================================
# SECTION 2: Application Deployment
# ============================================
echo "=== Section 2: Application Deployment ==="

echo "Creating application directory: $APP_DIR"
mkdir -p $APP_DIR
cd $APP_DIR

# Option A: Clone from GitHub (if GITHUB_REPO is set)
if [ -n "$GITHUB_REPO" ]; then
  echo "Installing Git..."
  apt-get install -y git > /dev/null 2>&1

  echo "Cloning application from GitHub..."
  git clone --branch "$GITHUB_BRANCH" --depth 1 "$GITHUB_REPO" temp-repo

  echo "Copying application files from $GITHUB_APP_PATH..."
  if [ -d "temp-repo/$GITHUB_APP_PATH" ]; then
    cp -r temp-repo/$GITHUB_APP_PATH/* .
    rm -rf temp-repo
    echo "✓ Application cloned from GitHub ($GITHUB_BRANCH branch)"
  else
    echo "✗ Error: Could not find $GITHUB_APP_PATH in repository"
    rm -rf temp-repo
    exit 1
  fi
else
  # Option B: Use embedded application code (below)
  echo "Deploying embedded application code..."

  # Package.json
  cat > package.json <<'PACKAGE_EOF'
{
  "name": "hit-counter-app",
  "version": "2.0.0",
  "description": "Hit counter application with database integration",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "pg": "^8.11.3",
    "mysql2": "^3.6.5",
    "dotenv": "^16.3.1"
  }
}
PACKAGE_EOF

  # config.js
  cat > config.js <<'CONFIG_EOF'
require('dotenv').config();

const config = {
  app: {
    port: parseInt(process.env.APP_PORT || '8000'),
    env: process.env.NODE_ENV || 'development'
  },
  database: {
    type: process.env.DB_TYPE || 'postgres',
    endpoint: process.env.DB_ENDPOINT || 'localhost',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD,
    name: process.env.DB_NAME || 'ha-tt-db',
    port: parseInt(process.env.DB_PORT || '5432')
  }
};

function validateConfig() {
  const required = ['DB_ENDPOINT', 'DB_USER', 'DB_PASSWORD'];
  const missing = required.filter(key => !process.env[key]);

  if (missing.length > 0) {
    throw new Error(`Missing required environment variables: ${missing.join(', ')}`);
  }

  if (!['postgres', 'mysql'].includes(config.database.type)) {
    throw new Error(`Invalid DB_TYPE: ${config.database.type}`);
  }

  return true;
}

module.exports = { config, validateConfig };
CONFIG_EOF

  # db.js
  cat > db.js <<'DB_EOF'
const { config } = require('./config');

let pool = null;

async function initializePool() {
  try {
    const isRDS = config.database.endpoint && config.database.endpoint.includes('rds');

    if (config.database.type === 'postgres') {
      const { Pool } = require('pg');
      const poolConfig = {
        host: config.database.endpoint,
        user: config.database.user,
        password: config.database.password,
        database: config.database.name,
        port: config.database.port
      };
      if (isRDS) {
        poolConfig.ssl = { rejectUnauthorized: false };
      }
      pool = new Pool(poolConfig);
      console.log('PostgreSQL pool created');
      if (isRDS) console.log('SSL enabled for RDS');
    } else if (config.database.type === 'mysql') {
      const mysql = require('mysql2/promise');
      const mysqlConfig = {
        host: config.database.endpoint,
        user: config.database.user,
        password: config.database.password,
        database: config.database.name,
        port: config.database.port,
        waitForConnections: true,
        connectionLimit: 10,
        queueLimit: 0
      };
      if (isRDS) {
        mysqlConfig.ssl = 'amazon';
      }
      pool = mysql.createPool(mysqlConfig);
      console.log('MySQL pool created');
      if (isRDS) console.log('SSL enabled for RDS (Amazon mode)');
    }

    return pool;
  } catch (error) {
    console.error('Failed to create database pool:', error.message);
    throw error;
  }
}

async function initializeTables() {
  try {
    if (config.database.type === 'postgres') {
      const client = await pool.connect();
      try {
        await client.query(`
          CREATE TABLE IF NOT EXISTS hits (
            id SERIAL PRIMARY KEY,
            hit_count INT DEFAULT 0,
            last_hit TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
        `);
      } finally {
        client.release();
      }
    } else if (config.database.type === 'mysql') {
      const connection = await pool.getConnection();
      try {
        await connection.execute(`
          CREATE TABLE IF NOT EXISTS hits (
            id INT AUTO_INCREMENT PRIMARY KEY,
            hit_count INT DEFAULT 0,
            last_hit TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
          )
        `);
      } finally {
        connection.release();
      }
    }
    console.log('Hits table initialized');
  } catch (error) {
    console.error('Failed to initialize tables:', error.message);
    throw error;
  }
}

async function initializeCounter() {
  try {
    if (config.database.type === 'postgres') {
      const client = await pool.connect();
      try {
        const result = await client.query('SELECT COUNT(*) as count FROM hits');
        if (parseInt(result.rows[0].count) === 0) {
          await client.query('INSERT INTO hits (hit_count) VALUES (0)');
        }
      } finally {
        client.release();
      }
    } else if (config.database.type === 'mysql') {
      const connection = await pool.getConnection();
      try {
        const [rows] = await connection.execute('SELECT COUNT(*) as count FROM hits');
        if (rows[0].count === 0) {
          await connection.execute('INSERT INTO hits (hit_count) VALUES (0)');
        }
      } finally {
        connection.release();
      }
    }
    console.log('Hit counter initialized');
  } catch (error) {
    console.error('Failed to initialize counter:', error.message);
    throw error;
  }
}

async function healthCheck() {
  try {
    if (config.database.type === 'postgres') {
      const client = await pool.connect();
      try {
        await client.query('SELECT NOW()');
      } finally {
        client.release();
      }
    } else if (config.database.type === 'mysql') {
      const connection = await pool.getConnection();
      try {
        await connection.ping();
      } finally {
        connection.release();
      }
    }
    return true;
  } catch (error) {
    console.error('Health check failed:', error.message);
    return false;
  }
}

async function getHitData() {
  try {
    if (config.database.type === 'postgres') {
      const client = await pool.connect();
      try {
        const result = await client.query('SELECT hit_count, last_hit FROM hits WHERE id = 1');
        return result.rows[0];
      } finally {
        client.release();
      }
    } else if (config.database.type === 'mysql') {
      const connection = await pool.getConnection();
      try {
        const [rows] = await connection.execute('SELECT hit_count, last_hit FROM hits WHERE id = 1');
        return rows[0];
      } finally {
        connection.release();
      }
    }
  } catch (error) {
    console.error('Failed to get hit data:', error.message);
    throw error;
  }
}

async function incrementCounter() {
  try {
    if (config.database.type === 'postgres') {
      const client = await pool.connect();
      try {
        await client.query('UPDATE hits SET hit_count = hit_count + 1, last_hit = CURRENT_TIMESTAMP WHERE id = 1');
      } finally {
        client.release();
      }
    } else if (config.database.type === 'mysql') {
      const connection = await pool.getConnection();
      try {
        await connection.execute('UPDATE hits SET hit_count = hit_count + 1 WHERE id = 1');
      } finally {
        connection.release();
      }
    }
  } catch (error) {
    console.error('Failed to increment counter:', error.message);
    throw error;
  }
}

async function resetCounter() {
  try {
    if (config.database.type === 'postgres') {
      const client = await pool.connect();
      try {
        await client.query('UPDATE hits SET hit_count = 0, last_hit = CURRENT_TIMESTAMP WHERE id = 1');
      } finally {
        client.release();
      }
    } else if (config.database.type === 'mysql') {
      const connection = await pool.getConnection();
      try {
        await connection.execute('UPDATE hits SET hit_count = 0 WHERE id = 1');
      } finally {
        connection.release();
      }
    }
    console.log('Hit counter reset to 0');
  } catch (error) {
    console.error('Failed to reset counter:', error.message);
    throw error;
  }
}

async function closePool() {
  try {
    if (config.database.type === 'postgres' && pool) {
      await pool.end();
      console.log('PostgreSQL pool closed');
    } else if (config.database.type === 'mysql' && pool) {
      await pool.end();
      console.log('MySQL pool closed');
    }
  } catch (error) {
    console.error('Error closing pool:', error.message);
  }
}

module.exports = {
  initializePool,
  initializeTables,
  initializeCounter,
  healthCheck,
  getHitData,
  incrementCounter,
  resetCounter,
  closePool,
  getPool: () => pool
};
DB_EOF

  # server.js
  cat > server.js <<'SERVER_EOF'
const express = require('express');
const { config } = require('./config');

function createServer() {
  const app = express();

  app.use(express.json());
  app.use(express.urlencoded({ extended: true }));

  app.use((req, res, next) => {
    const start = Date.now();
    res.on('finish', () => {
      const duration = Date.now() - start;
      console.log(`${req.method} ${req.path} - ${res.statusCode} (${duration}ms)`);
    });
    next();
  });

  app.get('/health', (req, res) => {
    res.status(200).json({
      status: 'ready',
      uptime: process.uptime(),
      database: config.database.type
    });
  });

  app.use(require('./routes'));

  app.use((req, res) => {
    res.status(404).json({ error: 'Not Found', path: req.path });
  });

  app.use((err, req, res, next) => {
    console.error('Unhandled error:', err.message);
    res.status(500).json({
      error: 'Internal Server Error',
      message: config.app.env === 'development' ? err.message : undefined
    });
  });

  return app;
}

module.exports = createServer;
SERVER_EOF

  # routes.js (simplified - without all the embedded HTML styling)
  cat > routes.js <<'ROUTES_EOF'
const express = require('express');
const db = require('./db');
const { config } = require('./config');

const router = express.Router();

const HTML_TEMPLATE = (hitCount, lastHit, dbType) => `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Hit Counter</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; display: flex; justify-content: center; align-items: center; margin: 0; padding: 20px; }
    .container { background: white; padding: 40px; border-radius: 12px; box-shadow: 0 20px 60px rgba(0,0,0,0.3); max-width: 400px; width: 100%; text-align: center; }
    .label { font-size: 18px; color: #666; margin-bottom: 15px; font-weight: 500; }
    .count { font-size: 72px; font-weight: bold; color: #667eea; margin: 20px 0; }
    .timestamp { font-size: 13px; color: #999; margin-top: 25px; }
    .status { background: #d1fae5; color: #065f46; padding: 12px 16px; border-radius: 6px; margin-top: 20px; font-size: 12px; border: 1px solid #a7f3d0; }
    .db-info { background: #eff6ff; color: #1e40af; padding: 12px 16px; border-radius: 6px; margin-top: 15px; font-size: 12px; border: 1px solid #bfdbfe; }
    .footer { margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; }
    .reset-button { background: #ef4444; color: white; border: none; padding: 10px 20px; border-radius: 6px; font-size: 14px; font-weight: 500; cursor: pointer; margin-top: 15px; transition: background 0.2s; }
    .reset-button:hover { background: #dc2626; }
  </style>
</head>
<body>
  <div class="container">
    <div class="label">Total Page Hits</div>
    <div class="count">${hitCount}</div>
    <div class="timestamp">Last hit: ${lastHit}</div>
    <div class="status">&#10003; Database Connected</div>
    <div class="db-info">Database: ${dbType === 'postgres' ? 'PostgreSQL' : 'MySQL'}</div>
    <div class="footer">
      <p>Refresh to increment counter</p>
      <button class="reset-button" onclick="if (confirm('Reset counter to 0?')) { fetch('/reset', { method: 'POST' }).then(() => location.reload()); }">Reset Counter</button>
    </div>
  </div>
</body>
</html>
`;

router.get('/health', async (req, res) => {
  try {
    const isHealthy = await db.healthCheck();
    res.status(isHealthy ? 200 : 503).json({
      status: isHealthy ? 'healthy' : 'unhealthy',
      db: config.database.type
    });
  } catch (error) {
    console.error('Health check error:', error.message);
    res.status(503).json({ status: 'unhealthy', error: error.message });
  }
});

router.get('/', async (req, res) => {
  try {
    await db.incrementCounter();
    const hitData = await db.getHitData();
    const lastHit = new Date(hitData.last_hit).toLocaleString();
    res.status(200).send(HTML_TEMPLATE(hitData.hit_count, lastHit, config.database.type));
  } catch (error) {
    console.error('Error in main route:', error.message);
    res.status(500).send(`<html><body style="text-align:center;margin-top:50px"><h1>Error</h1><p>${error.message}</p></body></html>`);
  }
});

router.get('/api/hits', async (req, res) => {
  try {
    const hitData = await db.getHitData();
    res.status(200).json({
      hits: hitData.hit_count,
      lastHit: hitData.last_hit,
      database: config.database.type
    });
  } catch (error) {
    console.error('Error in API route:', error.message);
    res.status(500).json({ error: error.message });
  }
});

router.post('/reset', async (req, res) => {
  try {
    await db.resetCounter();
    res.status(200).json({ status: 'reset', message: 'Counter reset to 0' });
  } catch (error) {
    console.error('Error resetting counter:', error.message);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
ROUTES_EOF

  # index.js
  cat > index.js <<'INDEX_EOF'
const { config, validateConfig } = require('./config');
const db = require('./db');
const createServer = require('./server');

async function start() {
  try {
    console.log('Starting Hit Counter Application');
    console.log(`Environment: ${config.app.env}`);
    console.log(`Database: ${config.database.type} (${config.database.endpoint}:${config.database.port})`);

    validateConfig();
    console.log('Configuration validated');

    await db.initializePool();
    await db.initializeTables();
    await db.initializeCounter();
    console.log('Database initialized');

    const app = createServer();
    const server = app.listen(config.app.port, () => {
      console.log(`Server listening on port ${config.app.port}`);
      console.log(`Application ready at http://localhost:${config.app.port}`);
    });

    process.on('SIGTERM', () => {
      console.log('SIGTERM signal received: closing HTTP server');
      server.close(async () => {
        console.log('HTTP server closed');
        await db.closePool();
        process.exit(0);
      });
    });

    process.on('SIGINT', () => {
      console.log('SIGINT signal received: closing HTTP server');
      server.close(async () => {
        console.log('HTTP server closed');
        await db.closePool();
        process.exit(0);
      });
    });

  } catch (error) {
    console.error(`Failed to start application: ${error.message}`);
    console.error(error.stack);
    process.exit(1);
  }
}

start();
INDEX_EOF

fi

echo "Installing npm dependencies..."
npm install --production

echo "✓ Application deployment complete"

# ============================================
# SECTION 3: Environment Configuration
# ============================================
echo "=== Section 3: Configuration ==="

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

# ============================================
# SECTION 4: Nginx Configuration
# ============================================
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

nginx -t
systemctl reload nginx

echo "✓ Nginx configured"

# ============================================
# SECTION 5: Systemd Service
# ============================================
echo "=== Section 5: Service Setup ==="

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

systemctl daemon-reload
systemctl enable app
systemctl start app

sleep 2

if systemctl is-active --quiet app; then
  echo "✓ Application service is running"
else
  echo "✗ Application service failed to start"
  systemctl status app
fi

systemctl restart nginx

if systemctl is-active --quiet nginx; then
  echo "✓ Nginx is running"
else
  echo "✗ Nginx failed to start"
fi

echo ""
echo "=== EC2 Setup Complete ==="

INSTANCE_IP=$(curl -s --max-time 2 http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "")

if [ -z "$INSTANCE_IP" ]; then
  INSTANCE_IP="[Get from AWS Console]"
  IP_NOTE=" (Check AWS Console → EC2 → Instances for your public IP)"
else
  IP_NOTE=""
fi

echo "Application will be available at: http://${INSTANCE_IP}${IP_NOTE}"
echo "Health check: http://${INSTANCE_IP}/health"
echo ""
echo "Next steps:"
echo "1. Wait 1-2 minutes for the application to be ready"
echo "2. Access application: http://${INSTANCE_IP}"
echo "3. Monitor logs: ssh -i your-keypair.pem ubuntu@${INSTANCE_IP}"
echo "   Then: sudo journalctl -u app -f"
