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

## 🚀 Deployment Steps

### **Step 1: Generate Deployment Script**

```bash
cd /path/to/ha-tt-app
./app-structure/config-generator.sh
```

**Select:** Option 2 (User data script)

**Answer prompts:**
```
Database Type: postgres
Database Endpoint: ha-tt-db.xxxxx.rds.amazonaws.com
Database User: postgres
Database Password: your-secure-password
Database Name: ha-tt-db
Database Port: 5432
Application Port: 8000
Application Directory: /opt/app
```

✅ Script generated: `generated/userdata-custom.sh`

---

### **Step 2: Review GitHub Configuration**

The script includes GitHub settings:
```bash
GITHUB_REPO="https://github.com/dev-enthusiast-84/dmi-c3-g3-demo-apps.git"
GITHUB_BRANCH="main"
GITHUB_APP_PATH="ha-tt-app/app-structure"
```

**To use different branch/repo, edit:**
```bash
nano generated/userdata-custom.sh
# Find and update GITHUB_REPO, GITHUB_BRANCH, GITHUB_APP_PATH
```

---

### **Step 3: Copy Script to Clipboard**

```bash
cat generated/userdata-custom.sh | pbcopy
```

---

### **Step 4: Launch EC2 Instance**

1. **AWS Console** → EC2 → Launch Templates
2. **Create Launch Template:**
   - AMI: Ubuntu 22.04 LTS
   - Instance Type: t3.micro
   - Key Pair: Your keypair
   - Security Groups: (allow port 80, 5432/3306 for RDS)
3. **Advanced Details** → **User Data**
4. **Paste** the script (Cmd+V or Ctrl+V)
5. **Create** template
6. **Launch** instance from template

---

### **Step 5: Wait for Setup**

Instance setup takes **2-3 minutes**:
- System updates
- Git clone from GitHub
- Node.js dependencies
- Database initialization
- Service startup

Monitor progress:
```bash
# SSH into instance
ssh -i your-keypair.pem ubuntu@<PUBLIC_IP>

# Watch logs
sudo tail -f /var/log/user-data.log
```

---

### **Step 6: Test Application**

```bash
# Get public IP from AWS Console

# Test in browser
http://<PUBLIC_IP>

# Test health check
curl http://<PUBLIC_IP>/health

# Test API
curl http://<PUBLIC_IP>/api/hits
```

You should see the **hit counter** displaying! 🎉

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
