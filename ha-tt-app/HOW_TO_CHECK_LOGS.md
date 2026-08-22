# How to Check Logs

Complete guide to monitoring and troubleshooting your EC2 instance and application logs.

---

## 📋 **Quick Start: SSH Into Your Instance**

```bash
ssh -i your-keypair.pem ubuntu@YOUR_PUBLIC_IP
```

---

## 🔍 **Log Files & Commands**

### **1. User Data Script Logs** (Setup Process)

The user data script runs when the EC2 instance first starts. Check these logs to see if installation completed successfully.

**Watch setup progress in real-time:**
```bash
sudo tail -f /var/log/user-data.log
```

**View entire setup log:**
```bash
sudo cat /var/log/user-data.log
```

**Check last 100 lines:**
```bash
sudo tail -100 /var/log/user-data.log
```

**Look for specific errors:**
```bash
sudo grep -i "error\|failed\|✗" /var/log/user-data.log
```

**What to look for:**
- ✓ Section 1: System Setup complete
- ✓ Section 2: Application deployment complete
- ✓ Section 3: Nginx configuration complete
- ✓ Section 3.5: Database initialization complete
- ✓ Section 4: Service setup complete
- ✓ Section 5: Application service is running

---

### **2. Application Service Logs** (Most Important!)

These logs show what your Node.js application is doing.

**Watch live logs (BEST FOR TROUBLESHOOTING):**
```bash
sudo journalctl -u app -f
```

**Last 50 lines:**
```bash
sudo journalctl -u app -n 50
```

**Last 100 lines:**
```bash
sudo journalctl -u app -n 100
```

**Search for specific message:**
```bash
sudo journalctl -u app | grep -i "connection\|database\|error"
```

**Show logs since last boot:**
```bash
sudo journalctl -u app -b
```

**Show logs for last 1 hour:**
```bash
sudo journalctl -u app --since "1 hour ago"
```

**What to look for:**
- ✓ Configuration validated
- ✓ PostgreSQL pool created
- ✓ Hits table initialized
- ✓ Database initialized
- ✓ Server listening on port 8000
- ✓ Application ready

---

### **3. Service Status**

**Check if app is running:**
```bash
sudo systemctl status app
```

**Check Nginx:**
```bash
sudo systemctl status nginx
```

**Restart the app:**
```bash
sudo systemctl restart app
```

**Restart Nginx:**
```bash
sudo systemctl restart nginx
```

**View service file:**
```bash
cat /etc/systemd/system/app.service
```

---

### **4. Nginx Logs**

Nginx handles incoming HTTP requests and proxies them to your app.

**Nginx error log:**
```bash
sudo tail -f /var/log/nginx/error.log
```

**Nginx access log:**
```bash
sudo tail -f /var/log/nginx/access.log
```

**Check Nginx config:**
```bash
sudo nginx -t
```

---

### **5. System Logs**

**All system logs:**
```bash
sudo journalctl -f
```

**Kernel messages:**
```bash
sudo dmesg | tail -20
```

---

## 🔍 **Common Diagnostic Checks**

### **Check if database connection works:**
```bash
sudo journalctl -u app -n 50 | grep -i "database\|connection\|postgres"
```

Expected output:
```
PostgreSQL pool created
Hits table initialized
Database initialized
```

### **Check if app started successfully:**
```bash
sudo journalctl -u app -n 20 | grep -i "listening\|ready\|application"
```

Expected output:
```
Server listening on port 8000
Application ready at http://localhost:8000
Health check available at http://localhost:8000/health
```

### **Check for SSL errors:**
```bash
sudo journalctl -u app | grep -i "ssl\|encryption\|certificate"
```

### **Check for database initialization errors:**
```bash
sudo cat /var/log/user-data.log | grep -A 10 "Database Initialization"
```

### **Check if environment variables loaded:**
```bash
sudo systemctl show-environment | grep DB_
```

Expected output:
```
DB_TYPE=postgres
DB_ENDPOINT=ha-tt-db.xxxxxx.rds.amazonaws.com
DB_USER=postgres
DB_NAME=ha-tt-db
DB_PORT=5432
```

---

## 📊 **Complete Diagnostic Check**

Run this single command to see everything at once:

```bash
echo "=== USER DATA LOG ===" && \
sudo tail -50 /var/log/user-data.log && \
echo -e "\n=== APP SERVICE STATUS ===" && \
sudo systemctl status app && \
echo -e "\n=== APP LOGS (LAST 30 LINES) ===" && \
sudo journalctl -u app -n 30 && \
echo -e "\n=== NGINX STATUS ===" && \
sudo systemctl status nginx
```

---

## 🚀 **First-Time Setup: What to Check**

After launching EC2, wait **2-3 minutes** for user data to complete, then:

### **Step 1: Check user data completed**
```bash
sudo tail /var/log/user-data.log | grep -i "complete\|ready"
```

### **Step 2: Check app is running**
```bash
sudo systemctl status app
```

### **Step 3: Check app logs**
```bash
sudo journalctl -u app -n 30
```

### **Step 4: Test the app locally**
```bash
curl http://localhost:8000
```

### **Step 5: Test health endpoint**
```bash
curl http://localhost:8000/health
```

---

## ⚠️ **Troubleshooting: App Fails to Start**

### **1. Check detailed error:**
```bash
sudo journalctl -u app -n 100
```

### **2. If it's a database connection error:**
```bash
sudo journalctl -u app | grep -i "connection\|database\|pg_hba\|ssl"
```

Common issues:
- `FATAL: database "ha-tt-db" does not exist` → Database not initialized
- `no pg_hba.conf entry` → SSL configuration issue
- `connection refused` → RDS not reachable (security group issue)

### **3. Check if database-init ran:**
```bash
sudo grep -i "database initialization" /var/log/user-data.log
```

### **4. Restart and watch logs:**
```bash
sudo systemctl restart app
sudo journalctl -u app -f
```

### **5. Check Nginx:**
```bash
sudo systemctl status nginx
sudo tail -20 /var/log/nginx/error.log
```

### **6. Check environment variables are loaded:**
```bash
sudo systemctl show-environment | grep DB_
```

---

## 🌐 **From Your Local Machine (No SSH Required)**

Test the application without SSH:

### **Test main page:**
```bash
curl http://YOUR_PUBLIC_IP
```

### **Test health endpoint:**
```bash
curl http://YOUR_PUBLIC_IP/health
```

### **Test API:**
```bash
curl http://YOUR_PUBLIC_IP/api/hits
```

### **Verbose output (see headers):**
```bash
curl -v http://YOUR_PUBLIC_IP
```

### **Check response code:**
```bash
curl -w "%{http_code}" http://YOUR_PUBLIC_IP
```

---

## 📈 **Monitoring in Real-Time**

### **Watch app logs live:**
```bash
sudo journalctl -u app -f
```

### **Watch all system logs:**
```bash
sudo journalctl -f
```

### **Watch Nginx access logs:**
```bash
sudo tail -f /var/log/nginx/access.log
```

### **Watch Nginx errors:**
```bash
sudo tail -f /var/log/nginx/error.log
```

---

## 💾 **Saving Logs for Analysis**

### **Save user data log:**
```bash
sudo cat /var/log/user-data.log > userdata.log
```

### **Save app logs:**
```bash
sudo journalctl -u app > app.log
```

### **Save all logs:**
```bash
sudo journalctl -u app > app.log && \
sudo cat /var/log/user-data.log > userdata.log && \
sudo tail -100 /var/log/nginx/error.log > nginx-error.log
```

Then download locally:
```bash
scp -i your-keypair.pem ubuntu@YOUR_PUBLIC_IP:~/app.log .
```

---

## 🎯 **Log Interpretation Guide**

### **Successful Startup:**
```
Configuration validated
PostgreSQL pool created
Hits table initialized
Database initialized
Server listening on port 8000
Application ready at http://localhost:8000
```

### **Database Connection Failed:**
```
Failed to create database pool: connection to server at "ha-tt-db.xxxxx.rds.amazonaws.com"
FATAL: no pg_hba.conf entry for host "10.0.1.8"
```
Solution: Check RDS security group, verify SSL is enabled

### **Database Doesn't Exist:**
```
FATAL: database "ha-tt-db" does not exist
```
Solution: Run `database-init.sh` to create it

### **Application Crashed:**
```
Failed to start application: [error message]
error.stack: [full stack trace]
```
Solution: Check the error message and review relevant logs

---

## 🔐 **Important: Security Notes**

**DO NOT:**
- ❌ Echo passwords to logs
- ❌ Share logs with sensitive data
- ❌ Commit logs to git

**DO:**
- ✅ Use `sudo journalctl -u app` to view app logs safely
- ✅ Filter logs with `grep` to avoid seeing passwords
- ✅ Delete logs after debugging if they contain sensitive data

---

## 📞 **Quick Reference**

| Task | Command |
|------|---------|
| Watch app logs live | `sudo journalctl -u app -f` |
| Last 50 app log lines | `sudo journalctl -u app -n 50` |
| View user data log | `sudo cat /var/log/user-data.log` |
| Restart app | `sudo systemctl restart app` |
| Check app status | `sudo systemctl status app` |
| Test app | `curl http://localhost:8000` |
| Check environment vars | `sudo systemctl show-environment \| grep DB_` |
| Search app logs | `sudo journalctl -u app \| grep "search-term"` |

---

## 🆘 **When to Check Each Log**

| Situation | Log to Check | Command |
|-----------|--------------|---------|
| Instance just launched | User data log | `sudo tail -f /var/log/user-data.log` |
| App won't start | App logs | `sudo journalctl -u app -n 100` |
| App crashes after starting | App logs | `sudo journalctl -u app -f` |
| Database connection error | App logs | `sudo journalctl -u app \| grep -i database` |
| Page not loading (HTTP error) | Nginx error log | `sudo tail -f /var/log/nginx/error.log` |
| Setup script stuck | User data log | `sudo tail -f /var/log/user-data.log` |

---

**Pro Tip:** Keep `sudo journalctl -u app -f` running in one terminal while testing in another. You'll see any errors immediately! 🚀
