# Templates Quick Start

**Safe, git-friendly way to deploy with your credentials**

---

## 🎯 In 3 Steps

### Step 1: Copy Template

```bash
# From repository root
cp deploy-config.sh.template deploy-config.sh

# Or navigate to repository first
cd /path/to/ha-tt-app
cp deploy-config.sh.template deploy-config.sh
```

### Step 2: Edit With Your Credentials

```bash
nano deploy-config.sh

# Change these lines:
DB_TYPE="postgres"                              # or "mysql"
DB_ENDPOINT="mydb.xxxxx.us-east-1.rds.amazonaws.com"  # Your endpoint
DB_USER="postgres"                              # Your username
DB_PASSWORD="YourPassword123!"                  # Your password
DB_PORT="5432"                                  # 5432 or 3306
```

### Step 3: Generate & Deploy

```bash
bash deploy-config.sh
# Output: ~/userdata-READY.sh (ready for AWS)

# Copy to clipboard
cat ~/userdata-READY.sh | pbcopy

# Paste into AWS Launch Template → User Data → Launch
```

**Done!** ✅

---

## 📁 Available Templates

### In Repository (Git-Safe)

These files are **committed to git** because they contain no secrets:

```
deploy-config.sh.template
├── Purpose: Automated script generator
├── Status: ✅ Committed to git
├── Contains: Placeholders only (no secrets)
└── Usage: Copy → Edit with your values → Run

app-structure/database-init.sh.template
├── Purpose: Optional DB pre-initialization
├── Status: ✅ Committed to git
├── Contains: Placeholders only (no secrets)
└── Usage: Copy → Edit with your values → Run
```

### On Your Machine (Local Only)

These files are **NOT committed to git** (automatically .gitignored):

```
deploy-config.sh (your local copy)
├── Purpose: Your deployment configuration
├── Status: ❌ NOT in git (.gitignored)
├── Contains: YOUR actual RDS credentials
└── Usage: Keep locally, delete after use

database-init.local.sh (your local copy)
├── Purpose: Your database initialization
├── Status: ❌ NOT in git (.gitignored)
├── Contains: YOUR actual RDS credentials
└── Usage: Keep locally, optional to use

userdata-READY.sh (generated)
├── Purpose: Ready-to-paste AWS deployment script
├── Status: ❌ NOT in git (.gitignored)
├── Contains: Your credentials embedded
└── Usage: Paste into AWS, delete after
```

---

## 🔐 Git Safety

### What's Committed ✅

```bash
git status

# Should show:
# On branch main
# nothing to commit, working tree clean

# The .template files are already in git
# Your edited versions don't appear in git
```

### What's Not Committed ❌

```bash
git status

# deploy-config.sh will NOT appear
# database-init.local.sh will NOT appear
# userdata-READY.sh will NOT appear

# These stay only on your local machine
```

### Verify Safety

```bash
# Check if your local files are ignored
git check-ignore -v deploy-config.sh
# Should output: .gitignore:44: deploy-config.sh

# Check if templates are in git
git ls-files | grep template
# Should show: deploy-config.sh.template
#             app-structure/database-init.sh.template
```

---

## 📋 Template Files Reference

### deploy-config.sh.template

**Location:** Root directory  
**Size:** ~1.5 KB  
**Status:** ✅ In git (no secrets)

**How to use:**
```bash
# 1. Copy
cp deploy-config.sh.template deploy-config.sh

# 2. Edit your copy (NOT the .template file)
nano deploy-config.sh

# 3. Run
bash deploy-config.sh

# 4. Result: ~/userdata-READY.sh generated
```

**What it does:**
- Reads your credentials from `deploy-config.sh`
- Copies the base userdata script
- Replaces placeholders with YOUR values
- Creates: `~/userdata-READY.sh`
- Ready for AWS Launch Template

---

### app-structure/database-init.sh.template

**Location:** app-structure/  
**Size:** ~2.5 KB  
**Status:** ✅ In git (no secrets)  
**Usage:** Optional

**How to use:**
```bash
# 1. Copy (optional - only if you want pre-init)
cp app-structure/database-init.sh.template database-init.local.sh

# 2. Edit your copy
nano database-init.local.sh

# 3. Run before EC2 deployment
bash database-init.local.sh

# 4. Result: Database tables created on RDS
```

**When to use:**
- ✅ You want faster EC2 startup
- ✅ You want to verify DB connectivity before EC2 launch
- ✅ You're doing multiple deployments to same RDS

**When to skip:**
- ✅ Application can auto-create tables (it does)
- ✅ You want minimal manual steps
- ✅ First-time setup

---

## 🚀 Complete Workflow

### Clone & Setup (First Time)

```bash
# 1. Clone repository
git clone https://github.com/myorg/ha-tt-app.git
cd ha-tt-app

# 2. List available templates
ls -la *.template
ls -la app-structure/*.template

# Output shows:
# deploy-config.sh.template              ✅ Available
# app-structure/database-init.sh.template ✅ Available
```

### Development (Your Machine)

```bash
# 3. Copy template locally (creates .gitignored file)
cp deploy-config.sh.template deploy-config.sh

# 4. Edit with YOUR credentials only
nano deploy-config.sh
# Change: DB_ENDPOINT, DB_USER, DB_PASSWORD, etc.

# 5. Verify it's gitignored
git status
# Should NOT show deploy-config.sh

# 6. Generate deployment script
bash deploy-config.sh

# 7. Verify generated script exists
ls -la ~/userdata-READY.sh
```

### Deployment

```bash
# 8. Copy and paste to AWS
cat ~/userdata-READY.sh | pbcopy

# 9. AWS Console:
# EC2 → Launch Templates → Create
# User Data → Paste → Create

# 10. Launch instance
# Monitor for 5-10 minutes
```

### Cleanup (Optional)

```bash
# 11. Delete local deployment scripts
rm ~/userdata-READY.sh
rm deploy-config.sh

# 12. Keep changes if any
git pull
git status  # Should be clean
```

---

## Common Questions

**Q: Can I commit deploy-config.sh?**  
A: ❌ No! It's gitignored for a reason. It contains YOUR RDS password.

**Q: What if I accidentally commit it?**  
A: See `TEMPLATE_AND_GIT_GUIDE.md` section "If You Accidentally Commit Secrets"

**Q: Do I need to edit the .template file?**  
A: ❌ No. Copy it, then edit the copy.

**Q: Where does the .template file go?**  
A: Nowhere - it stays in git. You copy it locally to create your version.

**Q: Can multiple team members use the same template?**  
A: ✅ Yes! Each person copies the template, edits with their own credentials.

**Q: Is database-init.sh.template optional?**  
A: ✅ Yes. Application auto-creates tables. Use it only if you want pre-init.

**Q: What should I delete after deployment?**  
A: Delete `userdata-READY.sh` (and `deploy-config.sh` if you want to clean up).

---

## File Checklist

### ✅ Commit to Git
```
[ ] deploy-config.sh.template
[ ] app-structure/database-init.sh.template
[ ] Documentation files (*.md)
[ ] Source code (*.js, *.json)
[ ] .gitignore
```

### ❌ DO NOT Commit
```
[ ] deploy-config.sh (your local copy)
[ ] database-init.local.sh (your local copy)
[ ] userdata-READY.sh (generated)
[ ] .env files
[ ] *.pem files
[ ] *.key files
[ ] Anything with passwords
```

---

## Quick Commands

```bash
# Copy template to working copy
cp deploy-config.sh.template deploy-config.sh

# Edit with your values
nano deploy-config.sh

# Verify it won't be committed
git check-ignore -v deploy-config.sh

# Generate deployment script
bash deploy-config.sh

# Show generated script
cat ~/userdata-READY.sh

# Copy to clipboard (macOS)
cat ~/userdata-READY.sh | pbcopy

# Copy to clipboard (Linux)
cat ~/userdata-READY.sh | xclip -selection clipboard

# Delete local scripts
rm ~/userdata-READY.sh deploy-config.sh

# Check git status (should be clean)
git status
```

---

## Security Summary

✅ **Templates in Git:** Safe (contain no secrets)  
❌ **Your Edits:** NOT in git (automatically .gitignored)  
❌ **Generated Scripts:** NOT in git (automatically .gitignored)  
✅ **Credentials:** Stay on your machine only  

**Rule:** Templates stay in git. Secrets stay local. Never mix.

---

## For More Info

- **Git Safety Details:** `TEMPLATE_AND_GIT_GUIDE.md`
- **Deployment Instructions:** `SECURE_LOCAL_DEPLOYMENT.md` → Method 2
- **All Documentation:** `DOCUMENTATION_MAP.md`

---

**Ready to deploy?** Follow the "3 Steps" at the top! 🚀
