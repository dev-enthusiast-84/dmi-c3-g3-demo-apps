# EC2 User Data Script - Complete Usage Guide

This guide explains how to use the provided user data script to launch an EC2 instance with a complete web application stack.

## What the Script Does

The user data script automatically:
- ✅ Installs Node.js 20.x and npm
- ✅ Installs Nginx as a reverse proxy
- ✅ Deploys an embedded Node.js/Express application
- ✅ Creates a MySQL database connection pool
- ✅ Sets up a hit-counter application with read/write database operations
- ✅ Configures Nginx to forward traffic on port 80 to the Node.js app on port 8000
- ✅ Creates a systemd service for automatic startup and restart
- ✅ Provides health check endpoints

## Prerequisites

1. **AWS Account** with EC2 and RDS permissions
2. **MySQL Database** (RDS instance or on-premises)
   - Database created and accessible from EC2 security group
   - Username and password created
3. **Ubuntu AMI** (Ubuntu 20.04 LTS, 22.04 LTS, or 24.04 LTS recommended)
4. **Security Group** configured to allow:
   - Inbound HTTP (port 80) from 0.0.0.0/0
   - Inbound HTTPS (port 443) from 0.0.0.0/0 (optional)
   - Outbound to RDS database port (typically 3306)

## Option 1: Launch via AWS Console

### Step 1: Create RDS Database (if not already created)

1. Go to AWS RDS Console
2. Create a MySQL database instance
3. Note down:
   - **Endpoint** (e.g., `mydb.xxxxx.us-east-1.rds.amazonaws.com`)
   - **Master Username** (e.g., `admin`)
   - **Master Password**
   - **Database Name** (e.g., `hitcounter`)

### Step 2: Create EC2 Launch Template

1. Go to EC2 Console → Launch Templates
2. Click "Create Launch Template"
3. Fill in the details:
   - **Template name:** `web-app-template`
   - **Template version description:** `v1`
   - **AMI:** Select Ubuntu 22.04 LTS (ami-xxxxxxxxx)
   - **Instance type:** `t3.micro` (free tier eligible)
   - **Key pair:** Select or create one for SSH access
   - **Security group:** Create or select one that allows port 80

4. **Advanced Details** → **User Data:**
   - Copy the entire `userdata-for-console.sh` script
   - Paste it in the User Data field

   **OR** use the templated version:
   ```bash
   #!/bin/bash
   DB_ENDPOINT="mydb.xxxxx.us-east-1.rds.amazonaws.com"
   DB_USER="admin"
   DB_PASSWORD="your-secure-password"
   DB_NAME="hitcounter"
   DB_PORT="3306"
   
   # Paste the rest of userdata-for-console.sh script here
   ```

5. Click "Create Launch Template"

### Step 3: Launch an Instance

1. Go to EC2 Console → Instances
2. Click "Launch Instances" → Select "Launch from Template"
3. Choose your newly created template
4. Set number of instances to 1
5. Click "Launch Instance"

### Step 4: Wait for Initialization

1. Select the instance and go to the "Details" tab
2. Wait for "Status Checks" to show "2/2 checks passed" (5-10 minutes)
3. Note the **Public IP Address** (e.g., `54.123.45.67`)

### Step 5: Test the Application

Open your browser and navigate to:
```
http://54.123.45.67
```

You should see a hit counter. Refresh the page to increment the counter.

## Option 2: Launch via CloudFormation

Save this as `template.yaml`:

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'Web Application with Database on EC2'

Parameters:
  DBEndpoint:
    Type: String
    Description: RDS Database endpoint (e.g., mydb.xxxxx.us-east-1.rds.amazonaws.com)
    
  DBUser:
    Type: String
    Default: admin
    Description: Database username
    
  DBPassword:
    Type: String
    NoEcho: true
    Description: Database password
    
  DBName:
    Type: String
    Default: hitcounter
    Description: Database name
    
  KeyPairName:
    Type: AWS::EC2::KeyPair::KeyName
    Description: EC2 Key Pair for SSH access

Resources:
  WebServerSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Security group for web server
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          CidrIp: 0.0.0.0/0
        - IpProtocol: tcp
          FromPort: 443
          ToPort: 443
          CidrIp: 0.0.0.0/0
        - IpProtocol: tcp
          FromPort: 22
          ToPort: 22
          CidrIp: 0.0.0.0/0

  EC2Instance:
    Type: AWS::EC2::Instance
    Properties:
      ImageId: ami-0c55b159cbfafe1f0  # Ubuntu 22.04 LTS - replace with your region
      InstanceType: t3.micro
      KeyName: !Ref KeyPairName
      SecurityGroupIds:
        - !Ref WebServerSecurityGroup
      UserData: !Base64
        Fn::Sub: |
          #!/bin/bash
          set -e
          exec > >(tee /var/log/user-data.log)
          exec 2>&1
          
          DB_ENDPOINT="${DBEndpoint}"
          DB_USER="${DBUser}"
          DB_PASSWORD="${DBPassword}"
          DB_NAME="${DBName}"
          DB_PORT="3306"
          APP_PORT=8000
          APP_DIR="/opt/app"
          
          # [Rest of userdata-for-console.sh script goes here]
          # Copy the entire script content between these markers
          
      Tags:
        - Key: Name
          Value: web-app-instance

Outputs:
  InstancePublicIP:
    Description: Public IP of the EC2 instance
    Value: !GetAtt EC2Instance.PublicIp
    
  WebApplicationURL:
    Description: URL to access the web application
    Value: !Sub 'http://${EC2Instance.PublicIp}'
```

Deploy with:
```bash
aws cloudformation create-stack \
  --stack-name web-app-stack \
  --template-body file://template.yaml \
  --parameters \
    ParameterKey=DBEndpoint,ParameterValue=your-rds-endpoint \
    ParameterKey=DBUser,ParameterValue=admin \
    ParameterKey=DBPassword,ParameterValue=your-password \
    ParameterKey=KeyPairName,ParameterValue=your-key-pair
```

## Option 3: Launch via AWS CLI

```bash
#!/bin/bash

# Set variables
REGION="us-east-1"
DB_ENDPOINT="mydb.xxxxx.us-east-1.rds.amazonaws.com"
DB_USER="admin"
DB_PASSWORD="your-secure-password"
DB_NAME="hitcounter"
KEY_PAIR_NAME="my-key-pair"
SECURITY_GROUP_ID="sg-0123456789abcdef0"
AMI_ID="ami-0c55b159cbfafe1f0"  # Ubuntu 22.04 LTS

# Create launch template
aws ec2 create-launch-template \
  --region $REGION \
  --launch-template-name web-app-template \
  --launch-template-data "{
    \"ImageId\": \"$AMI_ID\",
    \"InstanceType\": \"t3.micro\",
    \"KeyName\": \"$KEY_PAIR_NAME\",
    \"SecurityGroupIds\": [\"$SECURITY_GROUP_ID\"],
    \"UserData\": \"$(base64 -i userdata-for-console.sh)\"
  }"

# Launch instance from template
aws ec2 run-instances \
  --region $REGION \
  --launch-template LaunchTemplateName=web-app-template,Version=1 \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=web-app-instance}]'
```

## Troubleshooting

### Check Application Logs

SSH into the instance and run:

```bash
# View system user data logs
sudo tail -f /var/log/user-data.log

# View application logs
sudo journalctl -u app -f

# Check if services are running
sudo systemctl status app
sudo systemctl status nginx

# Check database connectivity
sudo -u ubuntu node -e "
  const mysql = require('mysql2/promise');
  mysql.createConnection({
    host: 'your-db-endpoint',
    user: 'admin',
    password: 'password',
    database: 'hitcounter'
  }).then(conn => {
    console.log('✓ Database connected');
    conn.end();
  }).catch(err => {
    console.error('✗ Connection failed:', err.message);
  });
"
```

### Common Issues

| Issue | Solution |
|-------|----------|
| **503 Bad Gateway** | Wait 2-3 more minutes for services to start. Check `systemctl status app` |
| **Database Connection Error** | Check security group allows outbound to RDS port 3306. Verify DB endpoint, username, password |
| **Nginx not serving traffic** | Check `sudo nginx -t` for syntax errors. Restart with `sudo systemctl restart nginx` |
| **High CPU/Memory usage** | Instance type too small. Scale up to t3.small or larger |
| **Port 80 not responding** | Check security group allows inbound on port 80. Check `sudo iptables -L` |

## Verification Steps

1. **Access the application:**
   ```bash
   curl http://<instance-ip>
   ```

2. **Check health endpoint:**
   ```bash
   curl http://<instance-ip>/health
   ```
   Expected response: `{"status":"healthy","timestamp":"2024-01-15T12:34:56.789Z"}`

3. **Verify database reads/writes:**
   - Open http://<instance-ip> in browser
   - Refresh multiple times
   - Hit counter should increment
   - Each number represents a database write operation

## Customization

### Change Application Port
Edit the `APP_PORT` variable in the user data script (default: 8000)

### Deploy from GitHub Instead
Uncomment the GitHub section and modify:
```bash
git clone https://github.com/YOUR-USERNAME/YOUR-REPO.git $APP_DIR
cd $APP_DIR
npm install --production
```

### Use Apache + PHP Instead
Replace the Node.js installation section with:
```bash
apt-get install -y apache2 php php-mysql php-cli

# Create application file at /var/www/html/index.php
```

### Enable HTTPS/SSL
Use AWS Certificate Manager and Application Load Balancer, or let's Encrypt:
```bash
apt-get install -y certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
```

## Cost Considerations

- **t3.micro EC2**: ~$0.0104/hour ($7.50/month)
- **RDS db.t3.micro**: ~$0.017/hour (~$12/month)
- **Data transfer**: First 100GB/month free
- **Total**: ~$20-25/month for full stack

## Cleanup

To avoid charges, delete resources when done:

```bash
# Delete CloudFormation stack (if used)
aws cloudformation delete-stack --stack-name web-app-stack

# Or manually delete:
# 1. Terminate EC2 instance
# 2. Delete RDS database
# 3. Delete security groups
# 4. Delete key pair (optional)
```

## Next Steps

- Set up Auto Scaling for high availability
- Add Application Load Balancer for load distribution
- Configure CloudWatch monitoring and alarms
- Set up CI/CD pipeline with CodePipeline/CodeDeploy
- Enable VPC Flow Logs for security monitoring
