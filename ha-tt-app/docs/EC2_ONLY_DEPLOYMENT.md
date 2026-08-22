# EC2-Only Deployment Guide

**Status:** ✅ Production Ready | **Scope:** EC2 Instance Setup Only

---

## Overview

The refactored deployment solution uses an **EC2-only user data script** that focuses exclusively on instance bootstrapping. All database initialization logic has been **separated into independent scripts** that can be run independently.

### Architecture Principle: Separation of Concerns

```
┌─────────────────────────────────────┐
│  Infrastructure Setup (Your RDS)    │ ← Run once before EC2
│  database-init.sh                   │   (Optional - app can auto-create)
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│  EC2 Instance Bootstrap             │ ← User Data Script
│  userdata-ec2-only.sh               │   (Runs on EC2 launch)
│  - Install Node.js                  │
│  - Install Nginx                    │
│  - Deploy application               │
│  - Configure environment            │
│  - Start services                   │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│  Application (Running on EC2)       │ ← Handles DB operations
│  Connects to existing RDS instance  │
│  Auto-creates tables if needed      │
└─────────────────────────────────────┘
```

---

## Scripts Included

### 1. **userdata-ec2-only.sh** (Main Deployment Script)
**Purpose:** EC2 instance setup only  
**Time:** 5-10 minutes  
**Scope:** System updates, Node.js, Nginx, application deployment, service startup

**What it does:**
✅ Update system packages  
✅ Install Node.js 20.x  
✅ Install Nginx web server  
✅ Deploy application code (embedded)  
✅ Configure environment variables  
✅ Create systemd service  
✅ Start services on port 80  

**What it does NOT do:**
❌ Create RDS database  
❌ Create databases or tables  
❌ Modify database infrastructure  
❌ Require existing databases  

**Usage:**
```bash
# Copy entire script content into AWS Launch Template → User Data
# Edit configuration variables:
DB_TYPE="postgres"              # or "mysql"
DB_ENDPOINT="your-endpoint"
DB_USER="postgres"
DB_PASSWORD="your-password"
DB_NAME="ha-tt-db"
```

---

### 2. **database-init.sh** (Optional Database Setup)
**Purpose:** Pre-initialize database and tables on existing RDS  
**Time:** 1-2 minutes  
**Scope:** Runs on your local machine or management instance

**What it does:**
✅ Connect to existing RDS instance  
✅ Create database if it doesn't exist  
✅ Create `hits` table with proper schema  
✅ Insert initial counter record  

**What it does NOT do:**
❌ Create RDS instance itself  
❌ Modify instance configuration  

**Usage:**
```bash
# Make executable
chmod +x database-init.sh

# Run before EC2 deployment (optional)
./database-init.sh postgres mydb.xxxxx.rds.amazonaws.com postgres password ha-tt-db

# or for MySQL
./database-init.sh mysql mydb.xxxxx.rds.amazonaws.com admin password ha-tt-db
```

**Note:** This is completely optional. The application will auto-create tables on first startup.

---

### 3. **config-generator.sh** (Configuration Helper)
**Purpose:** Generate configuration files and customized user data scripts  
**Time:** 2-3 minutes  
**Scope:** Interactive configuration tool

**What it does:**
✅ Interactive prompts for database configuration  
✅ Generate `.env` files  
✅ Generate customized user data scripts  
✅ Export environment variables  
✅ Create complete configuration packages  

**Usage:**
```bash
# Make executable
chmod +x config-generator.sh

# Run interactively
./config-generator.sh

# Follow prompts and choose:
# 1) .env file (for local development)
# 2) User data script (for EC2)
# 3) Complete package (both)
# 4) Environment variables only

# Output goes to ./generated/ directory
ls -la generated/
```

---

## Deployment Flow

### Option A: Minimal (Application Auto-Creates Database)

**Time:** 5-10 minutes total  
**Prerequisites:** EC2 key pair, security groups configured, RDS instance running

1. **Configure user data script:**
   - Edit 5 configuration lines in `userdata-ec2-only.sh`:
     ```bash
     DB_TYPE="postgres"
     DB_ENDPOINT="your-endpoint"
     DB_USER="postgres"
     DB_PASSWORD="your-password"
     DB_NAME="ha-tt-db"
     ```

2. **Create AWS Launch Template:**
   - AMI: Ubuntu 22.04 LTS
   - Instance Type: t3.micro
   - User Data: Copy entire `userdata-ec2-only.sh`

3. **Launch instance:**
   - Instance initializes in 5-10 minutes
   - Application auto-creates database and tables on first run

4. **Access application:**
   - `http://<public-ip>`

---

### Option B: Pre-Initialize Database

**Time:** 5-10 minutes EC2 + 1-2 minutes DB setup  
**Prerequisites:** EC2 key pair, security groups, RDS instance, database client tools

1. **Pre-initialize database (on your local machine):**
   ```bash
   ./database-init.sh postgres mydb.xxxxx.rds.amazonaws.com postgres password ha-tt-db
   ```

2. **Configure user data script:**
   - Same as Option A

3. **Create launch template and launch instance:**
   - Same as Option A

4. **Access application:**
   - `http://<public-ip>`
   - Database and tables already exist (faster startup)

---

### Option C: Generate Custom Configuration

**Time:** 5-10 minutes  
**Benefits:** Interactive setup, reusable configuration

1. **Generate configuration:**
   ```bash
   ./config-generator.sh
   
   # Select: 3) Complete configuration package
   # Answer prompts with your database details
   ```

2. **Review generated files:**
   ```bash
   ls -la generated/
   # - userdata-custom.sh
   # - .env
   # - env-vars.sh
   ```

3. **Use generated user data script:**
   - Copy `generated/userdata-custom.sh` to AWS Launch Template
   - Launch instance

---

## File Locations

```
app-structure/
├── userdata-ec2-only.sh        ← Main EC2 deployment script
├── database-init.sh             ← Optional database initialization
├── config-generator.sh          ← Configuration helper tool
├── package.json                 ← Application dependencies
├── index.js                     ← Application code (embedded in userdata)
└── .env.example                 ← Configuration template
```

---

## Application Initialization Flow

```
EC2 Instance Starts
    ↓
userdata-ec2-only.sh executes
    ├── Update system packages
    ├── Install Node.js & Nginx
    ├── Deploy application code
    ├── Create .env configuration
    ├── Install npm dependencies
    ├── Configure Nginx reverse proxy
    ├── Create systemd service
    └── Start services
    ↓
Node.js Application Starts
    ├── Connect to RDS (via environment variables)
    ├── Create 'hits' table if it doesn't exist
    ├── Initialize counter record if empty
    └── Listen on port 8000
    ↓
Nginx Reverse Proxy
    └── Forward port 80 → port 8000
    ↓
Application Ready
    └── http://<instance-ip>
```

---

## Configuration Options

### Environment Variables

The application reads these from `.env` file or environment:

| Variable | Purpose | Default |
|----------|---------|---------|
| `DB_TYPE` | PostgreSQL or MySQL | postgres |
| `DB_ENDPOINT` | RDS endpoint URL | localhost |
| `DB_USER` | Database username | postgres |
| `DB_PASSWORD` | Database password | (required) |
| `DB_NAME` | Database name | ha-tt-db |
| `DB_PORT` | Database port | 5432 (postgres) or 3306 (mysql) |
| `APP_PORT` | Application port | 8000 |
| `NODE_ENV` | Environment (production/development) | production |

### Database Configuration

#### PostgreSQL
```bash
DB_TYPE=postgres
DB_ENDPOINT=mydb.xxxxx.rds.amazonaws.com
DB_USER=postgres
DB_PASSWORD=secure-password
DB_NAME=ha-tt-db
DB_PORT=5432
```

#### MySQL
```bash
DB_TYPE=mysql
DB_ENDPOINT=mydb.xxxxx.rds.amazonaws.com
DB_USER=admin
DB_PASSWORD=secure-password
DB_NAME=ha-tt-db
DB_PORT=3306
```

---

## Verification & Testing

### Health Check Endpoint
```bash
curl http://<instance-ip>/health

# Expected response:
# {"status":"healthy","db":"postgres"}
```

### Test Main Application
```bash
# First access
curl http://<instance-ip>

# Should display:
# - Total Page Hits: 0
# - Connected to postgres/mysql

# Refresh to increment counter
curl http://<instance-ip>
# Should now show: 1
```

### Check Logs

**SSH into instance:**
```bash
ssh -i keypair.pem ubuntu@<instance-ip>
```

**View application logs:**
```bash
sudo journalctl -u app -f

# Expected output:
# PostgreSQL pool created
# Hits table ready
# Hit counter ready
# Application listening on port 8000
```

**View user data initialization logs:**
```bash
sudo tail -f /var/log/user-data.log

# Shows all installation steps and their status
```

**Check service status:**
```bash
sudo systemctl status app
sudo systemctl status nginx
```

---

## Troubleshooting

### Application won't start
```bash
# SSH into instance and check logs
sudo journalctl -u app -n 50

# Common issues:
# 1. Database connection error → Check security groups
# 2. Port already in use → Change APP_PORT
# 3. npm install failed → Check disk space
```

### Database connection error
```bash
# Verify security groups allow:
# 1. EC2 outbound to RDS port (5432/3306)
# 2. RDS inbound from EC2

# Test connection manually
psql -h <db-endpoint> -U <user> -d <database>
# or for MySQL:
mysql -h <db-endpoint> -u <user> -p
```

### Port 80 not responding
```bash
# Check Nginx
sudo nginx -t
sudo systemctl restart nginx
sudo netstat -tlnp | grep nginx

# Check security group allows inbound 80
```

### High initialization time (>10 minutes)
```bash
# Check if stuck on npm install
ps aux | grep npm

# Check disk space
df -h

# Check system logs
sudo tail -f /var/log/syslog
```

---

## Advantages of EC2-Only Approach

✅ **Clear Responsibility:** Script only sets up EC2, not external services  
✅ **Modular:** Separate scripts for each concern  
✅ **Reusable:** Can use same script for multiple instances  
✅ **Flexible:** Work with existing RDS or auto-initialize  
✅ **Faster Updates:** Deploy new versions without RDS changes  
✅ **Scalable:** Same script works for single instance to auto-scaling groups  
✅ **Safe:** No risk of modifying existing database infrastructure  

---

## Scaling to Production

### Single Instance (Current)
- 1x t3.micro EC2 + RDS db.t3.micro
- Capacity: ~100 requests/second
- Cost: ~$20/month

### Multi-Instance (Recommended)
1. Create AMI from working instance
2. Launch Auto Scaling Group with same user data
3. Add Application Load Balancer (ALB)
4. Configure RDS Multi-AZ
5. Enable CloudWatch monitoring

**No changes to user data script needed!** Same `userdata-ec2-only.sh` works for all instances.

---

## Next Steps

1. **Test Locally:**
   ```bash
   cd app-structure
   npm install
   npm start
   ```

2. **Generate Configuration:**
   ```bash
   ./config-generator.sh
   # Choose option 3 for complete package
   ```

3. **Deploy to AWS:**
   - Create Launch Template with user data
   - Launch instance
   - Access at `http://<public-ip>`

4. **Monitor & Scale:**
   - Set up CloudWatch alarms
   - Enable auto-scaling when needed
   - Add load balancer for multiple instances

---

## Reference

- **Main Script:** `app-structure/userdata-ec2-only.sh`
- **Database Init:** `app-structure/database-init.sh`
- **Config Generator:** `app-structure/config-generator.sh`
- **Application Code:** `app-structure/index.js`
- **Dependencies:** `app-structure/package.json`

For more details on the application architecture, see `docs/ARCHITECTURE.md`.
