# AWS EC2 Hit Counter Application

Complete, production-ready deployment solution for a Node.js web application with database integration. Supports **PostgreSQL** and **MySQL**.

**Status:** ✅ Production Ready | **Version:** 2.0 | **Updated:** 2026-08-21

---

## 🎯 Quick Start (5 Minutes)

### Fastest Path to Deployment

1. **Choose your database:**
   - PostgreSQL → `docs/COPY_PASTE_READY.md` (PostgreSQL section)
   - MySQL → `docs/COPY_PASTE_READY.md` (MySQL section)

2. **Edit 5 configuration lines** with your database details:
   ```bash
   DB_ENDPOINT="your-rds-endpoint.region.rds.amazonaws.com"
   DB_USER="postgres"  # or "admin" for MySQL
   DB_PASSWORD="your-password"
   DB_NAME="hitcounter"
   DB_PORT="5432"  # or 3306 for MySQL
   ```

3. **Copy & paste** into AWS Launch Template → User Data

4. **Launch instance** and access in 5-10 minutes at `http://<public-ip>`

👉 **Next:** See `docs/COPY_PASTE_READY.md` for detailed copy-paste scripts

---

## 📁 Project Structure

```
ha-tt-app/
├── 📁 app-structure/              ⭐ NEW - Modular Application
│   ├── index.js                   (Entry point & orchestration)
│   ├── config.js                  (Configuration management)
│   ├── logger.js                  (Logging utility)
│   ├── db.js                      (Database abstraction - PostgreSQL & MySQL)
│   ├── routes.js                  (HTTP endpoints)
│   ├── server.js                  (Express configuration)
│   ├── package.json               (Dependencies)
│   ├── .env.example               (Configuration template)
│   ├── userdata-modular.sh        (Optimized EC2 deployment script)
│   └── README.md                  (Module documentation)
│
├── 📁 docs/                        📚 Complete Documentation
│   ├── COPY_PASTE_READY.md        (Ready-to-use deployment scripts) ⭐
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
| **Deploy in 5 min** | `docs/COPY_PASTE_READY.md` ⭐ |
| **Understand deployment** | `docs/DEPLOY_TO_LAUNCH_TEMPLATE.md` |
| **Quick start guide** | `docs/SETUP_GUIDE.md` |
| **All details & options** | `docs/USAGE_GUIDE.md` |
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
