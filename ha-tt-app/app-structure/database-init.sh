#!/bin/bash
# ============================================
# Database Initialization Script
# ============================================
# PURPOSE: Initialize the database and table on existing RDS instance
# SCOPE: Runs BEFORE EC2 deployment (optional - app can auto-create)
# USAGE: ./database-init.sh <db-type> <endpoint> <user> <password> <db-name>

set -e

if [ $# -lt 5 ]; then
  echo "Usage: $0 <db-type> <endpoint> <user> <password> <db-name>"
  echo ""
  echo "Examples:"
  echo "  $0 postgres mydb.xxxxx.rds.amazonaws.com postgres mypassword ha-tt-db"
  echo "  $0 mysql mydb.xxxxx.rds.amazonaws.com admin mypassword ha-tt-db"
  exit 1
fi

DB_TYPE="$1"
DB_ENDPOINT="$2"
DB_USER="$3"
DB_PASSWORD="$4"
DB_NAME="$5"
DB_PORT="${6:-5432}"

echo "=== Database Initialization Script ==="
echo "Database Type: $DB_TYPE"
echo "Endpoint: $DB_ENDPOINT"
echo "User: $DB_USER"
echo "Database: $DB_NAME"
echo ""

if [ "$DB_TYPE" = "postgres" ]; then
  echo "Initializing PostgreSQL database..."

  # Check if psql is available
  if ! command -v psql &> /dev/null; then
    echo "Installing PostgreSQL client..."
    apt-get update
    apt-get install -y postgresql-client
  fi

  # Set connection environment
  export PGPASSWORD="$DB_PASSWORD"

  # Test connection first
  echo "Testing connection to RDS..."
  if ! psql -h "$DB_ENDPOINT" -U "$DB_USER" -p "$DB_PORT" -d "postgres" -c "SELECT 1;" > /dev/null 2>&1; then
    echo "❌ Error: Cannot connect to RDS"
    echo "   Endpoint: $DB_ENDPOINT"
    echo "   User: $DB_USER"
    echo "   Port: $DB_PORT"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Verify RDS endpoint is correct"
    echo "  2. Verify password is correct"
    echo "  3. Verify security group allows EC2 → RDS on port $DB_PORT"
    echo "  4. Verify RDS is in Running state"
    exit 1
  fi
  echo "✓ Connection successful"

  # Check if database already exists
  DB_EXISTS=$(psql -h "$DB_ENDPOINT" -U "$DB_USER" -p "$DB_PORT" -d "postgres" -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME';" 2>/dev/null || echo "")

  if [ -z "$DB_EXISTS" ]; then
    # Create database
    echo "Creating database: $DB_NAME"
    if ! psql -h "$DB_ENDPOINT" -U "$DB_USER" -p "$DB_PORT" -d "postgres" -c "CREATE DATABASE \"$DB_NAME\";" ; then
      echo "❌ Error: Failed to create database"
      exit 1
    fi
    echo "✓ Database created"
  else
    echo "✓ Database already exists: $DB_NAME"
  fi

  # Create table
  echo "Creating table: hits"
  if ! psql -h "$DB_ENDPOINT" -U "$DB_USER" -d "$DB_NAME" -p "$DB_PORT" <<EOF
CREATE TABLE IF NOT EXISTS hits (
  id SERIAL PRIMARY KEY,
  hit_count INT DEFAULT 0,
  last_hit TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO hits (hit_count) VALUES (0)
ON CONFLICT DO NOTHING;

SELECT COUNT(*) as row_count FROM hits;
EOF
  then
    echo "❌ Error: Failed to create table"
    exit 1
  fi

  echo "✓ PostgreSQL initialization complete"

elif [ "$DB_TYPE" = "mysql" ]; then
  echo "Initializing MySQL database..."

  # Check if mysql is available
  if ! command -v mysql &> /dev/null; then
    echo "Installing MySQL client..."
    apt-get update
    apt-get install -y mysql-client
  fi

  # Test connection first
  echo "Testing connection to RDS..."
  if ! mysql -h "$DB_ENDPOINT" -u "$DB_USER" -p"$DB_PASSWORD" -e "SELECT 1;" > /dev/null 2>&1; then
    echo "❌ Error: Cannot connect to RDS"
    echo "   Endpoint: $DB_ENDPOINT"
    echo "   User: $DB_USER"
    echo "   Port: 3306"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Verify RDS endpoint is correct"
    echo "  2. Verify password is correct"
    echo "  3. Verify security group allows EC2 → RDS on port 3306"
    echo "  4. Verify RDS is in Running state"
    exit 1
  fi
  echo "✓ Connection successful"

  # Create database
  echo "Creating database: $DB_NAME"
  if ! mysql -h "$DB_ENDPOINT" -u "$DB_USER" -p"$DB_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;" ; then
    echo "❌ Error: Failed to create database"
    exit 1
  fi
  echo "✓ Database created"

  # Create table
  echo "Creating table: hits"
  if ! mysql -h "$DB_ENDPOINT" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" <<EOF
CREATE TABLE IF NOT EXISTS hits (
  id INT AUTO_INCREMENT PRIMARY KEY,
  hit_count INT DEFAULT 0,
  last_hit TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

INSERT IGNORE INTO hits (id, hit_count) VALUES (1, 0);

SELECT COUNT(*) as row_count FROM hits;
EOF
  then
    echo "❌ Error: Failed to create table"
    exit 1
  fi

  echo "✓ MySQL initialization complete"

else
  echo "✗ Unsupported database type: $DB_TYPE"
  echo "Supported: postgres, mysql"
  exit 1
fi

echo ""
echo "=== Database Ready ==="
echo "Database: $DB_NAME"
echo "Table: hits"
echo ""
echo "You can now run the EC2 user data script with this database."
