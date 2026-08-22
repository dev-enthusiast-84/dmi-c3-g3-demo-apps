# Scripts Quick Reference

**Three Focused Scripts for EC2-Only Deployment**

---

## 1️⃣ userdata-ec2-only.sh (Main Deployment Script)

**Location:** `app-structure/userdata-ec2-only.sh`  
**Size:** 11 KB | **Lines:** ~355  
**Purpose:** EC2 instance setup ONLY  
**Time:** 5-10 minutes  

### What It Does
```
✅ System updates
✅ Install Node.js 20.x
✅ Install Nginx
✅ Deploy application code
✅ Configure environment variables
✅ Create systemd service
✅ Start services
```

### What It Doesn't Do
```
❌ Create RDS instance
❌ Create databases
❌ Create tables
❌ Modify RDS configuration
```

### Usage
```bash
# Edit configuration (5 lines):
DB_TYPE="postgres"
DB_ENDPOINT="your-endpoint"
DB_USER="postgres"
DB_PASSWORD="your-password"
DB_NAME="ha-tt-db"

# Copy entire script → AWS Launch Template → User Data → Launch
```

### Copy & Paste Path
```
app-structure/userdata-ec2-only.sh → AWS Launch Template User Data
```

---

## 2️⃣ database-init.sh (Optional Database Setup)

**Location:** `app-structure/database-init.sh`  
**Size:** 2.9 KB  
**Purpose:** Pre-initialize database (optional)  
**Time:** 1-2 minutes  

### When to Use
```
✅ Pre-create database before EC2 deployment
✅ Faster application startup
✅ Pre-validate database connectivity
✅ Deterministic setup
```

### When NOT Needed
```
❌ Application auto-creates database on startup
❌ No performance difference for single instance
❌ Extra step for initial setup
```

### Usage
```bash
chmod +x database-init.sh

# PostgreSQL
./database-init.sh postgres mydb.xxxxx.rds.amazonaws.com postgres password ha-tt-db

# MySQL
./database-init.sh mysql mydb.xxxxx.rds.amazonaws.com admin password ha-tt-db
```

### Supported Databases
- PostgreSQL (port 5432)
- MySQL (port 3306)

### Prerequisites
- PostgreSQL client installed (`psql`)
- MySQL client installed (`mysql`)
- RDS instance already running
- Network connectivity to RDS

---

## 3️⃣ config-generator.sh (Interactive Configuration Tool)

**Location:** `app-structure/config-generator.sh`  
**Size:** 14 KB  
**Purpose:** Generate configuration and customized scripts  
**Time:** 2-3 minutes  

### What It Generates
```
✅ .env file (for local development)
✅ Customized user data script (for AWS)
✅ Environment variables export
✅ Complete configuration packages
```

### Usage
```bash
chmod +x config-generator.sh
./config-generator.sh

# Follow interactive menu:
# 1) .env file
# 2) User data script
# 3) Complete package (both)
# 4) Environment variables only
```

### Generated Files Location
```
./generated/
├── .env
├── userdata-custom.sh
├── env-vars.sh
└── [other config files]
```

### Benefits
```
✅ No manual script editing
✅ Interactive validation
✅ Consistent configuration
✅ Reusable generated files
```

---

## Recommended Deployment Method

⭐ **RECOMMENDED: Automated Script (Not config-generator.sh, but the deploy-config.sh approach)**

Use the **Automated Script Method** from `SECURE_LOCAL_DEPLOYMENT.md`:
- Create config file locally with your values
- Run script generator
- Paste into AWS
- Simple, secure, no passwords shared

See: `SECURE_LOCAL_DEPLOYMENT.md` → Method 2 (Automated Script)

---

## Comparison Table

| Aspect | userdata-ec2-only.sh | database-init.sh | config-generator.sh |
|--------|----------------------|------------------|---------------------|
| **Purpose** | EC2 setup | DB initialization | Configuration tool |
| **Size** | 11 KB | 2.9 KB | 14 KB |
| **Run On** | AWS EC2 instance | Local machine | Local machine |
| **Required?** | ✅ Yes | ❌ No (optional) | ❌ No (convenience) |
| **Execution Time** | 5-10 min | 1-2 min | 2-3 min |
| **Prerequisites** | EC2 key pair | RDS instance | Database client tools |
| **Database Support** | Both | Both | Both |
| **Scope** | EC2 only | Database only | Configuration only |

---

## Deployment Scenarios

### ⭐ Scenario A: Automated Script (RECOMMENDED)
```
1. Create ~/deploy-config.sh with your values
2. Run: bash ~/deploy-config.sh
3. Copy generated ~/userdata-READY.sh
4. Paste into AWS Launch Template
5. Launch instance
Time: 3-5 minutes (most secure, least manual work)
Guide: SECURE_LOCAL_DEPLOYMENT.md → Method 2
```

### Alternative B: Manual Edit
```
1. Copy userdata-ec2-only.sh locally
2. Edit 6 configuration lines manually
3. Copy to clipboard
4. Paste into AWS Launch Template
5. Launch instance
Time: 5-10 minutes (direct control)
Guide: SECURE_LOCAL_DEPLOYMENT.md → Method 1
```

### Alternative C: Interactive Config Generator
```
1. Run: ./config-generator.sh (interactive prompts)
2. Choose: Option 2 (user data script)
3. Answer configuration prompts
4. Copy generated script
5. Paste into AWS Launch Template
6. Launch instance
Time: 5-10 minutes (wizard-style)
Guide: SECURE_LOCAL_DEPLOYMENT.md → Method 3
```

### Alternative D: With Database Pre-Setup
```
1. Run: ./database-init.sh (optional)
2. Use any method above for EC2 setup
3. Launch instance
Time: +1-2 minutes extra for DB initialization
Guide: SECURE_LOCAL_DEPLOYMENT.md
```

---

## Configuration Variables

### userdata-ec2-only.sh
```bash
DB_TYPE="postgres"              # or "mysql"
DB_ENDPOINT="your-endpoint"     # RDS endpoint URL
DB_USER="postgres"              # or "admin" for MySQL
DB_PASSWORD="your-password"     # Secure password
DB_NAME="ha-tt-db"             # Database name
DB_PORT="5432"                 # 5432 (postgres) or 3306 (mysql)
APP_PORT=8000                  # Application port
APP_DIR="/opt/app"             # Application directory
```

### database-init.sh
```bash
# Positional arguments
$1 = db-type        # "postgres" or "mysql"
$2 = endpoint       # RDS endpoint URL
$3 = user           # Database username
$4 = password       # Database password
$5 = database-name  # Database name
```

### config-generator.sh
```bash
# Interactive prompts for:
- Database Type (postgres/mysql)
- Database Endpoint
- Database User
- Database Password
- Database Name
- Database Port
- Application Port
- Application Directory
```

---

## File Locations Summary

```
ha-tt-app/
├── app-structure/
│   ├── userdata-ec2-only.sh        ← Use this for AWS
│   ├── database-init.sh            ← Run this optionally
│   ├── config-generator.sh         ← Run for interactive setup
│   ├── package.json                (application dependencies)
│   ├── index.js                    (application code)
│   └── README.md                   (detailed module docs)
│
├── docs/
│   ├── EC2_ONLY_DEPLOYMENT.md     ← Read this first
│   ├── COPY_PASTE_READY.md        (ready-to-use scripts)
│   └── [other documentation]
│
├── legacy/
│   ├── userdata-postgres.sh       (old monolithic approach)
│   ├── userdata-mysql.sh          (old monolithic approach)
│   ├── userdata-dual-db.sh        (old monolithic approach)
│   └── README.md
│
├── README.md                       (main project overview)
├── REFACTORING_SUMMARY.md         (what changed and why)
└── SCRIPTS_QUICK_REFERENCE.md     (this file)
```

---

## Quick Start Checklist

### Option A: Minimal (Fastest)
```
[ ] Read: docs/EC2_ONLY_DEPLOYMENT.md
[ ] Edit: app-structure/userdata-ec2-only.sh (5 lines)
[ ] Copy: Entire script
[ ] Paste: AWS Launch Template → User Data
[ ] Launch: EC2 instance
[ ] Wait: 5-10 minutes
[ ] Access: http://<instance-ip>
```

### Option B: With Pre-Setup
```
[ ] Run: ./database-init.sh (optional)
[ ] Follow: Option A steps above
```

### Option C: With Config Generator
```
[ ] Run: ./config-generator.sh
[ ] Choose: Option 3 (complete package)
[ ] Answer: Configuration prompts
[ ] Copy: generated/userdata-custom.sh
[ ] Paste: AWS Launch Template → User Data
[ ] Launch: EC2 instance
[ ] Access: http://<instance-ip>
```

---

## Troubleshooting Quick Reference

### Application won't start
```bash
ssh -i keypair.pem ubuntu@<instance-ip>
sudo journalctl -u app -n 50
sudo tail -f /var/log/user-data.log
```

### Database connection error
```bash
# Check security groups allow outbound to DB port
# Verify DB endpoint, user, password
curl http://<instance-ip>/health
```

### Port 80 not responding
```bash
sudo nginx -t
sudo systemctl status nginx
sudo systemctl restart nginx
```

### Configuration issues
```bash
# View current configuration
cat /opt/app/.env

# Check application environment
sudo systemctl show app --no-pager
```

---

## Key Principles

✨ **Separation of Concerns**
- EC2 setup ≠ Database setup
- Each script has one responsibility
- Easy to understand and maintain

✨ **Flexible Deployment**
- Database auto-creation or pre-creation
- Manual or interactive configuration
- Supports PostgreSQL and MySQL

✨ **Production Ready**
- Clear error handling
- Proper logging
- Security best practices
- Systemd auto-restart

✨ **Modular Components**
- Reusable for single instances or auto-scaling
- Easy to extend or modify
- Clear prerequisites documented

---

## Next Steps

1. **Start Here:** `docs/EC2_ONLY_DEPLOYMENT.md`
2. **Quick Deploy:** Use `userdata-ec2-only.sh` or config generator
3. **Pre-Setup:** Optional `database-init.sh`
4. **Monitor:** Check logs and verify application works
5. **Scale:** Use same script for multiple instances

---

**For more details:** See `docs/EC2_ONLY_DEPLOYMENT.md` and `REFACTORING_SUMMARY.md`
