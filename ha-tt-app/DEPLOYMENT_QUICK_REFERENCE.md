# Deployment Quick Reference

**Quick lookup for common deployment scenarios.**

---

## 📋 Checklist Before Deployment

```
[ ] RDS instance created and running
[ ] RDS endpoint: _________________________________
[ ] RDS username: postgres or admin
[ ] RDS password: (save securely)
[ ] EC2 security group allows port 80
[ ] EC2 security group allows RDS access (5432/3306)
[ ] EC2 key pair downloaded (.pem file)
[ ] GitHub repository ready (public or private)
```

---

## 🚀 Deployment Commands (Copy & Paste)

### **1. Generate Deployment Script**
```bash
cd /path/to/ha-tt-app
./app-structure/config-generator.sh
```

### **2. Follow Prompts**
```
Select option: 2
Database Type: postgres (or mysql)
Database Endpoint: ha-tt-db.xxxxx.rds.amazonaws.com
Database User: postgres (or admin)
Database Password: ••••••••••
Database Name: ha-tt-db
Database Port: 5432 (or 3306)
Application Port: 8000
Application Directory: /opt/app
```

### **3. Copy Generated Script**
```bash
cat generated/userdata-custom.sh | pbcopy
```

### **4. AWS Console Steps**
1. EC2 → Launch Templates
2. Create Launch Template
3. Name: `hit-counter-template`
4. AMI: `Ubuntu 22.04 LTS`
5. Instance type: `t3.micro`
6. Key pair: (your key)
7. Security groups: (your groups)
8. Advanced Details → User Data
9. **Paste script**
10. Create → Launch instance

### **5. Test Application**
```bash
# Get PUBLIC IP from AWS Console

# Test main page
curl http://<PUBLIC_IP>

# Test health check
curl http://<PUBLIC_IP>/health

# Test API
curl http://<PUBLIC_IP>/api/hits

# Or open in browser
http://<PUBLIC_IP>
```

---

## 🔍 Verify Deployment

### **SSH into Instance**
```bash
ssh -i your-keypair.pem ubuntu@<PUBLIC_IP>
```

### **Check Setup Progress**
```bash
# Watch user data logs
sudo tail -f /var/log/user-data.log

# Check app status
sudo systemctl status app

# Check app logs
sudo journalctl -u app -f

# Test locally
curl http://localhost:8000
```

### **Verify GitHub Clone**
```bash
# Check if code was cloned from GitHub
ls -la /opt/app/

# Should show:
# config.js
# db.js
# index.js
# routes.js
# server.js
# package.json
# node_modules/
# .env
```

---

## 🐛 Quick Troubleshooting

| Problem | Solution |
|---------|----------|
| **"This site can't be reached"** | Check security group allows port 80 |
| **App not running** | `sudo systemctl status app` - check logs |
| **Database connection error** | Verify RDS endpoint, credentials, security group |
| **GitHub clone failed** | Repo URL wrong or branch doesn't exist |
| **No node_modules** | `cd /opt/app && npm install --production` |
| **Port 8000 already in use** | Change APP_PORT in userdata script |

---

## 📊 Deployment Time

| Step | Time |
|------|------|
| Generate script | 2 min |
| AWS console setup | 3 min |
| Instance launch | 1 min |
| EC2 initialization | 3-5 min |
| GitHub clone | 1-2 min |
| **Total** | **10-15 min** |

---

## 🔄 Update Workflow

### **After Code Changes**

1. **Commit & Push to GitHub**
```bash
git add .
git commit -m "Your changes"
git push origin main
```

2. **Deploy New Instance**
   - Terminate old instance
   - Launch new from template
   - Script clones latest code

3. **Verify New Deployment**
```bash
curl http://<NEW_IP>/health
```

---

## 🌿 Using Different Branches

Edit `generated/userdata-custom.sh`:
```bash
GITHUB_BRANCH="develop"  # Or "feature/xyz"
```

Deploy with that branch!

---

## 🔐 Credentials Security

### **In Your Generated Script**
```bash
DB_TYPE="postgres"
DB_ENDPOINT="ha-tt-db.xxxxx.rds.amazonaws.com"
DB_USER="postgres"
DB_PASSWORD="YOUR_PASSWORD"           # ⚠️ Visible in userdata
DB_NAME="ha-tt-db"
```

### **Security Best Practices**
1. ✅ Generate script locally (not in AWS)
2. ✅ Review script before pasting
3. ✅ Delete local copy after pasting to AWS
4. ✅ Never commit generated scripts to git
5. ✅ Use strong passwords for RDS
6. ✅ Rotate passwords regularly

---

## 📈 Multiple Environments

### **Create Separate Templates**

**Production** (main branch)
```bash
GITHUB_BRANCH="main"
# Generate script for prod
```

**Staging** (develop branch)
```bash
GITHUB_BRANCH="develop"
# Generate script for staging
```

**Testing** (feature branch)
```bash
GITHUB_BRANCH="feature/xyz"
# Generate script for testing
```

Launch different instances from different templates!

---

## 💡 Pro Tips

1. **Save template after launch** - Don't delete after creating instance
2. **Tag instances** - Add Name tag for easy identification
3. **Monitor logs** - First 5 minutes shows if something fails
4. **Test health endpoint** - Good quick sanity check
5. **Keep old instances** - Easy rollback if something goes wrong

---

## 📚 Full Guides

| Guide | Purpose |
|-------|---------|
| `GITHUB_DEPLOYMENT_GUIDE.md` | Complete GitHub deployment |
| `HOW_TO_CHECK_LOGS.md` | Monitoring & troubleshooting |
| `SECURE_LOCAL_DEPLOYMENT.md` | Security best practices |
| `SECURE_CREDENTIAL_FLOW.md` | How credentials work |

---

## ⚡ One-Liner Deployment (After Setup)

```bash
# Generate + Copy + (Paste in AWS) = Done!
./app-structure/config-generator.sh && cat generated/userdata-custom.sh | pbcopy
```

Then paste in AWS Launch Template → Launch → Wait 5 min → Access app! 🚀

---

**Ready to deploy?** Start with: `./app-structure/config-generator.sh`
