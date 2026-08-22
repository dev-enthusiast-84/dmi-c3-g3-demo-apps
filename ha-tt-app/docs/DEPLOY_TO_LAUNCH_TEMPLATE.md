# Deploy to AWS Launch Template - Step by Step

Guide for adding the organized, modular application to EC2 Launch Template User Data field.

## ⚠️ PREREQUISITES - MUST HAVE BEFORE STARTING

**This deployment script launches EC2 instances. It does NOT create an RDS database server.**

### Required Before You Begin:

✅ **Existing RDS Instance (PostgreSQL or MySQL)**
- Instance must be running (check AWS RDS Console → "Available" status)
- Note the endpoint URL: `your-db.xxxxx.region.rds.amazonaws.com`
- Have master username: `postgres` (PostgreSQL) or `admin` (MySQL)
- Have master password: (the one you set during RDS creation)
- Database port: `5432` (PostgreSQL) or `3306` (MySQL)

✅ **Security Group Permissions**
- RDS security group: Allow inbound on DB port (5432/3306)
  - Source: EC2 security group (or 0.0.0.0/0)
- EC2 security group: Allow inbound on port 80 (HTTP)
  - Source: 0.0.0.0/0 (or your IP)

✅ **AWS Configuration**
- EC2 key pair exists (for SSH access to instances)
- VPC where RDS is running
- Permissions to create EC2 instances

### What Gets Created:
- ✅ NEW EC2 instance (Ubuntu 22.04)
- ✅ Application and web server on EC2
- ✅ NEW database in your existing RDS
- ✅ NEW table for application data

### What Does NOT Get Created:
- ❌ RDS instance (must pre-exist)
- ❌ Database server
- ❌ Master user credentials

### No RDS Yet?
1. Create RDS instance in AWS Console first
2. Wait for status to show "Available"
3. Get endpoint and credentials
4. Return here to deploy the application

---

## 📋 Three Deployment Options

### Option 1: Direct Paste (Recommended for Quick Setup)

**Use:** When you want to paste everything directly into AWS Console

**Steps:**

1. **Open AWS Console**
   - Go to EC2 → Launch Templates
   - Create new template or edit existing

2. **Configure Basic Settings**
   - Name: `web-app-template`
   - AMI: Ubuntu 22.04 LTS
   - Instance Type: `t3.micro`
   - Key Pair: Select your key pair
   - Security Group: Allow port 80 inbound

3. **Scroll to "Advanced Details"**
   - Find "User Data" section
   - Click in the text area

4. **Copy the Appropriate Script**

   **For PostgreSQL:**
   ```bash
   # Copy entire contents of: app-structure/userdata-modular.sh
   # Then change line 3 to:
   DB_TYPE="postgres"
   ```

   **For MySQL:**
   ```bash
   # Copy entire contents of: app-structure/userdata-modular.sh
   # Then change line 3 to:
   DB_TYPE="mysql"
   ```

5. **Edit Database Configuration**
   
   Before pasting, edit lines 4-9:
   ```bash
   DB_ENDPOINT="your-rds-endpoint.region.rds.amazonaws.com"
   DB_USER="postgres"  # or "admin" for MySQL
   DB_PASSWORD="your-secure-password"
   DB_NAME="ha-tt-db"
   DB_PORT="5432"      # or 3306 for MySQL
   ```

6. **Paste into User Data Field**
   - Select all (Ctrl+A)
   - Paste the script
   - Make sure ✓ box is unchecked (not base64 encoded)

7. **Create Launch Template**
   - Click "Create Launch Template"

8. **Launch Instance**
   - Select template → "Launch Instance from Template"
   - Wait 5-10 minutes
   - Access at: `http://<public-ip>`

---

### Option 2: GitHub Repository (Recommended for Teams)

**Use:** When code is in GitHub, no need to paste large scripts

**Steps:**

1. **Push app-structure to GitHub**
   ```bash
   git init
   git add app-structure/
   git commit -m "Add modular app"
   git push -u origin main
   ```

2. **Create Simple Deploy Script**

   In Launch Template User Data, paste this smaller script:

   ```bash
   #!/bin/bash
   set -e
   exec > >(tee /var/log/user-data.log)
   exec 2>&1

   echo "=== Installing Node.js ==="
   curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
   apt-get update && apt-get install -y nodejs nginx

   echo "=== Deploying Application from GitHub ==="
   APP_DIR="/opt/app"
   mkdir -p $APP_DIR
   cd $APP_DIR

   git clone https://github.com/YOUR-USERNAME/YOUR-REPO.git .
   cd app-structure

   echo "=== Creating Environment File ==="
   cat > .env <<'EOF'
   DB_TYPE=postgres
   DB_ENDPOINT=your-rds-endpoint.region.rds.amazonaws.com
   DB_USER=postgres
   DB_PASSWORD=your-password
   DB_NAME=ha-tt-db
   DB_PORT=5432
   APP_PORT=8000
   NODE_ENV=production
   EOF

   echo "=== Installing Dependencies ==="
   npm install --production

   echo "=== Starting Application ==="
   systemctl enable nginx
   systemctl start nginx

   cat > /etc/nginx/sites-available/default <<'NGINX_EOF'
   server {
       listen 80 default_server;
       server_name _;
       location / {
           proxy_pass http://127.0.0.1:8000;
           proxy_set_header Host $host;
       }
   }
   NGINX_EOF

   systemctl reload nginx

   cat > /etc/systemd/system/app.service <<'SYSTEMD_EOF'
   [Unit]
   Description=Node.js App
   After=network.target

   [Service]
   Type=simple
   User=ubuntu
   WorkingDirectory=/opt/app/app-structure
   EnvironmentFile=/opt/app/app-structure/.env
   ExecStart=/usr/bin/node index.js
   Restart=always

   [Install]
   WantedBy=multi-user.target
   SYSTEMD_EOF

   systemctl daemon-reload
   systemctl enable app
   systemctl start app

   echo "=== Deployment Complete ==="
   sleep 5
   systemctl status app
   ```

3. **Update GitHub URL**
   - Replace `YOUR-USERNAME/YOUR-REPO` with your repository

4. **Paste into Launch Template User Data**

5. **Deploy**
   - Create template
   - Launch instance
   - Access at: `http://<public-ip>`

**Advantages:**
- ✅ Small script (easy to paste)
- ✅ Always uses latest code from GitHub
- ✅ Easy to update code without changing template
- ✅ Team collaboration friendly

---

### Option 3: S3 Deployment (For Large Teams)

**Use:** When you want to store deployment script in S3

**Steps:**

1. **Upload to S3**
   ```bash
   aws s3 cp app-structure/userdata-modular.sh s3://your-bucket/scripts/
   ```

2. **Create IAM Role**
   - EC2 instance needs S3 read permission
   - Attach to instance profile

3. **Simple Launch Template User Data**

   ```bash
   #!/bin/bash
   set -e
   exec > >(tee /var/log/user-data.log)
   exec 2>&1

   echo "=== Downloading deployment script ==="
   aws s3 cp s3://your-bucket/scripts/userdata-modular.sh /tmp/
   chmod +x /tmp/userdata-modular.sh

   echo "=== Running deployment script ==="
   /tmp/userdata-modular.sh
   ```

4. **Paste into Launch Template**

5. **Deploy**

**Advantages:**
- ✅ Version control for scripts
- ✅ Easy to update scripts in S3
- ✅ Audit trail
- ✅ Backup capability

---

## 🎯 Quick Comparison

| Method | Size | GitHub | Complexity | Best For |
|--------|------|--------|-----------|----------|
| Direct Paste | Large | No | Simple | Quick tests, small teams |
| GitHub | Small | Yes | Medium | Production, teams |
| S3 | Small | Yes | Medium | Enterprise, version control |

---

## ✅ Step-by-Step: Direct Paste (Easiest)

### 1. Download the Script

From your ha-tt-app folder:
```bash
cat app-structure/userdata-modular.sh
```

### 2. Edit Configuration

Open in text editor and change these lines (3-9):
```bash
DB_TYPE="postgres"  # or "mysql"
DB_ENDPOINT="mydb.xxxxx.us-east-1.rds.amazonaws.com"
DB_USER="postgres"  # or "admin" for MySQL
DB_PASSWORD="your-secure-password"
DB_NAME="ha-tt-db"
DB_PORT="5432"  # or 3306 for MySQL
```

### 3. Open AWS Console

```
Services → EC2 → Launch Templates → Create Launch Template
```

### 4. Fill Basic Settings

```
Launch Template Name: web-app-template
AMI: Ubuntu 22.04 LTS (ami-xxxxxxxx)
Instance Type: t3.micro
Key Pair: (your key pair)
Security Groups: (allow port 80)
```

### 5. Scroll to Advanced Details

Find the "User Data" section (near bottom of form)

### 6. Copy & Paste Script

1. In text editor:
   - Select all (Ctrl+A)
   - Copy (Ctrl+C)

2. In AWS Console:
   - Click in User Data text area
   - Paste (Ctrl+V)
   - ✓ Checkbox should be UNCHECKED (not base64)

### 7. Create & Launch

```
Click: Create Launch Template
Select template → Launch Instance from Template
Select: 1 instance
Click: Launch Instances
```

### 8. Wait & Test

- Wait 5-10 minutes
- Get Public IP from EC2 console
- Open: `http://<public-ip>` in browser

---

## 🔧 Troubleshooting Launch Template Paste

### Script Doesn't Show Properly

**Problem:** Text appears garbled or incomplete

**Solution:**
1. Copy script again
2. Paste in plain text editor first (not Word)
3. Copy from plain text editor
4. Paste into AWS Console

### "User data has already been base64 encoded" Error

**Problem:** AWS is trying to encode already-encoded data

**Solution:**
1. Make sure ☐ checkbox is UNCHECKED
2. If checked, uncheck it
3. Paste again

### Character Limit Error

**Problem:** Script is too large for User Data field (max ~16 KB)

**Solution:**
- Use GitHub method (smaller script)
- Or use S3 method
- Or split script into smaller parts

### Script Runs But App Doesn't Start

**Problem:** No error in User Data, but app not responding

**Solution:**
1. SSH into instance:
   ```bash
   ssh -i keypair.pem ubuntu@<public-ip>
   ```

2. Check logs:
   ```bash
   sudo tail -100 /var/log/user-data.log
   sudo journalctl -u app -n 50
   ```

3. Check services:
   ```bash
   sudo systemctl status app
   sudo systemctl status nginx
   ```

---

## 📝 Pre-Launch Checklist

Before pasting script into Launch Template:

- [ ] Database endpoint is correct
- [ ] Database username is correct
- [ ] Database password is correct
- [ ] Database name is correct
- [ ] Database port is correct (5432 for PostgreSQL, 3306 for MySQL)
- [ ] Database type is set (postgres or mysql)
- [ ] EC2 key pair is selected
- [ ] Security group allows port 80
- [ ] User Data checkbox is UNCHECKED (not base64)

---

## 🚀 After Launch

1. **Wait for Status Checks**
   - Instance should show "2/2 checks passed"
   - Takes 5-10 minutes

2. **Get Public IP**
   - EC2 Console → Instances → Select your instance
   - Copy Public IP Address

3. **Test Application**
   ```bash
   curl http://<public-ip>
   curl http://<public-ip>/health
   curl http://<public-ip>/api/hits
   ```

4. **View Logs**
   ```bash
   ssh -i keypair.pem ubuntu@<public-ip>
   sudo journalctl -u app -f
   ```

---

## 📊 Expected Timing

| Phase | Duration | Status |
|-------|----------|--------|
| Instance launch | 1-2 min | Initializing |
| System updates | 2-3 min | Updating |
| Software install | 1-2 min | Installing |
| App startup | 1-2 min | Starting |
| Ready | 5-10 min total | **Ready** |

---

## 🎓 Which Method Should I Use?

### Use Direct Paste If:
- ✅ First time deploying
- ✅ Testing something
- ✅ Small project
- ✅ Want simplicity

### Use GitHub If:
- ✅ Team development
- ✅ Multiple deployments
- ✅ Need version control
- ✅ Want to update code easily

### Use S3 If:
- ✅ Enterprise environment
- ✅ Need audit trail
- ✅ Large organization
- ✅ Multiple regions

---

## 💡 Pro Tips

1. **Test Locally First**
   ```bash
   cd app-structure
   npm install
   npm start
   # Test at localhost:8000
   ```

2. **Use Comments in Script**
   - Makes it easier to understand later
   - Add dates for tracking changes

3. **Keep Old Templates**
   - Don't delete old launch templates
   - Use for rollback if needed

4. **Monitor Deployment**
   - Watch EC2 System Log while deploying
   - Check Application Logs after app starts

5. **Set Up Alarms**
   - After deployment, add CloudWatch alarms
   - Monitor CPU, network, errors

---

## 🆘 Need Help?

If something doesn't work:

1. **Check Logs**
   ```bash
   ssh -i keypair.pem ubuntu@<ip>
   sudo tail -200 /var/log/user-data.log
   ```

2. **Verify Configuration**
   ```bash
   cat /opt/app/.env
   ```

3. **Test Database**
   ```bash
   # PostgreSQL
   psql -h <endpoint> -U postgres -d ha-tt-db
   SELECT * FROM hits;
   
   # MySQL
   mysql -h <endpoint> -u admin -p ha-tt-db
   SELECT * FROM hits;
   ```

4. **Check Services**
   ```bash
   sudo systemctl status app
   sudo systemctl status nginx
   sudo nginx -t
   ```

---

**You're all set! Choose your preferred deployment method and follow the steps. Happy deploying!** 🚀
