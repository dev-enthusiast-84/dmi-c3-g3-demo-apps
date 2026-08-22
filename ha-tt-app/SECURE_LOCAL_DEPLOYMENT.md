# Secure Local Deployment Guide

**For users who prefer to keep passwords and keys local (not shared in chat/email)**

---

## Overview

This guide helps you:
✅ Keep credentials on YOUR machine only  
✅ Never type passwords in chat/email  
✅ Generate deployment-ready script locally  
✅ Deploy to AWS securely  

---

## 🎯 Recommended Method: Interactive Config Generator (Method 3)

**Start here** - Use the existing `config-generator.sh` tool (already in repo):
- Interactive prompts
- No manual editing needed
- Safe, built-in tool
- Ready to paste into AWS

👉 **Jump to Method 3** below for interactive setup

---

## Alternative Methods

**Method 1:** Simple Manual Edit - for those who prefer direct control  
**Method 2:** Template-Based Script - for those who want a file-based approach  

---

## Prerequisites

- Your RDS endpoint, username, password (saved locally)
- Your EC2 key pair name
- Terminal/command line access
- The repository files (cloned locally)

---

## 📋 How It Works

The scripts now:
- ✅ Automatically fetch EC2 instance IP from metadata
- ✅ Dynamically display actual IP in completion message
- ✅ Support custom application directories
- ✅ Use all user inputs (no hardcoded values)
- ✅ Print configuration at startup

**No manual IP replacement needed!** The EC2 user data script automatically displays your instance IP.

---

## 📋 Template Files Available

The repository includes **template files** that are safe to commit to git:

| Template File | Purpose | Location |
|---------------|---------|----------|
| `deploy-config.sh.template` | Auto-generates deployment script | Root directory |
| `app-structure/database-init.sh.template` | Pre-initializes database (optional) | app-structure/ |

**Key:** Templates are in git. Your edited versions (with credentials) stay local and .gitignored.

See: `TEMPLATE_AND_GIT_GUIDE.md` for detailed git safety information.

---

## Method 3: Interactive Config Generator (3 minutes) ⭐ RECOMMENDED

**Easiest approach** - Use the existing interactive tool already in the repository:

### Step 1: Run the Generator

```bash
cd /path/to/ha-tt-app
chmod +x app-structure/config-generator.sh
./app-structure/config-generator.sh
```

### Step 2: Follow Interactive Prompts

The tool will ask:
```
╔════════════════════════════════════════════════════════════════╗
║        Configuration Generator - Hit Counter App              ║
╚════════════════════════════════════════════════════════════════╝

What would you like to generate?

  1) .env file (for local development)
  2) User data script (for EC2 deployment)
  3) Complete configuration package
  4) Environment variables only

  Q) Quit

Select option:
```

### Step 3: Choose Option 2 (User Data Script)

```
Select option: 2
```

### Step 4: Answer Configuration Questions

```
Database Type (postgres/mysql) [postgres]: postgres
Database Endpoint (e.g., mydb.xxxxx.rds.amazonaws.com): mydb.cp6cq4cisdiw.us-east-1.rds.amazonaws.com
Database User (e.g., postgres/admin): postgres
Database Password: YourSecurePassword123!
Database Name [ha-tt-db]: ha-tt-db
Database Port [5432]: 5432
Application Port [8000]: 8000
Application Directory [/opt/app]: /opt/app
```

### Step 5: Generated Files

The tool creates:
```
generated/
├── userdata-custom.sh          ← Your deployment script (ready for AWS)
├── .env                        ← Environment configuration
└── env-vars.sh                 ← Environment variables export
```

### Step 6: Copy to Clipboard

```bash
cat generated/userdata-custom.sh | pbcopy
```

**✅ Done! Script is ready for AWS**

---

## Method 1: Simple Manual Edit (2 minutes)

### Step 1: Copy the Base Script Locally

```bash
# Navigate to repository root
cd /path/to/ha-tt-app

# Copy the base script (which has no secrets embedded yet)
cp app-structure/userdata-ec2-only.sh ~/userdata-READY.sh
```

### Step 2: Edit with Your Values

```bash
nano ~/userdata-READY.sh
```

Find these lines (around line 20-25):
```bash
DB_TYPE="postgres"
DB_ENDPOINT="your-db-endpoint.rds.amazonaws.com"
DB_USER="postgres"
DB_PASSWORD="your-secure-password"
DB_NAME="ha-tt-db"
DB_PORT="5432"
```

Replace with YOUR values:
```bash
DB_TYPE="postgres"                                    # or "mysql"
DB_ENDPOINT="mydb.xxxxx.us-east-1.rds.amazonaws.com"  # Your endpoint
DB_USER="postgres"                                    # Your username
DB_PASSWORD="YourActualPassword123!"                  # Your password
DB_NAME="ha-tt-db"                                    # Keep this
DB_PORT="5432"                                        # Your port (5432 or 3306)
```

Save: Press `Ctrl+X`, then `Y`, then `Enter`

### Step 3: Verify

```bash
head -30 ~/userdata-READY.sh

# Should show your actual values
```

### Step 4: Copy to Clipboard

```bash
cat ~/userdata-READY.sh | pbcopy
```

### Step 5: Paste into AWS

1. AWS Console → EC2 → Launch Templates
2. Create Launch Template
3. Scroll to User Data
4. Paste (Cmd+V)
5. Create template and launch

---

## Method 2: Automated Script Generation (3 minutes)

**Recommended:** Use the provided template file (nothing to type manually)

### Step 1: Copy Template File (From Repository)

The repository includes a template file. Simply copy it:

```bash
# Navigate to repository root
cd /path/to/ha-tt-app

# Copy the template
cp deploy-config.sh.template deploy-config.sh
```

**Why:** The template is pre-configured and safe to check into git (no secrets).

### Step 2: Edit Template With Your Values

```bash
nano deploy-config.sh
```

You'll see:
```bash
# ============================================
# EDIT THESE VALUES WITH YOUR RDS CREDENTIALS
# ============================================

DB_TYPE="postgres"
DB_ENDPOINT="your-rds-endpoint.rds.amazonaws.com"
DB_USER="your-rds-username"
DB_PASSWORD="your-rds-password"
DB_PORT="5432"
```

**Replace these lines** with YOUR actual RDS details:
```bash
DB_TYPE="postgres"                              # or "mysql"
DB_ENDPOINT="mydb.xxxxx.us-east-1.rds.amazonaws.com"  # Your endpoint
DB_USER="postgres"                              # Your username
DB_PASSWORD="YourSecurePass123!"                # Your password
DB_PORT="5432"                                  # 5432 or 3306
```

Save & exit (Ctrl+X, Y, Enter)

**Important:** This file is .gitignored (won't be committed to git)

### Step 2: Edit Config with Your Values

```bash
nano ~/deploy-config.sh
```

Change these lines to YOUR RDS details:
```bash
DB_TYPE="postgres"                              # or "mysql"
DB_ENDPOINT="your-rds-endpoint.rds.amazonaws.com"  # Your endpoint
DB_USER="your-username"                         # Your username
DB_PASSWORD="your-password"                     # Your password
DB_PORT="5432"                                  # 5432 or 3306
```

Save and exit (Ctrl+X, Y, Enter)

### Step 3: Run the Generator

```bash
bash ~/deploy-config.sh
```

Output:
```
✅ Script generated: ~/userdata-READY.sh
✅ Password is embedded locally (never shared)
✅ Ready to copy to AWS
```

### Step 4: Verify the Generated Script

```bash
head -30 ~/userdata-READY.sh

# Check that your values are there:
# DB_TYPE="postgres"
# DB_ENDPOINT="mydb.xxxxx.us-east-1.rds.amazonaws.com"
# DB_PASSWORD="YourPassword"
```

### Step 5: Copy to Clipboard

```bash
cat ~/userdata-READY.sh | pbcopy
```

### Step 6: Clean Up (Optional but Recommended)

```bash
# Delete the config file (no longer needed)
rm ~/deploy-config.sh

# The generated script stays in ~/userdata-READY.sh
```

### Step 7: Paste into AWS

Same as Method 1, Step 5

---

## Method 3: Using the config-generator.sh Tool

We also created an **interactive configuration generator**:

```bash
cd /Users/maneettaantony/Workspaces/DMI-C3-G3/dmi-c3-g3-demo-apps/ha-tt-app/app-structure

chmod +x config-generator.sh
./config-generator.sh
```

Follow the menu:
1. Select **Option 2** (Generate user data script)
2. Enter your RDS details when prompted
3. Script is generated in `./generated/userdata-custom.sh`
4. Copy to clipboard and paste into AWS

---

## Verification Checklist

Before pasting into AWS, verify:

```bash
# Check file exists
ls -lh ~/userdata-READY.sh

# Check it's not empty (should be ~355 lines)
wc -l ~/userdata-READY.sh

# Check your values are in there
grep DB_PASSWORD ~/userdata-READY.sh
grep DB_ENDPOINT ~/userdata-READY.sh

# Make sure it starts with shebang
head -1 ~/userdata-READY.sh
# Should output: #!/bin/bash
```

---

## Security Best Practices

### Do ✅
- ✅ Keep config files local only
- ✅ Delete config files after use
- ✅ Use restricted file permissions
- ✅ Keep passwords in secure password manager
- ✅ Rotate RDS passwords regularly

### Don't ❌
- ❌ Share passwords in chat/email
- ❌ Commit config files to Git
- ❌ Leave passwords in shell history
- ❌ Store scripts with passwords in shared folders
- ❌ Use weak passwords

---

## Extra Security: Restricted Permissions

Make config files more secure:

```bash
# Create with restricted permissions
touch ~/deploy-config.sh
chmod 600 ~/deploy-config.sh  # Only you can read/write

# Edit it
nano ~/deploy-config.sh

# After generation, delete it
rm ~/deploy-config.sh

# The generated script is safe to keep
chmod 644 ~/userdata-READY.sh
```

---

## Clean Up After Deployment

Once you've pasted into AWS and launched the instance:

```bash
# Delete local script (AWS has its own copy in the instance)
rm ~/userdata-READY.sh

# Clear bash history to avoid password exposure
history -c
```

Or more thoroughly:
```bash
# Delete from history completely
export HISTFILE=/dev/null

# Then delete the history file
shred -u ~/.bash_history
```

---

## Troubleshooting

### Script Not Generated
```bash
# Check the script file exists
ls -la /Users/maneettaantony/Workspaces/DMI-C3-G3/dmi-c3-g3-demo-apps/ha-tt-app/app-structure/userdata-ec2-only.sh

# Check permissions
chmod +x ~/deploy-config.sh

# Run with bash explicitly
bash ~/deploy-config.sh
```

### Values Not Replaced
```bash
# Check config file format
cat ~/deploy-config.sh | grep DB_

# Verify sed syntax
sed -i '' 's/test/replaced/' ~/test.txt

# On Linux, use different syntax:
sed -i 's/test/replaced/' ~/test.txt  # No '' on Linux
```

### Password Has Special Characters
If your password has special characters like `$`, `&`, or quotes:

```bash
# Escape them in the config file
DB_PASSWORD="Your\$Password&123"

# Or use single quotes
DB_PASSWORD='Your$Password&123'

# Or use a here-doc
read -s -p "Enter password: " DB_PASSWORD
```

---

## File Locations

| File | Location | Keep? | Notes |
|------|----------|-------|-------|
| Base script | `app-structure/userdata-ec2-only.sh` | ✅ Yes | Original, can reuse |
| Config file | `~/deploy-config.sh` | ❌ No | Delete after use |
| Generated script | `~/userdata-READY.sh` | ⏳ Temp | Delete after AWS launch |
| AWS Instance | EC2 instance | ✅ Yes | Copy stays in instance |

---

## Comparison: Which Method?

| Method | Time | Complexity | Automation | Security |
|--------|------|-----------|-----------|----------|
| **Manual Edit** | 2 min | Very low | None | High (you control it) |
| **Automated Script** | 3 min | Low | High | High (generated locally) |
| **config-generator** | 3 min | Low (interactive) | High | High (interactive) |

---

## Step-by-Step Summary

### Quick Path (Method 1)
```
1. cp userdata-ec2-only.sh ~/userdata-READY.sh
2. nano ~/userdata-READY.sh          # Edit 6 lines
3. cat ~/userdata-READY.sh | pbcopy  # Copy to clipboard
4. Paste into AWS Launch Template
5. Launch instance
6. rm ~/userdata-READY.sh            # Clean up
```

### Automated Path (Method 2)
```
1. Create ~/deploy-config.sh with your values
2. nano ~/deploy-config.sh           # Edit config
3. bash ~/deploy-config.sh           # Generate
4. cat ~/userdata-READY.sh | pbcopy  # Copy to clipboard
5. Paste into AWS Launch Template
6. Launch instance
7. rm ~/deploy-config.sh ~/userdata-READY.sh  # Clean up
```

---

## AWS Launch Template Steps

After generating your script locally:

1. **AWS Console** → EC2 → Launch Templates
2. Click **Create Launch Template**
3. Fill in basic info:
   - Name: `web-app-template`
   - AMI: Ubuntu 22.04 LTS
   - Instance Type: t3.micro
   - Key pair: Your EC2 key pair
   - Security group: Your EC2 security group
4. Scroll to **Advanced Details** → **User Data**
5. **Paste** your generated script (Cmd+V or Ctrl+V)
6. Click **Create Launch Template**
7. Click **Launch Instance from Template**
8. Confirm and launch

---

## After Launch

```bash
# Get public IP from AWS Console
PUBLIC_IP="54.123.45.67"

# Test application
curl http://$PUBLIC_IP

# View logs
ssh -i ~/your-keypair.pem ubuntu@$PUBLIC_IP
sudo journalctl -u app -f
```

---

## Security Summary

✅ **Passwords never typed in chat/email**  
✅ **Credentials only on your local machine**  
✅ **Generated script can be safely discarded**  
✅ **AWS stores encrypted in instance**  
✅ **Full control over the process**  

---

## Related Documentation

- Main deployment guide: `DEPLOYMENT_GUIDE.md`
- EC2-only deployment: `docs/EC2_ONLY_DEPLOYMENT.md`
- Quick reference: `SCRIPTS_QUICK_REFERENCE.md`
- Config generator tool: `app-structure/config-generator.sh`

---

**Ready to deploy securely?**

Choose your method above and follow the steps. No passwords shared, all local.

