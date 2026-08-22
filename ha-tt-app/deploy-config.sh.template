#!/bin/bash

# ============================================
# DEPLOYMENT CONFIGURATION TEMPLATE
# ============================================
#
# GENERIC TEMPLATE - No hardcoded paths
#
# INSTRUCTIONS:
# 1. Copy this file: cp deploy-config.sh.template deploy-config.sh
# 2. Edit deploy-config.sh with YOUR values (this file stays local)
# 3. Update BASE_SCRIPT path below if needed (or use default)
# 4. Run: bash deploy-config.sh
# 5. Do NOT commit deploy-config.sh to git
#
# The deploy-config.sh file (with your actual credentials) is:
# - .gitignored (never committed)
# - Only used locally on your machine
# - Safe to delete after deployment
#

# ============================================
# CONFIGURATION: EDIT THESE VALUES
# ============================================

# Database type: "postgres" or "mysql"
DB_TYPE="postgres"

# RDS endpoint (e.g., mydb.xxxxx.us-east-1.rds.amazonaws.com)
DB_ENDPOINT="your-rds-endpoint.rds.amazonaws.com"

# RDS master username (e.g., postgres or admin)
DB_USER="your-rds-username"

# RDS master password (your actual password)
DB_PASSWORD="your-rds-password"

# Database port (5432 for postgres, 3306 for mysql)
DB_PORT="5432"

# ============================================
# BASE SCRIPT LOCATION
# ============================================
# Change this to your actual path if needed
# Default assumes script is in repository root

BASE_SCRIPT="${1:-.}/app-structure/userdata-ec2-only.sh"

# Or specify absolute path:
# BASE_SCRIPT="/path/to/ha-tt-app/app-structure/userdata-ec2-only.sh"

# Or find it automatically:
# BASE_SCRIPT="$(find . -name 'userdata-ec2-only.sh' 2>/dev/null | head -1)"

# ============================================
# SCRIPT GENERATION (Do not edit below)
# ============================================

if [ ! -f "$BASE_SCRIPT" ]; then
  echo "❌ Error: Base script not found"
  echo "   Expected: $BASE_SCRIPT"
  echo ""
  echo "Solutions:"
  echo "1. Run this script from repository root"
  echo "2. Update BASE_SCRIPT variable with correct path"
  echo "3. Provide path as argument: bash $0 /path/to/repo"
  exit 1
fi

echo "Using base script: $BASE_SCRIPT"

# Copy base script to temp location
cp "$BASE_SCRIPT" /tmp/userdata-template.sh

# Replace placeholders with your values
sed -i '' "s|DB_TYPE=\"postgres\"|DB_TYPE=\"$DB_TYPE\"|" /tmp/userdata-template.sh
sed -i '' "s|DB_ENDPOINT=\"your-db-endpoint.rds.amazonaws.com\"|DB_ENDPOINT=\"$DB_ENDPOINT\"|" /tmp/userdata-template.sh
sed -i '' "s|DB_USER=\"postgres\"|DB_USER=\"$DB_USER\"|" /tmp/userdata-template.sh
sed -i '' "s|DB_PASSWORD=\"your-secure-password\"|DB_PASSWORD=\"$DB_PASSWORD\"|" /tmp/userdata-template.sh
sed -i '' "s|DB_PORT=\"5432\"|DB_PORT=\"$DB_PORT\"|" /tmp/userdata-template.sh

# Copy to final location
cp /tmp/userdata-template.sh ~/userdata-READY.sh

# Clean up temp files
rm /tmp/userdata-template.sh

echo ""
echo "✅ Deployment script generated successfully!"
echo ""
echo "📍 Location: ~/userdata-READY.sh"
echo ""
echo "Next steps:"
echo "1. Copy to clipboard:     cat ~/userdata-READY.sh | pbcopy"
echo "2. AWS Console:           EC2 → Launch Templates → Create"
echo "3. User Data field:       Paste script"
echo "4. Launch instance:       Click Launch"
echo ""
echo "After deployment (optional cleanup):"
echo "   rm ~/userdata-READY.sh"
echo "   rm deploy-config.sh"
echo ""
