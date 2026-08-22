# GitHub-Based Deployment Guide

**Recommended approach** - Deploy directly from GitHub repository with zero code duplication.

---

## 🎯 Overview

This guide shows how to deploy your Hit Counter app from GitHub to AWS EC2 in minutes.

**What makes this approach great:**
- ✅ No embedded code in deployment scripts
- ✅ Single source of truth (GitHub repo)
- ✅ Auto-updates with latest code from main branch
- ✅ Zero duplication across environments
- ✅ CI/CD ready

---

## 📋 Prerequisites

1. **GitHub Repository** - Your code in a public or private repo
2. **AWS Account** - EC2, RDS, VPC set up
3. **RDS Database** - PostgreSQL or MySQL running
4. **EC2 Keypair** - For SSH access
5. **Security Groups** - Port 80 (HTTP) and 5432/3306 (RDS)

---

## 🚀 Complete Deployment Steps (15 Steps)

### **STEP 1: Pre-Deployment Checklist** ✓

Before you start, verify you have:

```
[ ] RDS Instance
    - Endpoint: ha-tt-db.xxxxx.us-east-1.rds.amazonaws.com
    - Username: postgres
    - Password: (your secure password)
    - Status: RUNNING in AWS Console

[ ] EC2 Resources
    - Key pair downloaded (.pem file)
    - Security group created
    - Port 80 (HTTP) inbound allowed
    
[ ] GitHub Repository
    - Code pushed to main branch
    - Verified at: github.com/dev-enthusiast-84/dmi-c3-g3-demo-apps/tree/main/ha-tt-app
```

---

### **STEP 2: Generate Deployment Script** (5 minutes)

Navigate to your repository:
```bash
cd /path/to/ha-tt-app
```

Run the interactive generator:
```bash
./app-structure/config-generator.sh
```

You'll see this menu:
```
What would you like to generate?

  1) .env file (for local development)
  2) User data script (for EC2 deployment)
  3) Complete configuration package
  4) Environment variables only

  Q) Quit

Select option:
```

**Type: `2`** (User data script for EC2)

---

### **STEP 3: Answer Configuration Questions**

The script will ask for your database details. **Type each answer carefully:**

```
Database Type (postgres/mysql) [postgres]: 
↓ Press Enter (or type "postgres")

Database Endpoint (e.g., mydb.xxxxx.rds.amazonaws.com): 
↓ Type: ha-tt-db.cklo4cmkm5b6.us-east-1.rds.amazonaws.com

Database User (e.g., postgres/admin): 
↓ Press Enter (or type "postgres")

Database Password: 
↓ Type: your-secure-password (it won't show on screen)

Database Name [ha-tt-db]: 
↓ Press Enter (or type "ha-tt-db")

Database Port [5432]: 
↓ Press Enter (5432 is default for PostgreSQL)

Application Port [8000]: 
↓ Press Enter (8000 is good)

Application Directory [/opt/app]: 
↓ Press Enter (/opt/app is standard)
```

**Output:** Script generates to `generated/userdata-custom.sh`

---

### **STEP 4: Copy Script to Clipboard**

```bash
cat generated/userdata-custom.sh | pbcopy
```

**✓ Script is now on your clipboard**

---

### **STEP 5: Create Launch Template in AWS**

1. Open: https://console.aws.amazon.com
2. Go to: **EC2 → Launch Templates**
3. Click: **Create launch template**

---

### **STEP 6: Fill Launch Template Form**

| Field | Value |
|-------|-------|
| **Template name** | `hit-counter-template` |
| **Template description** | `Hit counter app with PostgreSQL` |
| **AMI** | Ubuntu 22.04 LTS (free tier eligible) |
| **Instance type** | t3.micro (free tier eligible) |
| **Key pair** | (Select your .pem key) |
| **Security group** | (Select your security group) |

---

### **STEP 7: Add User Data Script**

Scroll down to: **Advanced Details**

Click on: **User Data**

**Paste your script** (Cmd+V or Ctrl+V):
- You copied it in STEP 4
- It will show as a long script

---

### **STEP 8: Create Template**

Click: **Create launch template**

---

### **STEP 9: Launch Instance**

In the template details page:

Click: **Launch instance from template**

**Verify settings:**
- ✓ AMI: Ubuntu 22.04 LTS
- ✓ Instance type: t3.micro
- ✓ Key pair: Your key
- ✓ Security group: Your group
- ✓ User Data: Script pasted

Click: **Launch instance**

**✓ EC2 instance is starting**

---

### **STEP 10: Wait for Setup** (3-5 minutes)

Go to: **EC2 → Instances**

Watch your instance:
- Initially: **Pending** (starting)
- Then: **Running** (good!)
- Status checks: **Initializing** → **2/2 passed** (perfect!)

**⏱️ Wait 3-5 minutes for setup to complete**

---

### **STEP 11: Get Your Public IP**

Once instance is **Running** and **2/2 status checks passed**:

1. Click on your instance
2. Look for **Public IPv4 address**
3. Copy the IP (e.g., `54.123.45.67`)

---

### **STEP 12: Verify Deployment with SSH**

Open terminal and SSH into instance:

```bash
ssh -i /path/to/your-keypair.pem ubuntu@YOUR_PUBLIC_IP
```

**Replace `YOUR_PUBLIC_IP`** with your actual IP from STEP 11

**Example:**
```bash
ssh -i ~/Downloads/my-key.pem ubuntu@54.123.45.67
```

**First time will ask:**
```
The authenticity of host can't be established.
Are you sure you want to continue connecting? (yes/no/[fingerprint])
```

Type: `yes`

---

### **STEP 13: Monitor Setup Logs**

Once SSH connected, watch the deployment:

```bash
sudo tail -f /var/log/user-data.log
```

**You'll see:**
```
=== Section 1: System Setup ===
✓ System setup complete

=== Section 2: Application Deployment ===
Cloning application from GitHub...
✓ Application cloned from GitHub
✓ Application deployment complete

=== Section 3: Nginx Configuration ===
✓ Nginx configuration complete

=== Section 4: Service Setup ===
✓ Service setup complete

=== Section 5: Starting Services ===
✓ Application service is running
✓ Nginx is running

=== EC2 Setup Complete ===
Application will be available at: http://54.123.45.67
```

**Wait until you see "EC2 Setup Complete"**

Press: `Ctrl+C` to stop watching logs

---

### **STEP 14: Check Application Status**

Still in SSH terminal:

```bash
sudo systemctl status app
```

Should show:
```
● app.service - Hit Counter Web Application
     Loaded: loaded
     Active: active (running)
```

✓ **App is running!**

---

### **STEP 15: Test Application**

Exit SSH:
```bash
exit
```

Open browser and go to:
```
http://YOUR_PUBLIC_IP
```

**You should see:**
- ✅ "Total Page Hits" heading
- ✅ Hit counter number
- ✅ Last hit timestamp
- ✅ "Connected to postgres" status
- ✅ Reset Counter button (red)

**Test features:**
- Refresh page → counter increments
- Click Reset → confirmation + counter resets
- Test health: `curl http://YOUR_PUBLIC_IP/health`

**You should see the **hit counter** displaying! 🎉**

---

## 🔄 Deployment Workflow

### **After Code Updates**

Update code in GitHub:
```bash
git add .
git commit -m "Add feature X"
git push origin main
```

Deploy new instance:
1. Launch new EC2 from template
2. Script auto-clones latest code from `main` branch
3. App runs with newest features ✨

---

## 🌿 Using Different Branches

To deploy from a different branch:

1. Edit `generated/userdata-custom.sh`:
```bash
GITHUB_BRANCH="develop"  # or "feature/my-feature"
```

2. Use this script for launch

Script will clone from that branch!

---

## 🔐 GitHub Private Repository

If your repo is private:

### **Option A: Personal Access Token (Recommended)**

1. **GitHub** → Settings → Developer settings → Personal access tokens
2. Create token with `repo` scope
3. Update script:
```bash
GITHUB_REPO="https://YOUR_TOKEN@github.com/dev-enthusiast-84/dmi-c3-g3-demo-apps.git"
```

### **Option B: SSH Key**

1. Add EC2 instance key to GitHub (Settings → Deploy keys)
2. Update script:
```bash
GITHUB_REPO="git@github.com:dev-enthusiast-84/dmi-c3-g3-demo-apps.git"
```

---

## 📊 What Gets Deployed

Script clones and deploys:
```
ha-tt-app/app-structure/
├── config.js          (Configuration)
├── db.js              (Database operations)
├── index.js           (App entry point)
├── server.js          (Express server)
├── routes.js          (API routes)
├── package.json       (Dependencies)
└── (all other files)
```

---

## 🐛 Troubleshooting

### **GitHub Clone Failed**

Check logs:
```bash
sudo tail -100 /var/log/user-data.log | grep -i "git\|clone\|github"
```

**Solutions:**
- Verify repo is public OR token/SSH key configured
- Check branch name exists
- Verify path `ha-tt-app/app-structure` is correct

### **App Won't Start**

SSH to instance:
```bash
sudo systemctl status app
sudo journalctl -u app -n 50
```

Common issues:
- Database not initialized → Check RDS is running
- Environment variables missing → Check .env file
- Port 8000 in use → Check other apps

### **Cannot Reach Application**

1. Verify public IP is correct
2. Check security group allows port 80 inbound
3. Test locally: `curl http://localhost` (SSH into instance)
4. Check Nginx: `sudo systemctl status nginx`

---

## 🔄 Update Frequency

### **Development (Dev Branch)**
```bash
GITHUB_BRANCH="develop"
```
Deploy frequently from dev branch for testing

### **Production (Main Branch)**
```bash
GITHUB_BRANCH="main"
```
Deploy from main after testing

### **Feature Branches**
```bash
GITHUB_BRANCH="feature/reset-counter"
```
Deploy feature for review/testing

---

## 📈 Scaling Pattern

For multiple environments:

```bash
# Create launch templates for each
- Production Template (GITHUB_BRANCH="main")
- Staging Template (GITHUB_BRANCH="develop")
- Testing Template (GITHUB_BRANCH="feature/X")

# Launch instances as needed
# All pull latest code from their configured branch
```

---

## ✨ Benefits of This Approach

| Aspect | Before | After |
|--------|--------|-------|
| Code duplication | 2 copies (modular + embedded) | 1 copy (GitHub only) |
| Deployment time | Setup + manual code | Auto-clone + ready |
| Branch management | Single script | Branch-specific configs |
| Team collaboration | Limited | Full Git workflow |
| CI/CD ready | No | Yes |
| Update process | Manual | Git push → new instance |

---

## 🚀 Next Steps

1. **Commit to GitHub** - Push your code
2. **Generate script** - Run config-generator.sh
3. **Launch instance** - Paste userdata in AWS
4. **Monitor logs** - Watch deployment progress
5. **Test application** - Open in browser
6. **Update workflow** - Git push triggers new deployments

---

## 📚 Related Documentation

- **HOW_TO_CHECK_LOGS.md** - Monitor and troubleshoot
- **SECURE_LOCAL_DEPLOYMENT.md** - Security best practices
- **SECURE_CREDENTIAL_FLOW.md** - How credentials work

---

**This is the recommended deployment method for production use!** 🎯
