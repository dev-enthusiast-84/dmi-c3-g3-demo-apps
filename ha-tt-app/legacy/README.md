# AWS EC2 Hit Counter Application

A complete EC2 deployment solution with Node.js/Express web server and database integration. Supports both **MySQL** and **PostgreSQL**.

## 📋 What's Included

### User Data Scripts (Choose One)
- **userdata-mysql.sh** - For MySQL/MariaDB (port 3306)
- **userdata-postgres.sh** - For PostgreSQL (port 5432)
- **userdata-dual-db.sh** - Supports both MySQL and PostgreSQL (configure DB_TYPE variable)

### Utility Scripts
- **launch-instance.py** - Python/boto3 script for programmatic instance launching
- **test-application.sh** - Automated testing script to verify deployment

### Documentation
- **USAGE_GUIDE.md** - Comprehensive setup and troubleshooting guide
- **README.md** - This file

## 🚀 Quick Start

### Prerequisites
- AWS Account with EC2 and RDS permissions
- PostgreSQL database (RDS or self-hosted)
- Ubuntu 22.04 LTS AMI
- EC2 key pair for SSH access

### 3-Step Setup

#### Step 1: Choose the Right Script for Your Database

| Database | Script | Port | Default User |
|----------|--------|------|--------------|
| PostgreSQL | `userdata-postgres.sh` | 5432 | postgres |
| MySQL | `userdata-mysql.sh` | 3306 | admin |
| Both (configurable) | `userdata-dual-db.sh` | Configurable | See script |

**For PostgreSQL:** Edit `userdata-postgres.sh` and update these lines (lines 2-6):
```bash
DB_ENDPOINT="your-postgres-endpoint.rds.amazonaws.com"
DB_USER="postgres"
DB_PASSWORD="your-secure-password"
DB_NAME="hitcounter"
DB_PORT="5432"
```

**For MySQL:** Edit `userdata-mysql.sh` and update these lines (lines 2-6):
```bash
DB_ENDPOINT="your-mysql-endpoint.rds.amazonaws.com"
DB_USER="admin"
DB_PASSWORD="your-secure-password"
DB_NAME="hitcounter"
DB_PORT="3306"
```

**For Dual Support:** Edit `userdata-dual-db.sh` and update these lines (lines 2-7):
```bash
DB_TYPE="postgres"  # or "mysql"
DB_ENDPOINT="your-db-endpoint.rds.amazonaws.com"
DB_USER="postgres"  # or "admin" for MySQL
DB_PASSWORD="your-secure-password"
DB_NAME="hitcounter"
DB_PORT="5432"      # or "3306" for MySQL
```

#### Step 2: Launch Instance via AWS Console
1. Go to EC2 → Launch Templates → Create Launch Template
2. Configure:
   - **AMI**: Ubuntu 22.04 LTS
   - **Instance Type**: t3.micro
   - **Key Pair**: Your key pair
   - **Security Group**: Allow port 80 inbound
3. Advanced Details → User Data: Copy entire content of your chosen script:
   - `userdata-postgres.sh` for PostgreSQL
   - `userdata-mysql.sh` for MySQL
   - `userdata-dual-db.sh` for dual support
4. Create Launch Template
5. Launch Instance from Template

#### Step 3: Verify Deployment
Wait 5-10 minutes, then test:
```bash
chmod +x test-application.sh
./test-application.sh <instance-public-ip>
```

## 🗄️ Database Setup

### PostgreSQL Setup
```sql
-- Connect to your PostgreSQL database server
CREATE DATABASE hitcounter;
\c hitcounter
CREATE TABLE hits (
    id SERIAL PRIMARY KEY,
    hit_count INT DEFAULT 0,
    last_hit TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO hits (hit_count) VALUES (0);
```

**Security Group:** Allow inbound on **port 5432** from EC2 instance

### MySQL Setup
```sql
-- Connect to your MySQL database server
CREATE DATABASE hitcounter;
USE hitcounter;
CREATE TABLE hits (
    id INT AUTO_INCREMENT PRIMARY KEY,
    hit_count INT DEFAULT 0,
    last_hit TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
INSERT INTO hits (hit_count) VALUES (0);
```

**Security Group:** Allow inbound on **port 3306** from EC2 instance

### Database Auto-Creation
The application scripts will automatically create the table on first run if it doesn't exist, so the above SQL is optional.

## 📊 Application Features

- **Hit Counter** - Tracks total page views in database
- **Read/Write Operations** - Demonstrates database connectivity
- **Health Check** - `/health` endpoint for monitoring
- **Auto-restart** - Systemd service with automatic restart on failure
- **Reverse Proxy** - Nginx forwarding on port 80 to Node.js app on 8000

## 🧪 Testing

### Manual Test
```bash
# Test application
curl http://<instance-ip>

# Test health endpoint
curl http://<instance-ip>/health

# View logs
ssh -i keypair.pem ubuntu@<instance-ip> 'sudo journalctl -u app -f'
```

### Automated Test
```bash
chmod +x test-application.sh
./test-application.sh <instance-ip>
```

## 🚀 Alternative Launch Methods

### Method 1: Python Script (boto3)
```bash
python3 launch-instance.py \
  --region us-east-1 \
  --db-endpoint mydb.xxxxx.us-east-1.rds.amazonaws.com \
  --db-user postgres \
  --db-password 'secure-password' \
  --db-name hitcounter \
  --key-pair my-key-pair
```

### Method 2: AWS CLI
```bash
aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t3.micro \
  --key-name my-key-pair \
  --security-groups web-app-sg \
  --user-data file://userdata-for-console.sh
```

### Method 3: AWS CloudFormation
See USAGE_GUIDE.md for CloudFormation template example.

## 📁 Application Structure

Inside EC2 at `/opt/app/`:
- `package.json` - Node.js dependencies
- `index.js` - Express application
- `.env` - Environment configuration
- `node_modules/` - Installed packages

## 🔧 Troubleshooting

### Application Won't Start
```bash
# SSH into instance
ssh -i keypair.pem ubuntu@<instance-ip>

# Check service status
sudo systemctl status app

# View application logs
sudo journalctl -u app -n 50

# View user data initialization logs
sudo tail -100 /var/log/user-data.log
```

### Database Connection Error
```bash
# Verify database endpoint and credentials
# Check security group allows port 5432 from EC2

# Test connectivity
curl http://<instance-ip>/health

# Check logs for detailed error
sudo journalctl -u app | grep -i database
```

### Nginx Not Serving
```bash
# Test Nginx configuration
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx

# View Nginx error logs
sudo tail -50 /var/log/nginx/error.log
```

### Port 80 Not Responding
```bash
# Verify security group
aws ec2 describe-security-groups --group-ids <sg-id>

# Check iptables
sudo iptables -L

# Verify Nginx is listening
sudo netstat -tlnp | grep nginx
```

## 📊 Monitoring

### CloudWatch Integration
The application logs automatically go to `/var/log/` and can be monitored via CloudWatch Logs agent.

### Application Metrics
- **Hit Counter** - Total requests (stored in database)
- **Health Endpoint** - `/health` returns JSON with status
- **Logs** - Available via `journalctl` and `/var/log/`

## 💰 Cost Estimate

| Component | Hourly | Monthly |
|-----------|--------|---------|
| EC2 t3.micro | $0.0104 | $7.50 |
| RDS db.t3.micro | $0.017 | $12.00 |
| Data Transfer | Free (first 100GB) | - |
| **Total** | | **~$20/month** |

## 🧹 Cleanup

To avoid charges:
```bash
# Terminate EC2 instance
aws ec2 terminate-instances --instance-ids <instance-id>

# Delete RDS database
aws rds delete-db-instance --db-instance-identifier hitcounter --skip-final-snapshot

# Delete security groups (optional)
aws ec2 delete-security-group --group-id <sg-id>
```

## 📝 Notes

- **Database Support**: Choose between PostgreSQL (5432) or MySQL (3306)
- **Node.js Version**: 20.x (LTS)
- **Server**: Nginx reverse proxy + Express.js
- **Table Auto-creation**: The application creates the `hits` table automatically on first run
- **Counter Auto-init**: Hit counter is initialized to 0 if table is empty
- **Scripts**:
  - `userdata-postgres.sh` - PostgreSQL only (uses `pg` driver)
  - `userdata-mysql.sh` - MySQL only (uses `mysql2` driver)
  - `userdata-dual-db.sh` - Both databases (set DB_TYPE variable)

## 🔐 Security Considerations

For production:
1. Use AWS Secrets Manager for database credentials
2. Enable encryption for RDS
3. Configure VPC security groups properly
4. Use SSL/TLS certificates with Nginx
5. Enable CloudTrail for audit logging
6. Set up CloudWatch alarms for monitoring

## 📚 Additional Resources

- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [AWS RDS PostgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html)
- [Express.js Documentation](https://expressjs.com/)
- [node-postgres Documentation](https://node-postgres.com/)

## ❓ FAQ

**Q: Can I use MySQL instead of PostgreSQL?**
A: Yes, modify the script to use `mysql2` package and update SQL syntax.

**Q: What if I want to deploy my own application?**
A: Replace the embedded application in the script with your own code from GitHub.

**Q: How do I SSH into the instance?**
A: `ssh -i /path/to/keypair.pem ubuntu@<instance-public-ip>`

**Q: How do I view the application logs?**
A: `sudo journalctl -u app -f` on the EC2 instance

**Q: Can I scale this to multiple instances?**
A: Yes, use Auto Scaling Groups and Application Load Balancer (see USAGE_GUIDE.md)
