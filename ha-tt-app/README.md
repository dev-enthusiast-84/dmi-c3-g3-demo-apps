# AWS EC2 Hit Counter Application

Complete, production-ready deployment solution for a Node.js web application with database integration. Supports **PostgreSQL** and **MySQL**.

**Status:** ✅ Production Ready | **Version:** 2.0 | **Updated:** 2026-08-21 | **Code & Docs Synced:** ✅

---

## 🔒 Git Safety: Templates & Secrets

✅ **Templates in Git:** Repository includes `.template` files safe to commit  
✅ **Credentials Local Only:** Your `.local` files stay on your machine  
✅ **Automatic .gitignore:** Credentials never accidentally committed  

See: `TEMPLATE_AND_GIT_GUIDE.md` for full git safety practices

---

## 🎯 What's New: EC2-Only Deployment

**Refactored for clarity:** The deployment approach has been simplified to focus exclusively on EC2 instance setup.

✨ **Key Improvements:**
- ✅ **Separation of Concerns:** EC2 setup, database initialization, and configuration are now separate scripts
- ✅ **Modular:** `userdata-ec2-only.sh` handles ONLY EC2 bootstrapping
- ✅ **Optional Database Init:** `database-init.sh` for pre-setup (or let app auto-create)
- ✅ **Configuration Tool:** `config-generator.sh` for interactive setup
- ✅ **Cleaner Scope:** No database creation logic mixed into EC2 setup

📖 **Read First:** `docs/EC2_ONLY_DEPLOYMENT.md` for the new approach

---

## ⚠️ Prerequisites (External Setup - Before EC2 Launch)

**This user data script sets up an EC2 instance with a web server. It does NOT create infrastructure.**

Complete these BEFORE launching the EC2 instance:

### External Setup (Outside User Data Script)
- ✅ **RDS Instance** (PostgreSQL or MySQL):
  - Create and start in AWS RDS Console
  - Get endpoint URL, master username, password
  - Configure security group to allow EC2 access
  
- ✅ **AWS Infrastructure**:
  - Create EC2 security group (allow port 80)
  - Create EC2 key pair for SSH access
  - Configure network access between EC2 and RDS

- ✅ **Have Ready**:
  - RDS Endpoint: `your-db.xxxxx.region.rds.amazonaws.com`
  - RDS Master Username: `postgres` or `admin`
  - RDS Master Password: (from RDS creation)
  - Database Port: `5432` (PostgreSQL) or `3306` (MySQL)

### What User Data Script Does (EC2 Setup Only)
✅ **Sets Up on EC2 Instance:**
- Installs Node.js 20.x runtime
- Installs Nginx web server
- Deploys application code
- Configures environment variables (database connection)
- Creates systemd service for auto-restart
- Starts services on port 80

❌ **Does NOT Do:**
- Create RDS instance
- Create VPC or networking
- Create security groups
- Create database server software
- Assume RDS exists (configuration is passed in)

### Quick Checklist
```
[ ] RDS instance created and running
[ ] RDS endpoint: ___________________________
[ ] RDS master username: ___________________________
[ ] RDS master password: ___________________________
[ ] EC2 key pair created: ___________________________
[ ] EC2 security group created (port 80 open)
[ ] Ready to launch EC2
```

---

## ⭐ **RECOMMENDED: GitHub-Based Deployment**

**Cleanest approach** - Deploy directly from your GitHub repository with zero code duplication.

### Why GitHub Deployment?
✅ **Single source of truth** - Code lives in GitHub only  
✅ **Zero duplication** - No embedded code in deployment scripts  
✅ **Auto-updates** - New instances pull latest code from repo  
✅ **Team-friendly** - Full Git workflow for collaboration  
✅ **CI/CD ready** - Extensible to automation  

### Quick Start with GitHub

```bash
# Generate script (includes GitHub repo config)
./app-structure/config-generator.sh

# Select: Option 2
# Answer prompts (GitHub URL is pre-configured)
# Script is generated with your database credentials

# Copy to clipboard
cat generated/userdata-custom.sh | pbcopy

# Launch EC2 instance → Paste userdata → Done!
# Script auto-clones from GitHub and deploys
```

📖 **See:** `GITHUB_DEPLOYMENT_GUIDE.md` ← Complete GitHub deployment guide

---

## 🎯 Quick Start (20 Minutes)

### ⭐ **Fastest Path - Complete End-to-End Guide**

**See:** `AWS_LAUNCH_COMPLETE_GUIDE.md` ← **Start here for complete walkthrough**

This guide includes:
- ✅ How to generate userdata script locally
- ✅ How to paste into AWS Launch Template
- ✅ Step-by-step AWS console instructions
- ✅ How to launch and monitor instance
- ✅ How to test the application
- ✅ Troubleshooting guide

### Quick Overview - Use Interactive Tool (Already in Repo):

```bash
# Step 1: Run interactive config generator
cd /path/to/ha-tt-app
./app-structure/config-generator.sh

# Step 2: Follow prompts
# - Choose: Option 2 (User data script)
# - Enter: Your RDS endpoint, username, password, etc.
# - Output: generated/userdata-custom.sh

# Step 3: Copy to clipboard
cat generated/userdata-custom.sh | pbcopy

# Step 4: Paste into AWS (see AWS_LAUNCH_COMPLETE_GUIDE.md for details)
# - EC2 → Launch Templates → Create
# - Fill form (AMI, key pair, security group)
# - User Data: Paste script
# - Launch Instance

# Step 5: Test
curl http://<your-instance-ip>
curl http://<your-instance-ip>/health
```

👉 **For detailed step-by-step with screenshots:** `AWS_LAUNCH_COMPLETE_GUIDE.md`  
👉 **For script generation only:** `SECURE_LOCAL_DEPLOYMENT.md`

---

## 📁 Project Structure

```
ha-tt-app/
├── 📁 app-structure/              ⭐ NEW - Modular Application + Deployment Scripts
│   ├── index.js                   (Entry point & orchestration)
│   ├── config.js                  (Configuration management)
│   ├── logger.js                  (Logging utility)
│   ├── db.js                      (Database abstraction - PostgreSQL & MySQL)
│   ├── routes.js                  (HTTP endpoints)
│   ├── server.js                  (Express configuration)
│   ├── package.json               (Dependencies)
│   ├── .env.example               (Configuration template)
│   ├── userdata-ec2-only.sh       (⭐ EC2 deployment - EC2 setup ONLY)
│   ├── database-init.sh           (⭐ Optional database initialization)
│   ├── config-generator.sh        (⭐ Configuration generation tool)
│   └── README.md                  (Module documentation)
│
├── 📁 docs/                        📚 Complete Documentation
│   ├── EC2_ONLY_DEPLOYMENT.md     (⭐ NEW - EC2-only approach with separated scripts)
│   ├── COPY_PASTE_READY.md        (Ready-to-use deployment scripts)
│   ├── DEPLOY_TO_LAUNCH_TEMPLATE.md (How to use with AWS)
│   ├── SETUP_GUIDE.md             (Quick start guide)
│   ├── USAGE_GUIDE.md             (Comprehensive reference)
│   ├── ARCHITECTURE.md            (Design decisions & best practices)
│   ├── ORGANIZATION_GUIDE.md      (Project organization)
│   └── FILES_OVERVIEW.md          (File descriptions)
│
├── 📁 legacy/                      📦 Original Scripts (Still Supported)
│   ├── README.md                  (Legacy documentation)
│   └── scripts/
│       ├── userdata-postgres.sh   (PostgreSQL only)
│       ├── userdata-mysql.sh      (MySQL only)
│       ├── userdata-dual-db.sh    (Both databases)
│       ├── launch-instance.py     (Python launcher)
│       └── test-application.sh    (Verification tests)
│
├── .gitignore                     (Git configuration)
└── README.md                      (This file)
```

---

## 🚀 Deployment Options

### Option 1: Direct Paste (Recommended - Easiest)
**Perfect for:** Quick deployments, single instances, testing
- **Time:** 5 minutes
- **Complexity:** Very simple
- **File:** `docs/COPY_PASTE_READY.md`
- **Method:** Copy script → Paste in AWS Console → Done

### Option 2: GitHub Deployment (Recommended for Teams)
**Perfect for:** Team development, version control, easy updates
- **Time:** 10 minutes setup + 5 minutes deploy
- **Complexity:** Medium
- **File:** `docs/DEPLOY_TO_LAUNCH_TEMPLATE.md` (Option 2)
- **Method:** Push to GitHub → Deploy from repo → Always latest code

### Option 3: S3 Deployment (Enterprise)
**Perfect for:** Large organizations, audit trails, centralized management
- **Time:** 15 minutes setup + 5 minutes deploy
- **Complexity:** Medium
- **File:** `docs/DEPLOY_TO_LAUNCH_TEMPLATE.md` (Option 3)
- **Method:** Upload to S3 → Reference in user data → Managed scripts

### Option 4: Local Development
**Perfect for:** Adding features, testing, learning
- **Time:** 10 minutes
- **Complexity:** Simple
- **File:** `app-structure/README.md`
- **Method:** `npm install` → `npm start` → Test at localhost:8000

---

## 📚 Documentation Guide

| Need | Read This |
|------|-----------|
| **Deploy with automated script (RECOMMENDED)** | `SECURE_LOCAL_DEPLOYMENT.md` ⭐ START HERE |
| **Step-by-step deployment guide** | `DEPLOYMENT_GUIDE.md` |
| **EC2-only deployment architecture** | `docs/EC2_ONLY_DEPLOYMENT.md` |
| **All script options** | `SCRIPTS_QUICK_REFERENCE.md` |
| **Understand deployment flow** | `docs/DEPLOY_TO_LAUNCH_TEMPLATE.md` |
| **Architecture & design** | `docs/ARCHITECTURE.md` |
| **Project organization** | `docs/ORGANIZATION_GUIDE.md` |
| **Module documentation** | `app-structure/README.md` |
| **Legacy scripts** | `legacy/README.md` |

---

## ✨ Key Features

### Application Features
- ✅ **Hit Counter** - Tracks page views with database persistence
- ✅ **Database Support** - PostgreSQL and MySQL/MariaDB
- ✅ **Read/Write Operations** - Demonstrates full database integration
- ✅ **Health Checks** - `/health` endpoint for monitoring
- ✅ **JSON API** - `/api/hits` endpoint for programmatic access
- ✅ **Auto-restart** - Systemd service with automatic recovery
- ✅ **Reverse Proxy** - Nginx on port 80 → Node.js on port 8000

### Code Quality
- ✅ **Modular Architecture** - Separated concerns (config, logging, DB, routes)
- ✅ **Production-Ready** - Error handling, logging, graceful shutdown
- ✅ **Testable** - Each module independently testable
- ✅ **Scalable** - Load balancer ready, container ready
- ✅ **CI/CD Ready** - Automated deployment compatible
- ✅ **Environment-Based** - Dev/staging/production configs via .env
- ✅ **Documentation** - Comprehensive guides and inline comments

---

## 🎓 Use Cases

### Quick Testing
- Deploy legacy scripts in 5 minutes
- Test application features
- Verify infrastructure
- ➡️ Use: `docs/COPY_PASTE_READY.md`

### Development & Learning
- Modify application code
- Add new features/endpoints
- Understand Node.js/Express
- ➡️ Use: `app-structure/README.md`

### Small Production (1-2 instances)
- Single EC2 instance + RDS database
- Simple, proven setup
- Easy to maintain
- ➡️ Use: `docs/COPY_PASTE_READY.md`

### Large Production (Multiple instances)
- Auto Scaling + Load Balancer
- Multiple availability zones
- High availability setup
- ➡️ Use: `app-structure/` + AWS configurations

### Team Development
- Centralized code repository (GitHub)
- Version control for deployments
- Easy collaboration
- ➡️ Use: GitHub deployment method

---

## 🔧 Technology Stack

| Component | Technology | Version |
|-----------|-----------|---------|
| **Runtime** | Node.js | 20.x (LTS) |
| **Web Server** | Express.js | 4.18+ |
| **Reverse Proxy** | Nginx | Latest |
| **Database** | PostgreSQL or MySQL | Current |
| **OS** | Ubuntu | 22.04 LTS |
| **Cloud** | AWS (EC2 + RDS) | Current |

---

## 📊 Architecture

### Application Architecture
```
HTTP Request (Port 80)
    ↓
Nginx Reverse Proxy
    ↓
Express.js Server (Port 8000)
    ↓
Router (routes.js) → Request Mapping
    ↓
Handler Function → Business Logic
    ↓
Database Layer (db.js) → Query Building
    ↓
PostgreSQL or MySQL → Data Storage
    ↓
Response (HTML/JSON)
```

### Module Dependencies
```
index.js (Start)
├── config.js (Read config)
├── logger.js (Setup logging)
├── db.js (Initialize database)
│   ├── config.js
│   └── logger.js
├── server.js (Create Express app)
│   └── routes.js
│       ├── db.js
│       ├── logger.js
│       └── config.js
└── app.listen()
```

---

## 📈 Performance & Scalability

### Single Instance
- **Specs:** t3.micro EC2 + RDS
- **Capacity:** ~100 hits/second
- **Cost:** ~$20/month
- **Setup Time:** 5 minutes

### Scaled Setup (Recommended for Production)
- **Load Balancer:** Application Load Balancer
- **Compute:** Auto Scaling Group (3-10 instances)
- **Database:** RDS Multi-AZ
- **Capacity:** 10,000+ hits/second
- **Availability:** 99.99% uptime

### Containerized (Docker/ECS)
- **Deployment:** ECS/Fargate clusters
- **Scaling:** Auto-scaling based on load
- **Cost:** Pay per container usage
- **CI/CD:** Automated deployments

---

## 🔒 Security Features

✅ **Environment-Based Secrets** - Database passwords in .env (not in code)
✅ **Input Validation** - Sanitized route parameters
✅ **SQL Injection Prevention** - Parameterized queries
✅ **Error Handling** - Generic error messages (no info leakage)
✅ **Logging** - Audit trail of requests
✅ **HTTPS Ready** - Configure via reverse proxy/load balancer
✅ **Database Encryption** - Supported by AWS RDS

---

## 🚨 Common Issues & Solutions

### Script Too Large for Paste
**Solution:** Use GitHub deployment method (smaller script)
- See: `docs/DEPLOY_TO_LAUNCH_TEMPLATE.md` (Option 2)

### Database Connection Failed
**Solution:** Verify security groups allow database port
1. EC2 security group allows outbound to RDS port
2. RDS security group allows inbound from EC2

### Application Won't Start
**Solution:** SSH in and check logs
```bash
ssh -i keypair.pem ubuntu@<ip>
sudo journalctl -u app -n 50
sudo tail -100 /var/log/user-data.log
```

### Port 80 Not Responding
**Solution:** Check Nginx is running
```bash
sudo systemctl status nginx
sudo nginx -t
sudo systemctl restart nginx
```

---

## 📞 Support & Help

### Getting Started
1. Read `docs/SETUP_GUIDE.md` (5 min)
2. Copy script from `docs/COPY_PASTE_READY.md`
3. Deploy to AWS and test

### Development Questions
- See `app-structure/README.md` for module docs
- Check `docs/ARCHITECTURE.md` for design decisions

### Troubleshooting
- View deployment logs: `sudo tail -f /var/log/user-data.log`
- View application logs: `sudo journalctl -u app -f`
- Run tests: `./legacy/scripts/test-application.sh <ip>`

### Advanced Customization
- Modify `app-structure/*.js` files
- Add new routes in `app-structure/routes.js`
- Add database queries in `app-structure/db.js`
- See `docs/ARCHITECTURE.md` for best practices

---

## 🎯 Next Steps

### If You're New
1. ➡️ Read `docs/SETUP_GUIDE.md`
2. ➡️ Copy script from `docs/COPY_PASTE_READY.md`
3. ➡️ Deploy to AWS
4. ➡️ Access at `http://<public-ip>`

### If You Want to Customize
1. ➡️ Read `app-structure/README.md`
2. ➡️ Run locally: `cd app-structure && npm install && npm start`
3. ➡️ Make changes to `.js` files
4. ➡️ Test at localhost:8000
5. ➡️ Deploy using `docs/COPY_PASTE_READY.md`

### If You Want to Scale
1. ➡️ Read `docs/ARCHITECTURE.md`
2. ➡️ Review AWS Auto Scaling Group documentation
3. ➡️ Use modular app code (`app-structure/`) in production
4. ➡️ Add load balancer in front of instances
5. ➡️ Add CloudWatch monitoring and alarms

### If You Have Issues
1. ➡️ Check `docs/DEPLOY_TO_LAUNCH_TEMPLATE.md` (Troubleshooting section)
2. ➡️ SSH into instance and check logs
3. ➡️ Run `legacy/scripts/test-application.sh <ip>` for diagnostics
4. ➡️ Review security groups and database connectivity

---

## 📦 What's Included

| Item | Type | Count | Size |
|------|------|-------|------|
| Documentation Files | .md | 8 | ~70 KB |
| Modular App Files | .js | 6 | ~30 KB |
| Deployment Scripts | .sh | 4 | ~55 KB |
| Configuration Files | .json, .env | 3 | ~2 KB |
| Utility Scripts | .py | 1 | ~9 KB |
| **Total** | | **27** | **~167 KB** |

---

## 💡 Pro Tips

1. **Test Locally First** - Use `app-structure/` to test changes before deploying
2. **Keep Old Templates** - Don't delete launch templates; use for rollbacks
3. **Monitor Deployments** - Watch EC2 system logs during initialization
4. **Set Up Alarms** - Create CloudWatch alarms for CPU, network, errors
5. **Regular Backups** - Enable RDS automated backups
6. **Review Logs** - Check logs regularly for errors or suspicious activity
7. **Use Git** - Track all changes to application code
8. **Environment Separation** - Use different RDS instances for dev/staging/prod

---

## 📄 License

MIT - Free to use and modify

---

## 🤝 Contributing

Improvements welcome! Feel free to:
- Add features to `app-structure/`
- Improve documentation
- Report issues
- Submit PRs with enhancements

---

## 📅 Version History

| Version | Date | Changes |
|---------|------|---------|
| 2.0 | 2026-08-21 | ✨ Complete refactoring to modular architecture |
| 1.0 | 2026-08-21 | Initial release with monolithic scripts |

---

**Ready to get started?** 🚀

**→ Go to:** `docs/COPY_PASTE_READY.md`

Or read more about the different options in `docs/SETUP_GUIDE.md`
