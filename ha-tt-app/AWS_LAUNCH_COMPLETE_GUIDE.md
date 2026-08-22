# Complete AWS Launch Guide: Template to Running Instance

**End-to-end guide: Generate UserData → Create Launch Template → Deploy to AWS**

---

## 📋 Table of Contents

1. [Part 1: Generate UserData Script](#part-1-generate-userdata-script-on-your-machine)
2. [Part 2: Create AWS Launch Template](#part-2-paste-into-aws-launch-template)
3. [Part 3: Launch Instance](#part-3-launch-an-instance-from-template)
4. [Part 4: Monitor Initialization](#part-4-monitor-initialization)
5. [Part 5: Test Application](#part-5-test-the-application)
6. [Success Checklist](#-success-checklist)
7. [Cleanup](#-optional-cleanup-after-deployment)
8. [Troubleshooting](#-troubleshooting-quick-reference)

---

# **PART 1: Generate UserData Script (On Your Machine)**

## Step 1.1: Navigate to Repository

Open terminal and go to your repository:

```bash
# Navigate to repository
cd /path/to/ha-tt-app

# Verify location
pwd
# Should output: /path/to/ha-tt-app

# List files to confirm
ls -la | grep deploy-config.sh.template
# Should show: deploy-config.sh.template
```

## Step 1.2: Copy the Template

Create your local configuration file:

```bash
# Copy template to create local config
cp deploy-config.sh.template deploy-config.sh

# Verify it was created
ls -la deploy-config.sh
# Should show: deploy-config.sh (not .template)

# Verify .gitignore is working
git check-ignore -v deploy-config.sh
# Should output: .gitignore:44: deploy-config.sh
```

**✅ File created locally, won't be committed to git**

## Step 1.3: Edit with Your RDS Credentials

Open the file in text editor:

```bash
nano deploy-config.sh
```

You'll see the configuration section:

```bash
# ============================================
# CONFIGURATION: EDIT THESE VALUES
# ============================================

DB_TYPE="postgres"
DB_ENDPOINT="your-rds-endpoint.rds.amazonaws.com"
DB_USER="your-rds-username"
DB_PASSWORD="your-rds-password"
DB_PORT="5432"
```

### For PostgreSQL Deployment:

Replace with your actual RDS values:

```bash
DB_TYPE="postgres"
DB_ENDPOINT="mydb.cp6cq4cisdiw.us-east-1.rds.amazonaws.com"
DB_USER="postgres"
DB_PASSWORD="MySecurePassword123!"
DB_PORT="5432"
```

**Find your values in AWS:**
- **Endpoint:** RDS Console → Databases → Your DB → Endpoint
- **Username:** What you set (usually `postgres`)
- **Password:** What you set during RDS creation
- **Port:** Should be 5432 for PostgreSQL

### For MySQL Deployment:

```bash
DB_TYPE="mysql"
DB_ENDPOINT="mydb.xxxxx.us-east-1.rds.amazonaws.com"
DB_USER="admin"
DB_PASSWORD="MySecurePassword123!"
DB_PORT="3306"
```

**Save the file:**
- Press `Ctrl+X`
- Press `Y` (Yes)
- Press `Enter` (confirm)

## Step 1.4: Verify Security (Check Not in Git)

```bash
# Check git status
git status

# Expected output:
# On branch main
# nothing to commit, working tree clean

# Your deploy-config.sh should NOT appear
# (It's automatically gitignored)
```

## Step 1.5: Generate the Deployment Script

Run the generator:

```bash
bash deploy-config.sh
```

**Expected output:**
```
Using base script: ./app-structure/userdata-ec2-only.sh

✅ Deployment script generated successfully!

📍 Location: ~/userdata-READY.sh

Next steps:
1. Copy to clipboard:     cat ~/userdata-READY.sh | pbcopy
2. AWS Console:           EC2 → Launch Templates → Create
3. User Data field:       Paste script
4. Launch instance:       Click Launch
```

**✅ Script generated at: `~/userdata-READY.sh`**

## Step 1.6: Copy Script to Clipboard

### On macOS:
```bash
cat ~/userdata-READY.sh | pbcopy
```

### On Linux:
```bash
cat ~/userdata-READY.sh | xclip -selection clipboard
```

### On Windows (Git Bash):
```bash
cat ~/userdata-READY.sh | clip
```

**✅ Script is now in clipboard, ready to paste**

### Verify Before Pasting (Optional):

```bash
# View first 30 lines
head -30 ~/userdata-READY.sh

# Should show YOUR actual values, not placeholders:
# DB_TYPE="postgres"
# DB_ENDPOINT="mydb.xxxxx.rds.amazonaws.com"  # Your actual endpoint
# DB_USER="postgres"
# DB_PASSWORD="YourActualPassword"            # Your actual password
```

---

# **PART 2: Paste Into AWS Launch Template**

## Step 2.1: Log Into AWS Console

1. Open browser: https://console.aws.amazon.com/
2. Sign in with your AWS credentials
3. Verify you're in correct **Region** (top right corner)
   - Should match where your RDS instance is
   - Example regions: `us-east-1`, `us-west-2`, `eu-west-1`

## Step 2.2: Navigate to EC2 Service

1. In AWS Console top search bar, type: **EC2**
2. Click **EC2** from search results
3. You're now in EC2 Dashboard

## Step 2.3: Navigate to Launch Templates

1. In left sidebar menu, scroll down
2. Under **Instances** section, click **Launch Templates**
3. Click **Create Launch Template** button (top right, blue)

## Step 2.4: Fill Basic Information

On the **Create Launch Template** form:

```
Launch template name:           web-app-template
Template version description:   v1 - Hit Counter App
Description (optional):         Node.js/Express web server with database
```

**Fields:**
- **Name:** Enter `web-app-template`
- **Description:** Enter the version description above
- Leave other optional fields blank

## Step 2.5: Select AMI (Operating System)

Find **Application and OS Images** section:

1. Click **Browse more AMIs** button
2. In search box, type: `Ubuntu 22.04 LTS`
3. Look for official Ubuntu AMI:
   ```
   Ubuntu Server 22.04 LTS (HVM), SSD Volume Type
   Publisher: Canonical
   AMI ID: ami-0c55b159cbfafe1f0 (varies by region)
   ```
4. Click **Select** button on the right

**✅ AMI selected**

## Step 2.6: Choose Instance Type

Find **Instance Type** section:

1. In the dropdown, select or search for: `t3.micro`
2. Make sure it shows:
   ```
   t3.micro - 1 vCPU, 1 GB Memory (Free tier eligible)
   ```

**✅ Instance type selected**

## Step 2.7: Select or Create Key Pair

Find **Key Pair (login)** section:

1. In dropdown, select your EC2 key pair
   - This is your `.pem` file for SSH access
   - If you don't have one, click **Create new key pair**

**If creating new:**
- Name it: `my-ec2-key`
- Type: RSA
- Format: .pem
- Click **Create key pair**
- Save the downloaded file: `my-ec2-key.pem`
- Keep it safe!

**✅ Key pair selected**

## Step 2.8: Configure Security Group

Find **Network settings** section:

### Option A: Use Existing Security Group

1. Under **Security groups**, select existing one
2. Verify it allows:
   - ✅ HTTP (Port 80) from 0.0.0.0/0
   - ✅ SSH (Port 22) from your IP

### Option B: Create New Security Group

1. Click **Create security group**
2. Name: `web-app-sg`
3. Description: `Security group for web app`
4. Add inbound rules:

**Inbound Rule 1 - HTTP:**
```
Type:      HTTP
Protocol:  TCP
Port:      80
Source:    0.0.0.0/0 (Anywhere)
```

**Inbound Rule 2 - SSH (for debugging):**
```
Type:      SSH
Protocol:  TCP
Port:      22
Source:    Your IP or 0.0.0.0/0
```

**Outbound Rules:** Keep default (allow all)

**✅ Security group configured**

## Step 2.9: **CRITICAL - Paste UserData Script**

This is the most important step!

1. Scroll down to **Advanced Details** section
2. Click the arrow to **Expand Advanced Details**
3. Find **User Data** field (large text box)
4. Click in the text box
5. **Paste your script:** `Cmd+V` (Mac) or `Ctrl+V` (Windows/Linux)

**Expected result:**
```bash
#!/bin/bash
# ============================================
# EC2 User Data Script - Web Server Setup
# ============================================
# PURPOSE: Set up EC2 instance with Node.js + Nginx
# SCOPE: EC2 instance setup ONLY

set -e
exec > >(tee /var/log/user-data.log)

# ... rest of script ...
```

**Verify script content:**
- ✅ Starts with `#!/bin/bash`
- ✅ Contains your DB endpoint (not placeholder)
- ✅ Contains your DB username
- ✅ Contains your DB password
- ✅ Contains your DB port
- ✅ Length > 300 lines (should be substantial)

## Step 2.10: Final Review - Before Creating

Check all fields are correct:

```
✅ Launch template name: web-app-template
✅ AMI: Ubuntu 22.04 LTS (ami-0c55b15...)
✅ Instance type: t3.micro
✅ Key pair: Your key pair selected
✅ Security group: Allows port 80 & 22
✅ User Data: Script pasted (NOT empty, NOT placeholder)
```

## Step 2.11: Create Launch Template

1. Scroll to bottom of form
2. Click **Create Launch Template** button (blue)
3. Wait for page to load
4. You should see confirmation:
   ```
   Successfully created launch template
   web-app-template
   ```

**✅ Launch Template created successfully**

---

# **PART 3: Launch an Instance from Template**

## Step 3.1: Navigate to Instances

After template creation, you have two options:

### Option A: From Confirmation Page
- Click **View Launch Template** or **Launch Instance from Template**

### Option B: From EC2 Dashboard
1. EC2 Dashboard → **Instances** (left menu)
2. Click **Launch Instances** button
3. Click **Launch from Template** tab
4. Select **web-app-template**

## Step 3.2: Review Instance Details

On the launch page, verify pre-filled fields:

```
Number of instances:      1
Instance type:            t3.micro (from template)
Key pair:                 Your key pair (from template)
Security group:           Your SG (from template)
Network:                  Auto-filled
User Data:                ✅ Included in template
```

**All should be pre-filled from template. No changes needed.**

## Step 3.3: Launch the Instance

1. Click **Launch Instance** button (orange/red, bottom right)
2. Wait for launch page
3. You should see success message:
   ```
   Successfully initiated launch of instance
   i-0abc123def456ghi
   ```

**✅ Instance is launching**

## Step 3.4: Go to Instances Dashboard

1. Click **View All Instances** button
2. Or: EC2 → **Instances** (left menu)
3. You should see your new instance at top of list

---

# **PART 4: Monitor Initialization**

## Step 4.1: Find Your Instance

In EC2 **Instances** page:

1. Look at the top of the list
2. Your instance ID starts with `i-` (most recent)
3. Note the **Instance ID**:
   ```
   Example: i-0abc123def456ghi
   ```

## Step 4.2: Monitor Status

The instance shows multiple columns:

```
Instance ID          State       Status Checks      Public IPv4
i-0abc123def456ghi   running     Initializing...    54.123.45.67
```

**Status progression:**

| Status | Meaning | Time |
|--------|---------|------|
| `Initializing...` | Instance booting | 1-2 min |
| `1/2 checks passed` | EC2 running, user data executing | 3-8 min |
| `2/2 checks passed` | **Ready!** All systems online | 5-10 min total |

**⏳ Wait for: `2/2 checks passed` ✅**

This takes **5-10 minutes** - be patient!

## Step 4.3: Monitor User Data Execution (Optional)

If you want to see what's happening:

1. Click your instance ID
2. Click **Details** tab
3. Scroll down to **System Log**
4. Click **View System Log**
5. Should show installation progress:
   ```
   === EC2 User Data Script - Web Server Setup ===
   === Section 1: System Setup ===
   Updating system packages...
   Installing Node.js 20.x...
   Installing Nginx...
   === Section 2: Application Deployment ===
   ... more output ...
   ✅ EC2 Setup Complete
   ```

## Step 4.4: Get Your Public IP Address

Once status is `2/2 checks passed`:

1. In the Instances list, find your instance
2. Copy the **Public IPv4 address** column
   - Example: `54.123.45.67`
3. **Save this IP** - you need it to access the application

---

# **PART 5: Test the Application**

## Step 5.1: Test Main Application Page

Once you have the Public IP:

**Note:** When EC2 user data completes, it automatically displays the IP address in the completion message. Look for:
```
=== EC2 Setup Complete ===
Application will be available at: http://54.123.45.67
```

### Via Terminal:

```bash
# Use the IP from user data completion message
PUBLIC_IP="54.123.45.67"

# Test main page
curl http://$PUBLIC_IP

# Should return HTML with hit counter (status 0)
```

### Via Browser:

1. Open browser
2. Go to: `http://54.123.45.67` (use your IP from completion message)
3. You should see:
   ```
   Total Page Hits
   0
   Last hit: 8/21/2026 3:45:30 PM
   ✓ Connected to postgres
   ```

**✅ Application is responding**

## Step 5.2: Test Health Check Endpoint

Terminal:
```bash
curl http://54.123.45.67/health

# Should return:
# {"status":"healthy","db":"postgres"}
```

**✅ Database connection is working**

## Step 5.3: Test Hit Counter (Read/Write)

### In Browser:

1. Go to: `http://54.123.45.67`
2. You should see hit count: `0`
3. Refresh page (Cmd+R or Ctrl+R)
4. Hit count should now show: `1`
5. Refresh again: `2`
6. Refresh again: `3`

Each increment = database write operation successful

**✅ Database read/write is working**

### Via Terminal:

```bash
# Get current count
curl http://54.123.45.67 | grep -oP 'count">\K[^<]+'
# Output: 0

# Wait a second
sleep 1

# Get new count (after refresh)
curl http://54.123.45.67 | grep -oP 'count">\K[^<]+'
# Output: 1
```

## Step 5.4: Verify Logs (Optional)

If you want to verify everything is working:

```bash
# SSH into instance
ssh -i /path/to/keypair.pem ubuntu@54.123.45.67

# View application logs
sudo journalctl -u app -n 20

# Should show:
# PostgreSQL pool created
# Hits table ready
# Hit counter ready
# Application listening on port 8000
```

---

# **✅ Success Checklist**

Once you see all these, you're done! 🎉

```
☑ Instance status: 2/2 checks passed
☑ Public IPv4 address available (e.g., 54.123.45.67)
☑ Browser: http://<IP> shows "Total Page Hits: 0"
☑ Refresh page: Counter increments to 1
☑ Refresh page: Counter increments to 2
☑ curl http://<IP>/health returns {"status":"healthy"}
☑ Logs show: "Application listening on port 8000"
☑ Security group allows inbound port 80
☑ RDS instance still running and accessible
```

**All checkmarks = Successful deployment! ✅**

---

# **🧹 Optional: Cleanup (After Deployment)**

## Delete Local Deployment Files

After your instance is running, you can delete:

```bash
# Delete generated script
rm ~/userdata-READY.sh

# Delete local config
rm deploy-config.sh

# Git status should show clean
git status
# Output: nothing to commit, working tree clean
```

## Keep Template File in Git

The `.template` file stays in git for future use:

```bash
# This stays in git (safe - no secrets)
git ls-files | grep template
# Output: deploy-config.sh.template
```

---

# **🚨 Troubleshooting Quick Reference**

## Port 80 Not Responding

### Problem:
```
curl http://54.123.45.67
curl: (7) Failed to connect to 54.123.45.67 port 80
```

### Solutions:

**1. Wait Longer**
- User data is still running
- Wait 10 minutes from launch
- Check status: should be `2/2 checks passed`

**2. Check Security Group**
```bash
# In AWS Console:
# EC2 → Security Groups → Your Group
# Verify inbound rule:
# Type: HTTP, Port: 80, Source: 0.0.0.0/0
```

**3. Check Nginx**
```bash
ssh -i keypair.pem ubuntu@54.123.45.67

# Check nginx status
sudo systemctl status nginx

# Restart nginx
sudo systemctl restart nginx

# Check Nginx logs
sudo tail -50 /var/log/nginx/error.log
```

## Database Connection Error

### Problem:
```
curl http://54.123.45.67/health
{"status":"unhealthy","error":"connection failed"}
```

### Solutions:

**1. Verify RDS is Running**
- AWS Console → RDS → Databases
- Your database should show status: `Available`

**2. Verify Credentials**
```bash
# SSH into EC2
ssh -i keypair.pem ubuntu@54.123.45.67

# Check configured credentials
cat /opt/app/.env

# Verify values match your RDS
```

**3. Check Security Groups**
- EC2 security group: allow outbound on DB port (5432/3306)
- RDS security group: allow inbound from EC2 SG on DB port

**4. Test Connection**
```bash
ssh -i keypair.pem ubuntu@54.123.45.67

# For PostgreSQL:
psql -h <your-rds-endpoint> -U postgres -d ha-tt-db -c "SELECT 1"

# For MySQL:
mysql -h <your-rds-endpoint> -u admin -p ha-tt-db -e "SELECT 1"
```

## Application Won't Start

### Problem:
```bash
curl http://54.123.45.67
Connection refused
```

### Solutions:

```bash
# SSH into instance
ssh -i keypair.pem ubuntu@54.123.45.67

# Check app status
sudo systemctl status app

# View app logs
sudo journalctl -u app -n 50

# View user data logs
sudo tail -100 /var/log/user-data.log

# Check if port 8000 is listening
sudo netstat -tlnp | grep 8000
```

## SSH Connection Refused

### Problem:
```bash
ssh -i keypair.pem ubuntu@54.123.45.67
Permission denied
```

### Solutions:

**1. Verify Key Pair**
```bash
# Check key exists
ls -la ~/keypair.pem

# Fix permissions if needed
chmod 400 ~/keypair.pem
```

**2. Verify Instance Running**
- AWS Console → Instances
- Status should show: `Running`
- Not: `Stopped`, `Terminating`, etc.

**3. Wait for Ready**
- Instance might still be initializing
- Wait 3-5 minutes

**4. Use Session Manager (Alternative)**
- AWS Console → EC2 Instances
- Select instance → Connect → Session Manager

---

# **📞 Getting Help**

If you encounter issues:

1. **Check logs first:**
   ```bash
   # User data logs
   sudo tail -f /var/log/user-data.log
   
   # Application logs
   sudo journalctl -u app -f
   ```

2. **Check AWS Console:**
   - Instance status and status checks
   - Security groups inbound/outbound rules
   - RDS database status

3. **Review documentation:**
   - `SECURE_LOCAL_DEPLOYMENT.md` - Deployment steps
   - `docs/EC2_ONLY_DEPLOYMENT.md` - Architecture
   - `TEMPLATE_AND_GIT_GUIDE.md` - Git safety

---

# **📋 Command Quick Reference**

### Generate & Deploy:
```bash
# 1. Generate script
cd /path/to/ha-tt-app
cp deploy-config.sh.template deploy-config.sh
nano deploy-config.sh                    # Edit with your values
bash deploy-config.sh                    # Generate

# 2. Copy to clipboard
cat ~/userdata-READY.sh | pbcopy

# 3. AWS Console (manual steps in Part 2)

# 4. Test
curl http://54.123.45.67
curl http://54.123.45.67/health

# 5. Cleanup
rm ~/userdata-READY.sh deploy-config.sh
```

### Access Instance:
```bash
# SSH access
ssh -i /path/to/keypair.pem ubuntu@54.123.45.67

# View logs
sudo journalctl -u app -f
sudo tail -f /var/log/user-data.log

# Check services
sudo systemctl status app
sudo systemctl status nginx
```

---

**Ready to deploy?** Start with **Part 1, Step 1.1** above! 🚀

Last updated: 2026-08-21
