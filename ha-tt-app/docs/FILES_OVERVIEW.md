# EC2 Hit Counter Application - Files Overview

Complete deployment package for AWS EC2 with Node.js web server and database support.

## 📁 Files in This Package

### 1. User Data Scripts (Choose One)

**Location:** `legacy/scripts/`

#### **userdata-postgres.sh** ⭐ PostgreSQL
- **Best for:** PostgreSQL/RDS databases
- **Database Port:** 5432
- **Default User:** postgres
- **Driver:** `pg` (node-postgres)
- **File Size:** 7.5 KB
- **Path:** `legacy/scripts/userdata-postgres.sh`

Edit these lines before using:
```bash
DB_ENDPOINT="your-postgres-endpoint.rds.amazonaws.com"
DB_USER="postgres"
DB_PASSWORD="your-secure-password"
DB_NAME="ha-tt-db"
DB_PORT="5432"
```

#### **userdata-mysql.sh** ⭐ MySQL
- **Best for:** MySQL/MariaDB databases
- **Database Port:** 3306
- **Default User:** admin
- **Driver:** `mysql2`
- **File Size:** 7.7 KB
- **Path:** `legacy/scripts/userdata-mysql.sh`

Edit these lines before using:
```bash
DB_ENDPOINT="your-mysql-endpoint.rds.amazonaws.com"
DB_USER="admin"
DB_PASSWORD="your-secure-password"
DB_NAME="ha-tt-db"
DB_PORT="3306"
```

#### **userdata-dual-db.sh** ⭐⭐ Both PostgreSQL & MySQL
- **Best for:** Need flexibility to use either database
- **Supports:** Both PostgreSQL and MySQL
- **Configuration:** Set `DB_TYPE="postgres"` or `DB_TYPE="mysql"` on line 3
- **File Size:** 13 KB
- **Path:** `legacy/scripts/userdata-dual-db.sh`

Edit these lines before using:
```bash
DB_TYPE="postgres"  # or "mysql"
DB_ENDPOINT="your-db-endpoint.rds.amazonaws.com"
DB_USER="postgres"  # or "admin" for MySQL
DB_PASSWORD="your-secure-password"
DB_NAME="ha-tt-db"
DB_PORT="5432"      # or "3306" for MySQL
```

### 2. Utility Scripts

**Location:** `legacy/scripts/`

#### **launch-instance.py** 🐍 Python Launcher
- **Purpose:** Programmatically launch EC2 instances from command line
- **Requires:** Python 3, boto3
- **File Size:** 9.3 KB
- **Path:** `legacy/scripts/launch-instance.py`
- **Features:**
  - Auto-detects Ubuntu 22.04 LTS AMI
  - Creates/uses security groups
  - Waits for instance initialization
  - Shows public IP when ready

**Usage:**
```bash
python3 legacy/scripts/launch-instance.py \
  --region us-east-1 \
  --db-endpoint "mydb.xxxxx.us-east-1.rds.amazonaws.com" \
  --db-user "postgres" \
  --db-password "your-password" \
  --db-name "ha-tt-db" \
  --key-pair "my-key-pair"
```

#### **test-application.sh** 🧪 Testing Script
- **Purpose:** Verify deployed application is working correctly
- **File Size:** 7.2 KB
- **Path:** `legacy/scripts/test-application.sh`
- **Tests:**
  1. Network connectivity
  2. HTTP 200 response
  3. Page title and layout
  4. Health endpoint
  5. Database read/write operations

**Usage:**
```bash
chmod +x legacy/scripts/test-application.sh
./legacy/scripts/test-application.sh <instance-public-ip>
```

### 3. Documentation

**Location:** `docs/`

#### **COPY_PASTE_READY.md** ⭐ Ready-to-Deploy Scripts
- **Best for:** Quick deployments without reading long docs
- **Content:** Ready-to-paste PostgreSQL and MySQL scripts
- **Read Time:** 2 minutes
- **Path:** `docs/COPY_PASTE_READY.md`

**When to use:** When you want to deploy immediately

#### **SETUP_GUIDE.md** 🚀 Quick Start
- **Best for:** First-time users
- **Content:** 
  - Step-by-step setup instructions
  - Database selection guide
  - Launch methods (console, CLI, Python)
  - Troubleshooting guide
  - Cleanup instructions
- **Read Time:** 5-10 minutes
- **Path:** `docs/SETUP_GUIDE.md`

**When to use:** Start here if you're new to the process

#### **DEPLOY_TO_LAUNCH_TEMPLATE.md** 📋 AWS Integration Guide
- **Best for:** Deploying to AWS Launch Template
- **Content:** Three deployment methods, troubleshooting, checklists
- **Read Time:** 10 minutes
- **Path:** `docs/DEPLOY_TO_LAUNCH_TEMPLATE.md`

**When to use:** When integrating with AWS Console

#### **USAGE_GUIDE.md** 📖 Comprehensive Guide
- **Best for:** Reference and advanced setup
- **Content:**
  - Detailed setup for each launch method
  - CloudFormation templates
  - AWS CLI examples
  - Common issues and solutions
  - Cost analysis
  - Monitoring and scaling
- **Path:** `docs/USAGE_GUIDE.md`

**When to use:** For complete details and advanced configurations

#### **ARCHITECTURE.md** 🏗️ Design & Best Practices
- **Best for:** Understanding architecture and design decisions
- **Content:** Module separation, scalability, security, best practices
- **Path:** `docs/ARCHITECTURE.md`

**When to use:** For technical design details

#### **ORGANIZATION_GUIDE.md** 📁 Project Structure
- **Best for:** Understanding project organization
- **Content:** Directory structure, module responsibilities
- **Path:** `docs/ORGANIZATION_GUIDE.md`

**When to use:** To understand how code is organized

#### **FILES_OVERVIEW.md** (This File)
- **Best for:** Understanding what each file does
- **Content:** Description of all files and their usage
- **Path:** `docs/FILES_OVERVIEW.md`

## 🎯 Quick Selection Guide

### I want to use PostgreSQL
→ Use `legacy/scripts/userdata-postgres.sh`
→ Read `docs/COPY_PASTE_READY.md`
→ Or read `docs/SETUP_GUIDE.md`

### I want to use MySQL
→ Use `legacy/scripts/userdata-mysql.sh`
→ Read `docs/COPY_PASTE_READY.md`
→ Or read `docs/SETUP_GUIDE.md`

### I'm not sure which database I'll use
→ Use `legacy/scripts/userdata-dual-db.sh`
→ Edit to set `DB_TYPE` variable
→ Read `docs/SETUP_GUIDE.md`

### I want to automate deployment
→ Use `legacy/scripts/launch-instance.py`
→ Read `docs/DEPLOY_TO_LAUNCH_TEMPLATE.md` (Option 2)
→ Or read `docs/USAGE_GUIDE.md` for details

### I want to develop/customize the app
→ Use code in `app-structure/`
→ Read `app-structure/README.md`
→ Or read `docs/ARCHITECTURE.md`

### I want comprehensive reference
→ Read root-level `README.md` for overview
→ Read `docs/USAGE_GUIDE.md` for details
→ Use appropriate scripts from `legacy/scripts/` or `app-structure/`

## 📊 What Each Script Installs

All scripts install:
- ✅ Node.js 20.x (LTS)
- ✅ npm (Node Package Manager)
- ✅ Nginx (reverse proxy)
- ✅ Express.js web server
- ✅ Database driver (PostgreSQL `pg` or MySQL `mysql2`)
- ✅ Environment configuration file
- ✅ Systemd service for auto-restart

## 🔄 Typical Workflow

1. **Choose** which database script to use
2. **Edit** the first 7 lines with your database details
3. **Copy** the entire script
4. **Paste** into EC2 Launch Template User Data field
5. **Launch** EC2 instance from template
6. **Wait** 5-10 minutes for initialization
7. **Test** with browser or test-application.sh
8. **Monitor** via EC2 console and logs

## 💾 File Statistics

### Legacy Scripts (`legacy/scripts/`)
| File | Type | Location | Purpose |
|------|------|----------|---------|
| userdata-postgres.sh | Script | legacy/scripts/ | PostgreSQL deployment |
| userdata-mysql.sh | Script | legacy/scripts/ | MySQL deployment |
| userdata-dual-db.sh | Script | legacy/scripts/ | Both databases |
| launch-instance.py | Python | legacy/scripts/ | Automated launcher |
| test-application.sh | Script | legacy/scripts/ | Verification tests |

### Modular Application (`app-structure/`)
| File | Type | Location | Purpose |
|------|------|----------|---------|
| index.js | JavaScript | app-structure/ | Entry point |
| config.js | JavaScript | app-structure/ | Configuration |
| logger.js | JavaScript | app-structure/ | Logging |
| db.js | JavaScript | app-structure/ | Database layer |
| routes.js | JavaScript | app-structure/ | HTTP routes |
| server.js | JavaScript | app-structure/ | Express setup |
| package.json | JSON | app-structure/ | Dependencies |
| .env.example | Text | app-structure/ | Config template |
| userdata-modular.sh | Script | app-structure/ | Deployment script |

### Documentation (`docs/`)
| File | Type | Purpose |
|------|------|---------|
| COPY_PASTE_READY.md | Markdown | Ready-to-use scripts |
| SETUP_GUIDE.md | Markdown | Quick start guide |
| DEPLOY_TO_LAUNCH_TEMPLATE.md | Markdown | AWS integration |
| USAGE_GUIDE.md | Markdown | Complete reference |
| ARCHITECTURE.md | Markdown | Design & best practices |
| ORGANIZATION_GUIDE.md | Markdown | Project structure |
| FILES_OVERVIEW.md | Markdown | File descriptions |

**Total Package Size:** ~180 KB (well-organized, production-ready)

## 🛠️ Customization Options

### Change Application Port
Edit line in user data script:
```bash
APP_PORT=8000  # Change to desired port
```

### Use Custom Application Code
Replace the embedded application:
```bash
# In user data script, replace the "Creating Node.js Application" section
# with GitHub clone instead:
git clone https://github.com/YOUR-USERNAME/YOUR-REPO.git $APP_DIR
cd $APP_DIR
npm install --production
```

### Enable HTTPS/SSL
Add to user data script:
```bash
apt-get install -y certbot python3-certbot-nginx
certbot --nginx -d your-domain.com
```

### Change Nginx Configuration
Edit the Nginx config section in user data script

### Add Environment Variables
Edit the `.env` file section in user data script

## 🚨 Important Notes

1. **Security:** Update database credentials before pasting script
2. **Ports:** Ensure security groups allow 80 (HTTP) and database port
3. **Database:** Table is auto-created on first run
4. **Initialization:** Takes 5-10 minutes total
5. **Logs:** Available via `journalctl` on EC2 instance
6. **Cost:** ~$20/month for t3.micro + RDS

## 📞 Support Resources

- **AWS EC2 Docs:** https://docs.aws.amazon.com/ec2/
- **AWS RDS Docs:** https://docs.aws.amazon.com/rds/
- **Express.js:** https://expressjs.com/
- **node-postgres:** https://node-postgres.com/
- **mysql2:** https://github.com/sidorares/node-mysql2

## ✅ Before You Start

Prepare these:
- ✅ AWS Account with EC2/RDS permissions
- ✅ PostgreSQL or MySQL database (RDS or self-hosted)
- ✅ EC2 Key Pair for SSH
- ✅ Database credentials (endpoint, username, password)
- ✅ Security groups configured for database access

## 🎓 Learning Path

**New to AWS?**
1. Read README.md
2. Read SETUP_GUIDE.md
3. Launch using AWS Console (simplest method)
4. Test with test-application.sh

**Experienced with AWS?**
1. Choose appropriate user data script
2. Edit configuration
3. Use launch-instance.py for automation
4. Deploy to Auto Scaling Group

**DevOps/Infrastructure?**
1. Read USAGE_GUIDE.md
2. Adapt for CloudFormation templates
3. Integrate with CI/CD pipeline
4. Add monitoring and alarms

## 🔐 Security Best Practices

- [ ] Use strong database passwords (16+ characters)
- [ ] Store credentials in AWS Secrets Manager
- [ ] Use VPC with private subnets for RDS
- [ ] Enable encryption for RDS
- [ ] Configure security groups with least privilege
- [ ] Enable CloudTrail for audit logs
- [ ] Use HTTPS with certificate manager
- [ ] Monitor with CloudWatch alarms

## 📈 Next Steps After Deployment

1. Set up monitoring (CloudWatch)
2. Configure alarms (high CPU, no connectivity)
3. Plan scaling strategy
4. Add load balancer for HA
5. Set up CI/CD pipeline
6. Configure backups
7. Plan disaster recovery

---

**Last Updated:** 2026-08-21
**Package Version:** 2.0 (Dual Database Support)
**Status:** Production Ready
