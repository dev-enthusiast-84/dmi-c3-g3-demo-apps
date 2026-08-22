# Step-by-Step Deployment Guide

Complete walkthrough to deploy the application to AWS.

> **Quick Start:** For fastest setup, use the Automated Script method in `SECURE_LOCAL_DEPLOYMENT.md`

---

## Phase 1: Pre-Deployment Checklist

### ✅ AWS Account Prerequisites

Before starting, ensure you have:

```
[ ] AWS Account with permissions for:
    [ ] EC2 (create instances, security groups)
    [ ] RDS (database instance access)
    [ ] VPC (network configuration)

[ ] RDS Database Instance:
    [ ] Instance created and RUNNING
    [ ] Status shows "Available" (not "creating" or "backing up")
    [ ] Database type: PostgreSQL or MySQL
    [ ] Endpoint URL noted (e.g., mydb.xxxxx.us-east-1.rds.amazonaws.com)
    [ ] Master username noted (e.g., postgres or admin)
    [ ] Master password saved securely

[ ] EC2 Infrastructure:
    [ ] EC2 Key Pair created
    [ ] Security Group created with:
        [ ] Inbound: HTTP (port 80) from 0.0.0.0/0
        [ ] Inbound: SSH (port 22) from your IP (for debugging)
        [ ] Outbound: All traffic (or at least database port)

[ ] RDS Security Configuration:
    [ ] RDS Security Group allows inbound on database port:
        [ ] PostgreSQL: port 5432
        [ ] MySQL: port 3306
    [ ] Source: EC2 security group OR 0.0.0.0/0
    [ ] RDS and EC2 in same VPC or properly networked

[ ] Network Configuration:
    [ ] EC2 and RDS can communicate
    [ ] Both in same VPC (simplest) or configured for cross-VPC
```

### ✅ Information to Gather

Open a text editor and save these values:

```
Database Type:        [ ] postgres  [ ] mysql
Database Endpoint:    _________________________________________
Database Port:        _________________________________________
Database Username:    _________________________________________
Database Password:    _________________________________________
Database Name:        _________________________________________
                      (default: ha-tt-db)

EC2 Key Pair Name:    _________________________________________
EC2 Security Group:   _________________________________________
AWS Region:           _________________________________________
                      (e.g., us-east-1, us-west-2)
```

---

## Phase 2: Prepare the User Data Script

### Step 1: Get the Script

The script is located at:
```
/Users/maneettaantony/Workspaces/DMI-C3-G3/dmi-c3-g3-demo-apps/ha-tt-app/app-structure/userdata-ec2-only.sh
```

### Step 2: Open and Edit Configuration

Open the script and find these lines (around line 16-27):

```bash
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
```

### Step 3: Update with Your Values

Edit ONLY these 6 lines:

```bash
# CHANGE THESE BASED ON YOUR DATABASE:

DB_TYPE="postgres"                                    # or "mysql"
DB_ENDPOINT="mydb.xxxxx.us-east-1.rds.amazonaws.com"  # Your RDS endpoint
DB_USER="postgres"                                    # or "admin" for MySQL
DB_PASSWORD="YourSecurePassword123!"                  # Your RDS password
DB_NAME="ha-tt-db"                                    # Database name
DB_PORT="5432"                                        # 5432 for postgres, 3306 for mysql

# LEAVE THESE UNCHANGED:
APP_PORT=8000
APP_DIR="/opt/app"
```

**Example for PostgreSQL:**
```bash
DB_TYPE="postgres"
DB_ENDPOINT="mydb.cp6cq4cisdiw.us-east-1.rds.amazonaws.com"
DB_USER="postgres"
DB_PASSWORD="MySecurePass123!"
DB_NAME="ha-tt-db"
DB_PORT="5432"
```

**Example for MySQL:**
```bash
DB_TYPE="mysql"
DB_ENDPOINT="mydb.xxxxx.us-east-1.rds.amazonaws.com"
DB_USER="admin"
DB_PASSWORD="MySecurePass123!"
DB_NAME="ha-tt-db"
DB_PORT="3306"
```

### Step 4: Copy the Entire Script

Select all content (Ctrl+A or Cmd+A) and copy to clipboard.

---

## Phase 3: Create AWS Launch Template

### Step 1: Go to EC2 Console

1. Log in to AWS Console
2. Go to **EC2 Dashboard**
3. In left menu, click **Launch Templates**

### Step 2: Create Launch Template

1. Click **Create Launch Template**
2. Fill in the form:

**Basic Details:**
```
Launch template name:           web-app-template
Template version description:   v1 - Hit Counter App
```

**Application and OS Image:**
```
AMI: Search for "Ubuntu"
Select: Ubuntu Server 22.04 LTS (or 24.04 LTS)
Keep: x86 architecture
```

**Instance Type:**
```
Instance type: t3.micro (free tier eligible)
```

**Key Pair:**
```
Key pair name: Select your existing key pair
(If you don't have one, create one and save the .pem file)
```

**Network Settings:**
```
Security groups: Select your security group
(Must allow inbound HTTP port 80)
```

**Advanced Details:**

Scroll down to find **User Data** field and:

1. Click in the User Data text box
2. Paste the entire edited script (all lines)
3. Make sure all content is there

**Example:**
```
#!/bin/bash
# ============================================
# EC2 User Data Script - Web Server Setup
# ============================================
[... rest of script ...]
```

### Step 3: Create the Template

1. Scroll down to bottom
2. Click **Create Launch Template**
3. Confirm creation message appears

---

## Phase 4: Launch EC2 Instance

### Step 1: Go to Instances

1. In EC2 Dashboard, click **Instances** (left menu)
2. Click **Launch Instances**
3. Click **Launch from Template**

### Step 2: Select Your Template

1. Find your template: `web-app-template`
2. Click to select it
3. Click **Launch Instance from Template**

### Step 3: Configure Instance

Keep defaults, but verify:
```
[ ] Number of instances: 1
[ ] Instance type: t3.micro
[ ] Key pair: Your key pair selected
[ ] Security group: Your group selected
[ ] VPC: Same as RDS (or configured for access)
```

### Step 4: Launch

1. Click **Launch Instance**
2. Confirmation page appears with instance ID
3. Click on instance ID to view details

---

## Phase 5: Wait for Initialization

### Step 1: Monitor Instance

In the EC2 Instances list:

1. Find your instance (should show "Running")
2. Check **Status Checks** column:
   ```
   Initializing...     (wait)
   1/2 checks passed  (still running user data)
   2/2 checks passed  (ready!)
   ```

3. **Time to wait:** 5-10 minutes for full initialization

### Step 2: Get Public IP

Once instance is running:
1. Copy the **Public IPv4 address** (e.g., 54.123.45.67)
2. Save it for testing

### Step 3: Verify in User Data Logs

SSH into instance to verify setup:

```bash
ssh -i /path/to/keypair.pem ubuntu@<PUBLIC_IP>

# View user data initialization logs
sudo tail -f /var/log/user-data.log

# Should show something like:
# === EC2 User Data Script - Web Server Setup ===
# Configuration:
#   Database Type: postgres
#   Database Endpoint: mydb.xxxxx.rds.amazonaws.com
# === Section 1: System Setup ===
# Updating system packages...
# Installing Node.js 20.x...
# Installing Nginx...
# === Section 2: Application Deployment ===
# Creating application directory: /opt/app
# Deploying application code...
# Installing npm dependencies...
# [... more output ...]
# === EC2 Setup Complete ===
```

---

## Phase 6: Test the Application

### ✅ Test 1: Basic HTTP Request

Open your browser or run:

```bash
curl http://<PUBLIC_IP>
```

**Expected Response:**
```html
<!DOCTYPE html>
<html>
  <head>
    <title>Hit Counter</title>
    ...
  </head>
  <body>
    <div class="container">
      <div class="label">Total Page Hits</div>
      <div class="count">0</div>
      <div class="timestamp">Last hit: 8/21/2026, 3:45:30 PM</div>
      <div class="status">✓ Connected to postgres</div>
    </div>
  </body>
</html>
```

**If successful:** ✅ Nginx is serving traffic from Node.js

### ✅ Test 2: Health Check Endpoint

```bash
curl http://<PUBLIC_IP>/health
```

**Expected Response:**
```json
{"status":"healthy","db":"postgres"}
```

**If successful:** ✅ Application is running and database connected

### ✅ Test 3: Hit Counter Increment

Refresh page in browser or:

```bash
# First hit
curl http://<PUBLIC_IP> | grep -oP 'count">\K[^<]+'

# Wait 1 second
sleep 1

# Second hit (should be 1 instead of 0)
curl http://<PUBLIC_IP> | grep -oP 'count">\K[^<]+'
```

**If counter increments:** ✅ Database read/write working

### ✅ Test 4: Verify Services Running

SSH into instance:

```bash
ssh -i /path/to/keypair.pem ubuntu@<PUBLIC_IP>

# Check Node.js app
sudo systemctl status app

# Should show: active (running)

# Check Nginx
sudo systemctl status nginx

# Should show: active (running)

# View app logs
sudo journalctl -u app -n 20

# Should show:
# PostgreSQL pool created
# Hits table ready
# Hit counter ready
# Application listening on port 8000
```

---

## Phase 7: Verify Database Connectivity

### SSH Into Instance

```bash
ssh -i /path/to/keypair.pem ubuntu@<PUBLIC_IP>
```

### Check .env Configuration

```bash
cat /opt/app/.env

# Should output:
# DB_TYPE=postgres
# DB_ENDPOINT=mydb.xxxxx.rds.amazonaws.com
# DB_USER=postgres
# DB_PASSWORD=YourPassword
# DB_NAME=ha-tt-db
# DB_PORT=5432
# APP_PORT=8000
# NODE_ENV=production
```

### Check Nginx Configuration

```bash
sudo nginx -t

# Should output:
# nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
# nginx: configuration file /etc/nginx/nginx.conf test is successful
```

### Check Database Connection (Optional)

```bash
# For PostgreSQL:
psql -h <DB_ENDPOINT> -U postgres -d ha-tt-db -c "SELECT COUNT(*) FROM hits;"

# For MySQL:
mysql -h <DB_ENDPOINT> -u admin -p ha-tt-db -e "SELECT COUNT(*) FROM hits;"

# Should return: 1 row with count of hits
```

---

## Phase 8: Troubleshooting

### Issue: Port 80 Not Responding

**Check:**
```bash
# SSH into instance
curl http://localhost/health

# If this works but public IP doesn't:
# → Check EC2 security group allows inbound port 80

# If localhost also fails:
sudo systemctl status nginx
sudo nginx -t
sudo journalctl -u nginx -n 20
```

**Fix:**
1. Go to EC2 Console → Security Groups
2. Select your security group
3. Verify Inbound rule allows HTTP (port 80)
4. Restart instance if needed

### Issue: Database Connection Error

**Check:**
```bash
# SSH into instance
sudo journalctl -u app | grep -i database

# Look for connection errors
```

**Verify:**
1. RDS instance is RUNNING (not stopped)
2. RDS endpoint is correct in .env
3. RDS username/password are correct
4. RDS security group allows inbound from EC2 on database port
5. EC2 security group allows outbound to RDS port

### Issue: Application Won't Start

**Check:**
```bash
# SSH into instance
sudo journalctl -u app -n 50

# Look for errors in application startup
sudo tail -100 /var/log/user-data.log
```

**Common causes:**
- Database connection fails → Check credentials
- npm install failed → Check disk space: `df -h`
- Port already in use → Check if changed APP_PORT
- Permission denied → Check file ownership: `ls -la /opt/app`

### Issue: High CPU/Memory Usage

**Solution:**
1. Go to EC2 Console
2. Stop instance
3. Change Instance Type to t3.small or larger
4. Start instance again

---

## Phase 9: Production Checklist

Before considering this production-ready:

```
[ ] Application responds on port 80
[ ] Health check endpoint returns {"status":"healthy"}
[ ] Hit counter increments on page refresh
[ ] Database records persist after page refresh
[ ] Services restart after EC2 reboot
[ ] Nginx logs show HTTP requests
[ ] Application logs show no errors
[ ] Security groups configured correctly
[ ] RDS database encrypted (optional but recommended)
[ ] CloudWatch alarms set up (optional)
[ ] Regular backups configured (optional)
```

---

## Phase 10: Next Steps

### 🚀 Scale to Multiple Instances

1. Save this Launch Template
2. Create Auto Scaling Group with 2-3 instances
3. Add Application Load Balancer in front
4. All instances use same user data script

### 🔍 Monitor in Production

```bash
# SSH into instance and monitor:
sudo journalctl -u app -f  # Follow app logs
sudo journalctl -u nginx -f  # Follow nginx logs
curl http://<ip>/health  # Health check
```

### 🔄 Deploy Updates

1. Modify application code in userdata script
2. Create new Launch Template version
3. Terminate old instance
4. Launch new instance with updated template

### 📊 Add Monitoring

```bash
# SSH into instance
sudo apt-get install -y cloudwatch-agent
# Configure CloudWatch agent to send logs
```

---

## Quick Reference

### Command Cheat Sheet

```bash
# Connect to instance
ssh -i keypair.pem ubuntu@<PUBLIC_IP>

# View user data logs
sudo tail -f /var/log/user-data.log

# View application logs
sudo journalctl -u app -f

# View Nginx logs
sudo journalctl -u nginx -f

# Check services running
sudo systemctl status app
sudo systemctl status nginx

# View application configuration
cat /opt/app/.env

# Test health endpoint
curl http://localhost/health

# Check database from app directory
cd /opt/app && node -e "console.log(require('dotenv').config())"
```

### Important Files on EC2

```
/opt/app/                     # Application directory
├── index.js                  # Application code
├── package.json              # Dependencies
├── node_modules/             # Installed packages
└── .env                       # Configuration (DB credentials)

/etc/nginx/sites-available/default  # Nginx config
/etc/systemd/system/app.service     # Systemd service file
/var/log/user-data.log              # Initialization log
```

---

## 💡 Recommended: Use SECURE_LOCAL_DEPLOYMENT.md

This guide uses manual steps. For a **faster, easier approach**, use the **Automated Script Method**:

📖 See: `SECURE_LOCAL_DEPLOYMENT.md` → **Method 2: Automated Script**

It does Steps 2-3 automatically and is more secure.

---

## Summary

| Phase | What | Time | Key Action |
|-------|------|------|-----------|
| 1 | Pre-flight checks | 5 min | Gather AWS info |
| 2 | Edit script | 2 min | Update 6 config lines |
| 3 | Create template | 3 min | Paste script in user data |
| 4 | Launch instance | 1 min | Click launch |
| 5 | Wait & initialize | 10 min | Monitor status checks |
| 6 | Test application | 2 min | Access via browser |
| 7 | Verify database | 2 min | Check connectivity |
| 8 | Troubleshoot | varies | If issues occur |
| 9 | Production check | 5 min | Verify all systems |
| 10 | Next steps | varies | Scale or monitor |

**Total Time (Manual):** 30-40 minutes  
**Total Time (Automated):** 15-20 minutes ⭐

> **Recommendation:** Use the Automated Script method from `SECURE_LOCAL_DEPLOYMENT.md` for fastest, easiest deployment.

---

## Success Criteria

✅ **You're done when:**
1. Instance shows "2/2 status checks passed"
2. `http://<PUBLIC_IP>` displays hit counter
3. Refreshing page increments counter
4. Health endpoint returns `{"status":"healthy"}`
5. Logs show no errors

🎉 **Congratulations!** Your application is running on AWS!

---

For more information:
- Full guide: `docs/EC2_ONLY_DEPLOYMENT.md`
- Quick reference: `SCRIPTS_QUICK_REFERENCE.md`
- Architecture: `docs/ARCHITECTURE.md`
