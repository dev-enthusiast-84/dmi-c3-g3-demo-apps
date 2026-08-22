# Secure Credential Flow & Environment Variables

## 🎯 How Environment Variables Get to Your App on EC2

This document explains the complete flow of how credentials are securely passed from your local machine to the running application on EC2.

---

## 🔐 **Complete Flow: From Your Computer to Running App**

```
┌─────────────────────────────────────────────────────────────────────┐
│ 1. YOUR LOCAL MACHINE                                               │
│    ========================                                          │
│    Run config-generator.sh                                           │
│    └─→ Type credentials interactively (NOT in git, NOT shared)      │
│    └─→ Generates: userdata-custom.sh (with your credentials)        │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────────┐
│ 2. AWS CONSOLE                                                      │
│    ==============                                                    │
│    Copy userdata-custom.sh to clipboard                             │
│    └─→ Paste into: EC2 Launch Template > User Data                  │
│    └─→ Credentials embedded in template (secured by AWS)            │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────────┐
│ 3. EC2 INSTANCE STARTUP (runs user data script)                     │
│    ======================                                            │
│    UserData script executes:                                         │
│    ├─ Section 1: System setup (Node.js, Nginx, PostgreSQL client)   │
│    ├─ Section 2: Deploy app code                                     │
│    │  └─→ Create /opt/app/.env with credentials (lines 250-259)     │
│    │      DB_TYPE=postgres                                          │
│    │      DB_ENDPOINT=ha-tt-db.xxxxx.rds.amazonaws.com              │
│    │      DB_USER=postgres                                          │
│    │      DB_PASSWORD=YourSecurePassword123                         │
│    │      DB_NAME=ha-tt-db                                          │
│    │      DB_PORT=5432                                              │
│    │      APP_PORT=8000                                             │
│    │      NODE_ENV=production                                       │
│    ├─ Section 3: Nginx configuration                                │
│    ├─ Section 3.5: DATABASE INITIALIZATION ✨ (NEW)                 │
│    │  └─→ Create temporary database-init.sh script                  │
│    │  └─→ Call: ./database-init.sh postgres [credentials]           │
│    │  └─→ Result: Database and table created if needed              │
│    ├─ Section 4: Create systemd service file                        │
│    │  └─→ File: /etc/systemd/system/app.service                     │
│    │  └─→ Contains: EnvironmentFile=/opt/app/.env                   │
│    └─ Section 5: Start services                                     │
│       └─→ systemctl start app                                       │
│           └─→ App reads /opt/app/.env as environment variables      │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────────┐
│ 4. NODE.JS APP (now running)                                        │
│    ======================                                            │
│    app reads process.env for credentials:                           │
│    ├─ process.env.DB_ENDPOINT   → host                              │
│    ├─ process.env.DB_USER       → user                              │
│    ├─ process.env.DB_PASSWORD   → password                          │
│    ├─ process.env.DB_NAME       → database                          │
│    ├─ process.env.DB_PORT       → port                              │
│    └─ process.env.APP_PORT      → port                              │
│                                                                      │
│    Creates connection with SSL:                                     │
│    if (DB_ENDPOINT.includes('rds')) {                               │
│      dbConfig.ssl = { rejectUnauthorized: false }                   │
│    }                                                                 │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 🔑 **Key Files & Their Role**

| File | Location | Created By | Purpose | Contains Secrets |
|------|----------|-----------|---------|-----------------|
| `config-generator.sh` | Local machine | Repo | Interactive credential prompt | ❌ No |
| `userdata-custom.sh` | Local machine (temporary) | config-generator | Script with embedded credentials | ✅ Yes (local only) |
| `/opt/app/.env` | EC2 instance | userdata script | Credentials loaded by systemd | ✅ Yes (in instance) |
| `/etc/systemd/system/app.service` | EC2 instance | userdata script | Service configuration | ❌ No (references .env) |
| `app` (running process) | EC2 memory | systemd | Node.js application | ✅ Yes (loaded in memory) |

---

## 🔒 **Security Guarantees**

### ✅ What IS Secure

- **Credentials never in git** - config-generator output is `.gitignore`d
- **Credentials never shared** - Only live on your machine and EC2 instance
- **Credentials not logged** - systemd doesn't log environment files
- **Credentials encrypted in transit** - AWS transfers encrypted
- **File permissions restricted** - `/opt/app/.env` is readable only by app user
- **Memory-only at runtime** - Deleted from disk after app starts

### ⚠️ What to Watch

- **CloudWatch logs** - Don't manually echo passwords to logs
- **EC2 instance access** - Anyone with SSH access can read `/opt/app/.env`
- **Snapshot backups** - EBS snapshots contain credentials
- **History** - If you manually typed credentials in SSH, they're in `~/.bash_history`

---

## 🚀 **Complete Deployment Flow (Updated)**

### Step 1: Generate Script Locally

```bash
cd /Users/maneettaantony/Workspaces/DMI-C3-G3/dmi-c3-g3-demo-apps/ha-tt-app
./app-structure/config-generator.sh

# Select: Option 2 (Generate user data script)
# Answer prompts with your RDS credentials
# Output: generated/userdata-custom.sh
```

### Step 2: Copy to Clipboard

```bash
cat generated/userdata-custom.sh | pbcopy
```

### Step 3: Launch EC2

1. AWS Console → EC2 → Launch Templates
2. Create Launch Template
3. AMI: Ubuntu 22.04 LTS
4. Instance Type: t3.micro
5. Key Pair: Your EC2 key
6. Security Group: Your security group (allows port 80, RDS access)
7. **Advanced Details** → **User Data** → Paste (Cmd+V)
8. Create and launch

### Step 4: Automatic Setup

UserData script automatically:
1. ✅ Installs Node.js, Nginx, PostgreSQL client
2. ✅ Deploys application code
3. ✅ Creates `/opt/app/.env` with credentials
4. ✅ Initializes database (if not exists)
5. ✅ Creates systemd service
6. ✅ Starts application

### Step 5: Test

```bash
# Get public IP
curl http://[PUBLIC_IP]

# Should show hit counter!
```

---

## 🔄 **What Happens in systemd Service**

When you run `systemctl start app`:

```bash
# systemd reads the service file
cat /etc/systemd/system/app.service

# Key line:
# EnvironmentFile=/opt/app/.env

# systemd loads all variables from .env into the process environment
# Then runs the command with those env vars available:
# /usr/bin/node /opt/app/index.js

# In Node.js:
process.env.DB_ENDPOINT  # "ha-tt-db.xxxxx.rds.amazonaws.com"
process.env.DB_PASSWORD  # "YourPassword123"
# ... etc
```

---

## 📝 **How App Code Reads Credentials**

### In db.js (modular structure)

```javascript
// config.js loads from process.env
const config = {
  database: {
    endpoint: process.env.DB_ENDPOINT,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    name: process.env.DB_NAME,
    port: process.env.DB_PORT
  }
};

// db.js uses config and adds SSL for RDS
if (config.database.endpoint && config.database.endpoint.includes('rds')) {
  poolConfig.ssl = { rejectUnauthorized: false };
}
```

### In embedded app code (userdata script)

```javascript
const dbConfig = {
  host: process.env.DB_ENDPOINT,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: parseInt(process.env.DB_PORT || '5432')
};

// Enable SSL for RDS
if (process.env.DB_ENDPOINT && process.env.DB_ENDPOINT.includes('rds')) {
  dbConfig.ssl = { rejectUnauthorized: false };
}
```

---

## 🔄 **Database Initialization Flow**

### New in userdata (Section 3.5)

```bash
# 1. Create temporary init script with database logic
cat > /tmp/database-init.sh <<'EOF'
  # PostgreSQL setup code
  # Test connection, create database, create table
EOF

# 2. Run it with credentials passed as arguments
/tmp/database-init.sh postgres "$DB_ENDPOINT" "$DB_USER" "$DB_PASSWORD" "$DB_NAME" "$DB_PORT"

# 3. If it works: Database is ready before app starts
# 4. If it fails: App can still start and retry creating tables
```

### Result

- ✅ Database created on first launch
- ✅ Database not recreated if already exists
- ✅ Credentials passed securely (as function arguments, not in script)
- ✅ Happens before app starts (better reliability)

---

## ✨ **Improvements Made**

| Issue | Before | After |
|-------|--------|-------|
| Credentials | Hardcoded in template | Generated from `config-generator.sh` |
| Database Init | Manual via Query Editor | Automatic in userdata (Section 3.5) |
| SSL Support | Not configured | Auto-enabled for RDS endpoints |
| Error Handling | Silent failures | Clear error messages in logs |
| Timing | App might fail on startup | Database ready before app starts |

---

## 🧪 **Testing the Flow**

### Check if environment variables are loaded

```bash
sudo systemctl show-environment | grep DB_
# Should output:
# DB_TYPE=postgres
# DB_ENDPOINT=ha-tt-db.xxxxx.rds.amazonaws.com
# DB_USER=postgres
# ... etc
```

### Check if .env file exists

```bash
cat /opt/app/.env
# Should show all credentials
```

### Check if app is using them

```bash
sudo journalctl -u app -n 20
# Should show:
# PostgreSQL pool created
# Table creation successful
# Application listening on port 8000
```

### Manual credential test

```bash
# Test connection with same credentials
export PGPASSWORD='YourPassword123'
psql -h ha-tt-db.xxxxx.rds.amazonaws.com -U postgres -d ha-tt-db -c "SELECT * FROM hits;"
```

---

## 🚨 **Common Issues & Solutions**

### Issue: "no pg_hba.conf entry"

**Cause:** RDS requires SSL but app wasn't using it  
**Solution:** Automatic now with SSL configuration in app code

### Issue: "FATAL: database 'ha-tt-db' does not exist"

**Cause:** Database init failed, app tried to connect  
**Solution:** Database now initialized in Section 3.5 before app starts

### Issue: App doesn't see environment variables

**Cause:** Service not loading .env file  
**Solution:** Check `EnvironmentFile=/opt/app/.env` in service file

### Issue: Credentials showing in logs

**Cause:** Manually echoing to console  
**Solution:** Credentials in .env are not automatically logged

---

## 📚 **Related Files**

- `app-structure/config-generator.sh` - Interactive credential prompt
- `app-structure/userdata-ec2-only.sh` - Main EC2 setup script (UPDATED)
- `app-structure/database-init.sh` - Standalone DB init script
- `app-structure/db.js` - App database module with SSL support
- `SECURE_LOCAL_DEPLOYMENT.md` - How to generate scripts safely

---

## ✅ **Checklist Before Deploying**

- [ ] Run config-generator.sh to generate userdata-custom.sh
- [ ] Review credentials are correct (not in git)
- [ ] Copy userdata-custom.sh to clipboard
- [ ] Paste into EC2 Launch Template User Data
- [ ] Verify security groups allow EC2→RDS on port 5432
- [ ] Launch instance and wait for initialization
- [ ] Check logs: `sudo journalctl -u app -n 30`
- [ ] Test app: `curl http://[PUBLIC_IP]`
- [ ] Delete local userdata-custom.sh file
- [ ] Run: `history -c` to clear shell history

---

**This flow ensures credentials are secure while being available to your running application.**
