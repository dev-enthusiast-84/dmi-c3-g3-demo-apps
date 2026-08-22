# Quick Setup Guide - Choose Your Database

## Step 1: Select the Correct Script

### For PostgreSQL
Use: **`userdata-postgres.sh`**
- Default Port: 5432
- Default User: postgres

### For MySQL/MariaDB
Use: **`userdata-mysql.sh`**
- Default Port: 3306
- Default User: admin

### For Both (Switchable)
Use: **`userdata-dual-db.sh`**
- Edit line 3: `DB_TYPE="postgres"` or `DB_TYPE="mysql"`

## Step 2: Edit Configuration Variables

Open your chosen script file and edit the first 7 lines:

**PostgreSQL Example:**
```bash
DB_ENDPOINT="mydb-postgres.xxxxx.us-east-1.rds.amazonaws.com"
DB_USER="postgres"
DB_PASSWORD="your-secure-password-here"
DB_NAME="hitcounter"
DB_PORT="5432"
APP_PORT=8000
APP_DIR="/opt/app"
```

**MySQL Example:**
```bash
DB_ENDPOINT="mydb-mysql.xxxxx.us-east-1.rds.amazonaws.com"
DB_USER="admin"
DB_PASSWORD="your-secure-password-here"
DB_NAME="hitcounter"
DB_PORT="3306"
APP_PORT=8000
APP_DIR="/opt/app"
```

## Step 3: Launch EC2 Instance

### Via AWS Console

1. Go to **EC2 → Launch Templates**
2. Click **"Create Launch Template"**
3. Fill in:
   - Name: `web-app-template`
   - AMI: **Ubuntu 22.04 LTS** (or latest Ubuntu)
   - Instance Type: **t3.micro** (free tier eligible)
   - Key Pair: Select your key pair
   - Security Group: Create one allowing port 80 inbound

4. Scroll to **"Advanced Details"**
5. In the **"User Data"** section:
   - Copy the **entire contents** of your chosen script (after editing)
   - Paste it into the User Data field
   
6. Click **"Create Launch Template"**

7. Launch Instance from Template

### Via AWS CLI

```bash
# Make script executable
chmod +x userdata-postgres.sh  # or userdata-mysql.sh

# Launch instance
aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t3.micro \
  --key-name my-key-pair \
  --security-groups default \
  --user-data file://userdata-postgres.sh \
  --region us-east-1
```

### Via Python Script

```bash
python3 launch-instance.py \
  --region us-east-1 \
  --db-endpoint "mydb.xxxxx.us-east-1.rds.amazonaws.com" \
  --db-user "postgres" \
  --db-password "your-password" \
  --db-name "hitcounter" \
  --key-pair "my-key-pair"
```

## Step 4: Wait for Deployment

- Instance initialization takes **5-10 minutes**
- Application startup takes **2-3 additional minutes**
- Total time: **7-13 minutes**

Monitor progress:
1. Go to EC2 → Instances
2. Select your instance
3. Wait for Status Checks to show **"2/2 checks passed"**

## Step 5: Verify Application

### Get the Public IP
1. Select your instance in AWS Console
2. Copy the **Public IP Address**

### Test in Browser
```
http://<public-ip>
```

You should see a page with:
- "Total Page Hits" heading
- A counter showing a number
- "✓ Database Connected" status
- Last hit timestamp

### Refresh to Test Database Write
1. Refresh the page
2. The counter should increment (this is a database write operation)
3. Timestamp should update

### Run Automated Tests
```bash
chmod +x test-application.sh
./test-application.sh <public-ip>
```

## Database Connection Details

### PostgreSQL RDS
```
Host: mydb-postgres.xxxxx.us-east-1.rds.amazonaws.com
Port: 5432
Username: postgres
Database: hitcounter
Table: hits (auto-created)
```

### MySQL RDS
```
Host: mydb-mysql.xxxxx.us-east-1.rds.amazonaws.com
Port: 3306
Username: admin
Database: hitcounter
Table: hits (auto-created)
```

## Troubleshooting

### Application Shows "Database Connection Error"

1. **SSH into the instance:**
   ```bash
   ssh -i ~/path/to/keypair.pem ubuntu@<public-ip>
   ```

2. **Check application status:**
   ```bash
   sudo systemctl status app
   sudo journalctl -u app -n 50
   ```

3. **Verify database connectivity:**
   - Check RDS security group allows inbound on 5432 (PostgreSQL) or 3306 (MySQL)
   - Verify database credentials are correct
   - Ensure database exists and is accessible from the EC2 instance's security group

4. **View full initialization logs:**
   ```bash
   sudo tail -200 /var/log/user-data.log
   ```

### Port 80 Not Responding

```bash
# Check security group allows port 80
aws ec2 describe-security-groups --group-ids <sg-id>

# On instance, verify Nginx is running
sudo systemctl status nginx
sudo nginx -t  # Test configuration

# Restart Nginx
sudo systemctl restart nginx
```

### Node.js Application Not Running

```bash
# SSH into instance and check
sudo journalctl -u app -f

# Restart the service
sudo systemctl restart app
sudo systemctl status app

# Check logs for errors
sudo journalctl -u app -n 100 | grep -i error
```

## Application Structure

Once deployed, your application lives at:
```
/opt/app/
├── index.js              # Express application
├── package.json          # Dependencies
├── .env                  # Database configuration
└── node_modules/         # Installed packages
```

Services:
```
- Node.js app on port 8000 (internal)
- Nginx reverse proxy on port 80 (public)
```

## Testing Database Connectivity

### From EC2 Instance

**PostgreSQL:**
```bash
ssh -i keypair.pem ubuntu@<ip>
psql -h <db-endpoint> -U postgres -d hitcounter
SELECT * FROM hits;
```

**MySQL:**
```bash
ssh -i keypair.pem ubuntu@<ip>
mysql -h <db-endpoint> -u admin -p -D hitcounter
SELECT * FROM hits;
```

## Cleanup - Stop Charges

```bash
# Terminate EC2 instance
aws ec2 terminate-instances --instance-ids <instance-id>

# Delete RDS database
aws rds delete-db-instance \
  --db-instance-identifier hitcounter \
  --skip-final-snapshot

# Delete security groups
aws ec2 delete-security-group --group-id <sg-id>
```

## Important Notes

- **Auto-table creation**: The application automatically creates the `hits` table on first run
- **Database auto-init**: Hit counter starts at 0 if empty
- **Services auto-restart**: Application restarts automatically if it crashes
- **Port forwarding**: Nginx forwards port 80 requests to Node.js on port 8000
- **Logging**: All logs available via `journalctl` on the EC2 instance

## Next Steps

1. **Monitor**: Set up CloudWatch alarms for EC2 and RDS
2. **Scale**: Use Auto Scaling Groups if you need high availability
3. **Load Balance**: Add Application Load Balancer for multiple instances
4. **HTTPS**: Use AWS Certificate Manager + ALB for SSL/TLS
5. **CI/CD**: Deploy updates using CodePipeline/CodeDeploy

## Support

For detailed troubleshooting and advanced setup, see:
- `USAGE_GUIDE.md` - Comprehensive guide with all options
- `README.md` - Feature overview and architecture
- Application logs: `sudo journalctl -u app -f`
- User data logs: `sudo tail -f /var/log/user-data.log`
