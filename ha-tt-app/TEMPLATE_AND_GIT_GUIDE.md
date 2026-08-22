# Template Scripts & Git Safety Guide

**How to use templates safely without committing credentials to git**

---

## Overview

This project provides **template scripts** that you copy and modify locally. The templates stay in git, but your actual deployment scripts with credentials stay on your machine only.

```
In Git (Public)          On Your Machine (Private)
├── *.template files      ├── *.local files (ignored)
├── Example configs       ├── Actual configs (ignored)
└── Documentation         └── Generated scripts (ignored)
```

---

## File Structure

### ✅ Checked Into Git (Templates & Examples)

```
deploy-config.sh.template              ← Template with placeholders
app-structure/
├── database-init.sh.template           ← Template with placeholders
├── config-generator.sh                 ← Utility (no secrets)
├── userdata-ec2-only.sh               ← Base script (no secrets)
└── index.js                            ← Application code
```

### ❌ NOT Checked Into Git (.gitignore)

```
deploy-config.sh                        ← Your local copy with credentials
database-init.local.sh                  ← Your local copy with credentials
userdata-READY.sh                       ← Generated with your credentials
generated/userdata-*.sh                 ← Any generated scripts
.env files                              ← Environment variables
*.local                                 ← Any .local files
*.pem / *.key                          ← AWS keys
```

---

## Workflow: Safe Deployment Without Committing Secrets

### Step 1: Clone Repository

```bash
git clone <repo>
cd ha-tt-app
```

### Step 2: Copy Template Locally (Not Committed)

```bash
# Copy template to local file (ignored by git)
cp deploy-config.sh.template deploy-config.sh
```

### Step 3: Edit With Your Credentials (Stays Local)

```bash
# Edit with YOUR actual RDS credentials
nano deploy-config.sh

# Never commit this file - it's gitignored
```

### Step 4: Generate Deployment Script (Stays Local)

```bash
bash deploy-config.sh

# Generates: ~/userdata-READY.sh (with your credentials)
# This file is also NOT committed
```

### Step 5: Deploy to AWS

```bash
# Copy to clipboard and paste into AWS Console
cat ~/userdata-READY.sh | pbcopy
```

### Step 6: Clean Up (Optional)

```bash
# Remove local scripts after deployment
rm ~/userdata-READY.sh
rm deploy-config.sh
```

---

## Template Files Explained

### deploy-config.sh.template

**Location:** Root directory  
**Purpose:** Template for automation script generator  
**What's In It:** Placeholders for RDS credentials

**Usage:**
```bash
# 1. Copy template
cp deploy-config.sh.template deploy-config.sh

# 2. Edit with your values
nano deploy-config.sh

# 3. Run to generate deployment script
bash deploy-config.sh

# 4. Result: ~/userdata-READY.sh (ready for AWS)
```

**Git Status:** ✅ Committed (contains NO secrets)  
**Your Local Version:** ❌ Not committed (contains secrets, .gitignored)

---

### app-structure/database-init.sh.template

**Location:** app-structure/  
**Purpose:** Template for optional database pre-initialization  
**What's In It:** Placeholders for RDS credentials

**Usage:**
```bash
# 1. Copy template (optional - only if you want pre-init)
cp app-structure/database-init.sh.template database-init.local.sh

# 2. Edit with your values
nano database-init.local.sh

# 3. Run before EC2 deployment (optional)
bash database-init.local.sh

# Result: Database tables created on RDS
```

**Git Status:** ✅ Committed (contains NO secrets)  
**Your Local Version:** ❌ Not committed (contains secrets, .gitignored)

---

## .gitignore Configuration

The `.gitignore` file ensures these sensitive files are NEVER committed:

```
# Deployment Configuration (SENSITIVE - Never commit)
deploy-config.sh                # Your local config with credentials
userdata-READY.sh              # Generated script with embedded secrets

# Database initialization scripts
database-init.local.sh          # Your local DB init with credentials
database-init.sh.template.local # Any template overrides

# Generated scripts (with credentials embedded)
/generated/userdata-*.sh        # Generated scripts

# AWS/Terraform
*.pem                           # AWS key pairs
*.key                          # Private keys
aws-credentials.json           # AWS credentials
terraform.tfvars               # Terraform secrets

# Local scripts with secrets
/local-scripts/
deploy.local.sh
```

---

## Verification: Check Git Safety

### ✅ Safe to Commit
```bash
# Check what's tracked
git status

# Should show:
# ✓ deploy-config.sh.template
# ✓ app-structure/database-init.sh.template
# ✓ DOCUMENTATION files
# ✓ Source code (.js, .json)

# Should NOT show:
# ✗ deploy-config.sh (no template extension)
# ✗ userdata-READY.sh
# ✗ database-init.local.sh
# ✗ *.pem files
```

### ❌ Never Commit
```bash
# Check for accidentally tracked files
git log --oneline --follow -- deploy-config.sh

# Should return nothing (file not in history)
```

### Test .gitignore

```bash
# Verify gitignore is working
git check-ignore -v deploy-config.sh

# Should output:
# .gitignore:44: deploy-config.sh

# If no output, file might be committed!
```

---

## If You Accidentally Commit Secrets

### ⚠️ EMERGENCY: Remove from Git History

**If you committed credentials to git, do this immediately:**

```bash
# 1. Remove file from git (but keep locally)
git rm --cached deploy-config.sh

# 2. Commit the removal
git commit -m "Remove deploy-config.sh (contained credentials)"

# 3. Push to remote
git push

# 4. IMPORTANT: Rotate credentials immediately!
# Change your RDS password in AWS Console
```

### Prevent Future Accidents

```bash
# Use git hooks to prevent secrets
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
if git diff --cached | grep -i password; then
  echo "❌ ERROR: Possible password in commit!"
  exit 1
fi
EOF

chmod +x .git/hooks/pre-commit
```

---

## Team Workflow with Templates

### For Team Members

1. **Clone repo**
   ```bash
   git clone <repo>
   ```

2. **Copy template locally**
   ```bash
   cp deploy-config.sh.template deploy-config.sh
   ```

3. **Add YOUR credentials**
   ```bash
   # Each team member uses their own RDS credentials
   nano deploy-config.sh
   ```

4. **Generate and deploy**
   ```bash
   bash deploy-config.sh
   # Your script, your credentials, stays local
   ```

5. **Never commit or share**
   ```bash
   # Your deploy-config.sh stays .gitignored
   # Each team member has their own local version
   ```

### Why This Works

✅ Everyone uses the same template  
✅ Everyone has different credentials (local only)  
✅ No credentials in git  
✅ No accidental sharing  
✅ Easy to onboard new team members  

---

## Example: Complete Workflow

### Setup (First Time)

```bash
# 1. Clone repo
git clone https://github.com/myorg/ha-tt-app.git
cd ha-tt-app

# 2. Check what templates are available
ls -la *.template
ls -la app-structure/*.template

# Output:
# deploy-config.sh.template              ← Available
# app-structure/database-init.sh.template ← Available
```

### Development (Your Local Machine)

```bash
# 3. Copy template with YOUR values
cp deploy-config.sh.template deploy-config.sh

# 4. Edit with your RDS details
nano deploy-config.sh
# Change these lines to YOUR values:
# DB_ENDPOINT="your-endpoint"
# DB_USER="your-user"
# DB_PASSWORD="your-password"

# 5. Verify it's NOT committed
git status
# Should show deploy-config.sh is IGNORED

# 6. Generate deployment script
bash deploy-config.sh
# Creates: ~/userdata-READY.sh
```

### Deployment

```bash
# 7. Copy and paste into AWS
cat ~/userdata-READY.sh | pbcopy

# 8. Launch instance via AWS Console
# Paste into Launch Template → User Data

# 9. Monitor deployment
# Instance initializes in 5-10 minutes
```

### Cleanup

```bash
# 10. Delete local deployment scripts (optional)
rm ~/userdata-READY.sh
rm deploy-config.sh

# 11. Pull latest changes from team
git pull
```

---

## File Reference Table

| File | Git? | Your Machine | Contains Secrets? | Purpose |
|------|------|--------------|------------------|---------|
| `deploy-config.sh.template` | ✅ Yes | Copy locally | ❌ No (placeholders) | Template for automation |
| `deploy-config.sh` | ❌ No | You create | ✅ Yes | Your local deployment config |
| `userdata-ec2-only.sh` | ✅ Yes | Reference | ❌ No (base script) | Base deployment script |
| `userdata-READY.sh` | ❌ No | Generated | ✅ Yes | Your generated deployment script |
| `database-init.sh.template` | ✅ Yes | Copy locally | ❌ No (placeholders) | DB init template (optional) |
| `database-init.local.sh` | ❌ No | You create | ✅ Yes | Your local DB init |
| `.env.example` | ✅ Yes | Reference | ❌ No (example) | Example environment variables |
| `.env` | ❌ No | You create | ✅ Yes | Your actual environment variables |

---

## Best Practices

### ✅ DO

- ✅ Keep `.template` files in git
- ✅ Copy templates locally with `.local` extension
- ✅ Edit your `.local` files with actual credentials
- ✅ Run generators to create deployment scripts
- ✅ Use generated scripts immediately, then delete
- ✅ Commit documentation and examples
- ✅ Rotate credentials regularly
- ✅ Review .gitignore before commits

### ❌ DON'T

- ❌ Commit `deploy-config.sh` (without `.template`)
- ❌ Commit `userdata-READY.sh`
- ❌ Commit `.env` files with real credentials
- ❌ Commit `.pem` or `.key` files
- ❌ Commit files with passwords
- ❌ Share your `.local` files
- ❌ Leave generated scripts on disk permanently
- ❌ Hardcode credentials in code

---

## Security Checklist

```
Before pushing to git:

[ ] Run `git status` and verify:
    [ ] No .local files listed
    [ ] No deploy-config.sh (without .template)
    [ ] No userdata-READY.sh
    [ ] No *.pem or *.key files
    [ ] No .env files (except .env.example)

[ ] Run `git diff --cached` to review:
    [ ] No passwords visible
    [ ] No API keys visible
    [ ] No AWS credentials visible
    [ ] No database passwords visible

[ ] Verify .gitignore covers:
    [ ] *.local files
    [ ] deploy-config.sh
    [ ] userdata-READY.sh
    [ ] *.pem and *.key files
    [ ] .env files

[ ] If you see secrets:
    [ ] Cancel commit (Ctrl+C)
    [ ] Remove from staging area
    [ ] Run git check-ignore to verify ignore rules
    [ ] Try commit again
```

---

## Troubleshooting

### Problem: "deploy-config.sh already in git history"

**Solution:**
```bash
# 1. Remove from git history
git filter-branch --tree-filter 'rm -f deploy-config.sh' HEAD

# 2. Force push (careful! affects all users)
git push --force

# 3. Rotate credentials (file was exposed)
# Change your RDS password in AWS Console
```

### Problem: ".gitignore not working for already tracked files"

**Solution:**
```bash
# 1. Untrack the file
git rm --cached deploy-config.sh

# 2. Commit the removal
git commit -m "Untrack deploy-config.sh"

# 3. Verify it's in .gitignore
cat .gitignore | grep deploy-config.sh

# 4. Push changes
git push
```

### Problem: "I don't know if credentials are in git"

**Solution:**
```bash
# Search git history for passwords
git log --all --source --remotes -S "password" | head -20

# Search for DB endpoints
git log --all --source --remotes -S "rds.amazonaws.com" | head -20

# If found, immediately rotate credentials and remove from history
```

---

## Quick Reference Commands

```bash
# Check what's staged for commit
git status

# Review changes before committing
git diff --cached

# Verify .gitignore is working
git check-ignore -v deploy-config.sh

# See if file is tracked in git history
git log --oneline -- deploy-config.sh

# Untrack a file that shouldn't be tracked
git rm --cached filename

# See what .gitignore patterns apply
git check-ignore -v filename

# Verify no passwords in git history
git log --all -S "password" | head

# Show git history for a sensitive file
git log --oneline -- .env

# Remove sensitive file from git history (CAREFUL!)
git filter-branch --tree-filter 'rm -f sensitive-file' HEAD
```

---

## For Repository Administrators

### Initial Setup

```bash
# 1. Create .gitignore
cat > .gitignore << 'EOF'
# Sensitive files - never commit
*.local
deploy-config.sh
userdata-READY.sh
*.pem
*.key
.env
aws-credentials.json
EOF

# 2. Create templates for team
cp userdata-generator.sh userdata-generator.sh.template
# Remove all secrets from template

# 3. Commit
git add .gitignore *.template
git commit -m "Add templates and gitignore for safe deployment"
git push

# 4. Verify
git log --oneline -1
```

### Onboarding New Team Members

```bash
# Create a SETUP.md for team:

cat > SETUP.md << 'EOF'
# Setup for Development

## First Time Setup

1. Clone repo: `git clone <repo>`
2. Copy templates: `cp *.template *.local`
3. Edit your .local files with YOUR credentials
4. Never commit your .local files (they're .gitignored)
5. Generate deployment scripts: `bash deploy-config.sh`
6. Deploy to AWS

## Important
- NEVER commit .local files
- NEVER share your credentials
- NEVER commit .pem files
- If you accidentally commit secrets, let us know immediately
EOF

git add SETUP.md
git commit -m "Add setup guide for team"
git push
```

---

## Summary

| What | Where | Git? | Contains Secrets? |
|------|-------|------|------------------|
| **Templates** | Repo | ✅ Yes | ❌ No |
| **Your Configs** | Local Only | ❌ No | ✅ Yes |
| **Generated Scripts** | Local Only | ❌ No | ✅ Yes |
| **Documentation** | Repo | ✅ Yes | ❌ No |
| **Source Code** | Repo | ✅ Yes | ❌ No |

**Golden Rule:** Credentials stay on your machine. Templates stay in git. Never the two shall meet in history.

---

**Questions?** Check `.gitignore` and run:
```bash
git status
git check-ignore -v deploy-config.sh
```

Both should confirm your credentials are safe.
