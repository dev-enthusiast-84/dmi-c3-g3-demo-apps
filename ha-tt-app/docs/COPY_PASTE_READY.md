# Copy & Paste Ready Scripts for AWS Launch Template

⚠️ **READ FIRST:** These scripts deploy the application to EC2. They do NOT create an RDS instance. You must have an existing RDS instance running before using these scripts.

## USER DATA SCRIPT SCOPE

This is a **user data script for EC2 instances**. It runs ON the instance and sets it up as a web server.

### Script Responsibilities (EC2 Setup Only):
✅ Install Node.js 20.x runtime
✅ Install Nginx reverse proxy
✅ Deploy application code
✅ Configure environment variables (database connection details)
✅ Create systemd service for auto-restart
✅ Start services on port 80

### What Script Does NOT Do:
❌ Create RDS instance
❌ Create VPC or networking
❌ Create security groups
❌ Create databases (optional - app handles it)

## ⚠️ PREREQUISITES (Setup Before EC2 Launch)

Complete this external setup FIRST:

**RDS Instance (PostgreSQL or MySQL)**
- Create in AWS RDS Console
- Get status: "Available"
- Get endpoint: `your-db.xxxxx.region.rds.amazonaws.com`
- Get master username: `postgres` (PostgreSQL) or `admin` (MySQL)
- Get master password: (from RDS creation)
- Get port: `5432` (PostgreSQL) or `3306` (MySQL)

**AWS Infrastructure**
- EC2 security group (allow port 80 inbound)
- RDS security group (allow EC2 access on DB port)
- EC2 key pair created
- Network configured between EC2 and RDS

### Ready to Launch EC2?
Once you have RDS running and credentials ready, use this script to launch the EC2 instance and set up the web server.

---

## 🎯 Which Script to Use?

### PostgreSQL
Use the script below for PostgreSQL databases.
- Port: 5432
- Default User: postgres

### MySQL
Use the script below for MySQL/MariaDB databases.
- Port: 3306
- Default User: admin

---

## 📋 PostgreSQL Version

### Step 1: Copy the Script Below

Scroll down and copy everything from `#!/bin/bash` to the end.

### Step 2: Edit Configuration

Find these lines in the script and update them:

```bash
DB_ENDPOINT="your-postgres-endpoint.region.rds.amazonaws.com"
DB_USER="postgres"
DB_PASSWORD="your-secure-password-here"
DB_NAME="ha-tt-db"
DB_PORT="5432"
```

### Step 3: Paste into AWS Launch Template

1. Open AWS Console → EC2 → Launch Templates
2. Create Launch Template (or edit existing)
3. Scroll to "Advanced Details" → "User Data"
4. Paste the entire script
5. Make sure the checkbox is **UNCHECKED** (not base64 encoded)

### Script for PostgreSQL:

```bash
#!/bin/bash
set -e
exec > >(tee /var/log/user-data.log)
exec 2>&1

# ============================================
# CONFIGURATION - EDIT THESE VALUES
# ============================================
DB_TYPE="postgres"
DB_ENDPOINT="your-postgres-endpoint.region.rds.amazonaws.com"
DB_USER="postgres"
DB_PASSWORD="your-secure-password-here"
DB_NAME="ha-tt-db"
DB_PORT="5432"
APP_PORT=8000
APP_DIR="/opt/app"

echo "=== Starting Deployment ==="
echo "Database: PostgreSQL ($DB_ENDPOINT:$DB_PORT)"
date

# ============================================
# INSTALL DEPENDENCIES
# ============================================
apt-get update
apt-get upgrade -y
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
apt-get install -y nodejs nginx

echo "Node: $(node --version)"
echo "npm: $(npm --version)"

# ============================================
# CREATE APPLICATION
# ============================================
systemctl enable nginx
mkdir -p $APP_DIR
cd $APP_DIR

cat > package.json <<'EOF'
{
  "name": "hit-counter-app",
  "version": "2.0.0",
  "dependencies": {
    "express": "^4.18.2",
    "pg": "^8.11.3",
    "dotenv": "^16.3.1"
  }
}
EOF

cat > config.js <<'EOF'
require('dotenv').config();
const config = {
  app: { port: parseInt(process.env.APP_PORT || '8000'), env: process.env.NODE_ENV || 'production' },
  database: {
    type: 'postgres',
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
  if (missing.length > 0) throw new Error(`Missing: ${missing.join(', ')}`);
  return true;
}
module.exports = { config, validateConfig };
EOF

cat > logger.js <<'EOF'
const log = (level, message) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] [${level.toUpperCase()}] ${message}`);
};
module.exports = {
  error: (msg) => log('error', msg),
  warn: (msg) => log('warn', msg),
  info: (msg) => log('info', msg),
  debug: (msg) => log('debug', msg)
};
EOF

cat > db.js <<'EOF'
const { Pool } = require('pg');
const { config } = require('./config');
const logger = require('./logger');
let pool = null;

async function initializePool() {
  pool = new Pool({
    host: config.database.endpoint,
    user: config.database.user,
    password: config.database.password,
    database: config.database.name,
    port: config.database.port
  });
  logger.info('PostgreSQL pool created');
  return pool;
}

async function initializeTables() {
  const client = await pool.connect();
  try {
    await client.query(`
      CREATE TABLE IF NOT EXISTS hits (
        id SERIAL PRIMARY KEY,
        hit_count INT DEFAULT 0,
        last_hit TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    logger.info('Hits table initialized');
  } finally {
    client.release();
  }
}

async function initializeCounter() {
  const client = await pool.connect();
  try {
    const result = await client.query('SELECT COUNT(*) as count FROM hits');
    if (parseInt(result.rows[0].count) === 0) {
      await client.query('INSERT INTO hits (hit_count) VALUES (0)');
      logger.info('Hit counter initialized to 0');
    }
  } finally {
    client.release();
  }
}

async function healthCheck() {
  try {
    const client = await pool.connect();
    await client.query('SELECT NOW()');
    client.release();
    return true;
  } catch (error) {
    logger.error(`Health check failed: ${error.message}`);
    return false;
  }
}

async function getHitData() {
  const client = await pool.connect();
  try {
    const result = await client.query('SELECT hit_count, last_hit FROM hits WHERE id = 1');
    return result.rows[0];
  } finally {
    client.release();
  }
}

async function incrementCounter() {
  const client = await pool.connect();
  try {
    await client.query('UPDATE hits SET hit_count = hit_count + 1, last_hit = CURRENT_TIMESTAMP WHERE id = 1');
  } finally {
    client.release();
  }
}

module.exports = { initializePool, initializeTables, initializeCounter, healthCheck, getHitData, incrementCounter };
EOF

cat > routes.js <<'EOF'
const express = require('express');
const db = require('./db');
const logger = require('./logger');
const router = express.Router();

router.get('/health', async (req, res) => {
  try {
    const isHealthy = await db.healthCheck();
    res.status(isHealthy ? 200 : 503).json({ status: isHealthy ? 'healthy' : 'unhealthy', db: 'postgresql' });
  } catch (error) {
    res.status(503).json({ status: 'unhealthy', error: error.message });
  }
});

router.get('/', async (req, res) => {
  try {
    await db.incrementCounter();
    const hitData = await db.getHitData();
    res.status(200).send(`
      <!DOCTYPE html>
      <html>
        <head><meta charset="UTF-8"><meta name="viewport" content="width=device-width"><title>Hit Counter</title>
        <style>body{font-family:Arial;text-align:center;margin-top:50px;background:#f5f5f5}.container{background:#fff;padding:40px;border-radius:10px;width:400px;margin:0 auto;box-shadow:0 2px 10px rgba(0,0,0,.1)}.count{font-size:56px;font-weight:bold;color:#2563eb;margin:20px 0}.label{font-size:20px;color:#666}.timestamp{font-size:14px;color:#999;margin-top:30px}.status{background:#d1fae5;color:#065f46;padding:10px;border-radius:5px;margin-top:20px;font-size:12px}</style>
        </head><body><div class="container"><div class="label">Total Page Hits</div><div class="count">${hitData.hit_count}</div><div class="timestamp">Last hit: ${new Date(hitData.last_hit).toLocaleString()}</div><div class="status">✓ PostgreSQL Connected</div></div></body>
      </html>
    `);
  } catch (error) {
    logger.error(`Error: ${error.message}`);
    res.status(500).send(`<html><body style="text-align:center;margin-top:50px"><h1>Error</h1><p>${error.message}</p></body></html>`);
  }
});

router.get('/api/hits', async (req, res) => {
  try {
    const hitData = await db.getHitData();
    res.json({ hits: hitData.hit_count, database: 'postgresql' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
EOF

cat > server.js <<'EOF'
const express = require('express');
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

cat > index.js <<'EOF'
#!/usr/bin/env node
const { config, validateConfig } = require('./config');
const logger = require('./logger');
const db = require('./db');
const createServer = require('./server');

async function start() {
  try {
    logger.info('Starting Hit Counter Application');
    logger.info(`Database: ${config.database.endpoint}:${config.database.port}`);
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
    logger.error(`Fatal: ${error.message}`);
    process.exit(1);
  }
}
start();
EOF

cat > .env <<ENVEOF
DB_TYPE=postgres
DB_ENDPOINT=$DB_ENDPOINT
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_NAME=$DB_NAME
DB_PORT=$DB_PORT
APP_PORT=$APP_PORT
NODE_ENV=production
ENVEOF

echo "Installing dependencies..."
npm install --production

# ============================================
# CONFIGURE NGINX
# ============================================
cat > /etc/nginx/sites-available/default <<'NGINX_EOF'
server {
    listen 80 default_server;
    server_name _;
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
NGINX_EOF

nginx -t && systemctl reload nginx

# ============================================
# CREATE SYSTEMD SERVICE
# ============================================
cat > /etc/systemd/system/app.service <<SYSTEMD_EOF
[Unit]
Description=Hit Counter App
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=$APP_DIR
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
systemctl enable app
systemctl start app
systemctl restart nginx

sleep 5
echo "=== Deployment Complete ==="
echo "Application: http://<instance-ip>"
echo "Health: http://<instance-ip>/health"
echo "View logs: sudo journalctl -u app -f"
```

---

## 📋 MySQL Version

### Step 1: Copy the Script Below

Scroll down and copy everything from `#!/bin/bash` to the end.

### Step 2: Edit Configuration

Find these lines in the script and update them:

```bash
DB_ENDPOINT="your-mysql-endpoint.region.rds.amazonaws.com"
DB_USER="admin"
DB_PASSWORD="your-secure-password-here"
DB_NAME="ha-tt-db"
DB_PORT="3306"
```

### Step 3: Paste into AWS Launch Template

(Same as PostgreSQL - see instructions above)

### Script for MySQL:

```bash
#!/bin/bash
set -e
exec > >(tee /var/log/user-data.log)
exec 2>&1

# ============================================
# CONFIGURATION - EDIT THESE VALUES
# ============================================
DB_TYPE="mysql"
DB_ENDPOINT="your-mysql-endpoint.region.rds.amazonaws.com"
DB_USER="admin"
DB_PASSWORD="your-secure-password-here"
DB_NAME="ha-tt-db"
DB_PORT="3306"
APP_PORT=8000
APP_DIR="/opt/app"

echo "=== Starting Deployment ==="
echo "Database: MySQL ($DB_ENDPOINT:$DB_PORT)"
date

# ============================================
# INSTALL DEPENDENCIES
# ============================================
apt-get update
apt-get upgrade -y
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
apt-get install -y nodejs nginx

echo "Node: $(node --version)"
echo "npm: $(npm --version)"

# ============================================
# CREATE APPLICATION
# ============================================
systemctl enable nginx
mkdir -p $APP_DIR
cd $APP_DIR

cat > package.json <<'EOF'
{
  "name": "hit-counter-app",
  "version": "2.0.0",
  "dependencies": {
    "express": "^4.18.2",
    "mysql2": "^3.6.5",
    "dotenv": "^16.3.1"
  }
}
EOF

cat > config.js <<'EOF'
require('dotenv').config();
const config = {
  app: { port: parseInt(process.env.APP_PORT || '8000'), env: process.env.NODE_ENV || 'production' },
  database: {
    type: 'mysql',
    endpoint: process.env.DB_ENDPOINT || 'localhost',
    user: process.env.DB_USER || 'admin',
    password: process.env.DB_PASSWORD,
    name: process.env.DB_NAME || 'ha-tt-db',
    port: parseInt(process.env.DB_PORT || '3306')
  }
};
function validateConfig() {
  const required = ['DB_ENDPOINT', 'DB_USER', 'DB_PASSWORD'];
  const missing = required.filter(key => !process.env[key]);
  if (missing.length > 0) throw new Error(`Missing: ${missing.join(', ')}`);
  return true;
}
module.exports = { config, validateConfig };
EOF

cat > logger.js <<'EOF'
const log = (level, message) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] [${level.toUpperCase()}] ${message}`);
};
module.exports = {
  error: (msg) => log('error', msg),
  warn: (msg) => log('warn', msg),
  info: (msg) => log('info', msg),
  debug: (msg) => log('debug', msg)
};
EOF

cat > db.js <<'EOF'
const mysql = require('mysql2/promise');
const { config } = require('./config');
const logger = require('./logger');
let pool = null;

async function initializePool() {
  pool = mysql.createPool({
    host: config.database.endpoint,
    user: config.database.user,
    password: config.database.password,
    database: config.database.name,
    port: config.database.port,
    connectionLimit: 10
  });
  logger.info('MySQL pool created');
  return pool;
}

async function initializeTables() {
  const conn = await pool.getConnection();
  try {
    await conn.execute(`
      CREATE TABLE IF NOT EXISTS hits (
        id INT AUTO_INCREMENT PRIMARY KEY,
        hit_count INT DEFAULT 0,
        last_hit TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )
    `);
    logger.info('Hits table initialized');
  } finally {
    conn.release();
  }
}

async function initializeCounter() {
  const conn = await pool.getConnection();
  try {
    const [rows] = await conn.execute('SELECT COUNT(*) as count FROM hits');
    if (rows[0].count === 0) {
      await conn.execute('INSERT INTO hits (hit_count) VALUES (0)');
      logger.info('Hit counter initialized to 0');
    }
  } finally {
    conn.release();
  }
}

async function healthCheck() {
  try {
    const conn = await pool.getConnection();
    await conn.ping();
    conn.release();
    return true;
  } catch (error) {
    logger.error(`Health check failed: ${error.message}`);
    return false;
  }
}

async function getHitData() {
  const conn = await pool.getConnection();
  try {
    const [rows] = await conn.execute('SELECT hit_count, last_hit FROM hits WHERE id = 1');
    return rows[0];
  } finally {
    conn.release();
  }
}

async function incrementCounter() {
  const conn = await pool.getConnection();
  try {
    await conn.execute('UPDATE hits SET hit_count = hit_count + 1 WHERE id = 1');
  } finally {
    conn.release();
  }
}

module.exports = { initializePool, initializeTables, initializeCounter, healthCheck, getHitData, incrementCounter };
EOF

cat > routes.js <<'EOF'
const express = require('express');
const db = require('./db');
const logger = require('./logger');
const router = express.Router();

router.get('/health', async (req, res) => {
  try {
    const isHealthy = await db.healthCheck();
    res.status(isHealthy ? 200 : 503).json({ status: isHealthy ? 'healthy' : 'unhealthy', db: 'mysql' });
  } catch (error) {
    res.status(503).json({ status: 'unhealthy', error: error.message });
  }
});

router.get('/', async (req, res) => {
  try {
    await db.incrementCounter();
    const hitData = await db.getHitData();
    res.status(200).send(`
      <!DOCTYPE html>
      <html>
        <head><meta charset="UTF-8"><meta name="viewport" content="width=device-width"><title>Hit Counter</title>
        <style>body{font-family:Arial;text-align:center;margin-top:50px;background:#f5f5f5}.container{background:#fff;padding:40px;border-radius:10px;width:400px;margin:0 auto;box-shadow:0 2px 10px rgba(0,0,0,.1)}.count{font-size:56px;font-weight:bold;color:#2563eb;margin:20px 0}.label{font-size:20px;color:#666}.timestamp{font-size:14px;color:#999;margin-top:30px}.status{background:#d1fae5;color:#065f46;padding:10px;border-radius:5px;margin-top:20px;font-size:12px}</style>
        </head><body><div class="container"><div class="label">Total Page Hits</div><div class="count">${hitData.hit_count}</div><div class="timestamp">Last hit: ${new Date(hitData.last_hit).toLocaleString()}</div><div class="status">✓ MySQL Connected</div></div></body>
      </html>
    `);
  } catch (error) {
    logger.error(`Error: ${error.message}`);
    res.status(500).send(`<html><body style="text-align:center;margin-top:50px"><h1>Error</h1><p>${error.message}</p></body></html>`);
  }
});

router.get('/api/hits', async (req, res) => {
  try {
    const hitData = await db.getHitData();
    res.json({ hits: hitData.hit_count, database: 'mysql' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
EOF

cat > server.js <<'EOF'
const express = require('express');
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

cat > index.js <<'EOF'
#!/usr/bin/env node
const { config, validateConfig } = require('./config');
const logger = require('./logger');
const db = require('./db');
const createServer = require('./server');

async function start() {
  try {
    logger.info('Starting Hit Counter Application');
    logger.info(`Database: ${config.database.endpoint}:${config.database.port}`);
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
    logger.error(`Fatal: ${error.message}`);
    process.exit(1);
  }
}
start();
EOF

cat > .env <<ENVEOF
DB_TYPE=mysql
DB_ENDPOINT=$DB_ENDPOINT
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_NAME=$DB_NAME
DB_PORT=$DB_PORT
APP_PORT=$APP_PORT
NODE_ENV=production
ENVEOF

echo "Installing dependencies..."
npm install --production

# ============================================
# CONFIGURE NGINX
# ============================================
cat > /etc/nginx/sites-available/default <<'NGINX_EOF'
server {
    listen 80 default_server;
    server_name _;
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
NGINX_EOF

nginx -t && systemctl reload nginx

# ============================================
# CREATE SYSTEMD SERVICE
# ============================================
cat > /etc/systemd/system/app.service <<SYSTEMD_EOF
[Unit]
Description=Hit Counter App
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=$APP_DIR
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
systemctl enable app
systemctl start app
systemctl restart nginx

sleep 5
echo "=== Deployment Complete ==="
echo "Application: http://<instance-ip>"
echo "Health: http://<instance-ip>/health"
echo "View logs: sudo journalctl -u app -f"
```

---

## ✅ Quick Checklist

Before you paste:

- [ ] You've chosen PostgreSQL or MySQL script
- [ ] You've edited DB_ENDPOINT (line 5)
- [ ] You've edited DB_USER (line 6)
- [ ] You've edited DB_PASSWORD (line 7)
- [ ] You've edited DB_NAME (line 8) - if not using "ha-tt-db"
- [ ] You've edited DB_PORT (line 9) - if different from default

After you paste:

- [ ] Checkbox in AWS is **UNCHECKED** (not base64)
- [ ] Script appears correctly (not garbled)
- [ ] Click "Create Launch Template"
- [ ] Launch instance from template
- [ ] Wait 5-10 minutes for startup
- [ ] Test at: `http://<public-ip>`

---

**You're ready to deploy! 🚀**
