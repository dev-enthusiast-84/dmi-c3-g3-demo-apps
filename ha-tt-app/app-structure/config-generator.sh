#!/bin/bash
# ============================================
# Configuration Generator Script
# ============================================
# PURPOSE: Generate userdata scripts from template
# USES: userdata-ec2-only.sh as single source of truth
# OUTPUT: generated/userdata-custom.sh with your credentials

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="${SCRIPT_DIR}/userdata-ec2-only.sh"
OUTPUT_DIR="${SCRIPT_DIR}/generated"

print_header() {
  echo ""
  echo "╔════════════════════════════════════════════════════════════════╗"
  echo "║        Configuration Generator - Hit Counter App              ║"
  echo "╚════════════════════════════════════════════════════════════════╝"
  echo ""
}

print_menu() {
  echo "What would you like to generate?"
  echo ""
  echo "  1) .env file (for local development)"
  echo "  2) User data script (for EC2 deployment)"
  echo "  3) Complete package (.env + userdata)"
  echo ""
  echo "  Q) Quit"
  echo ""
}

prompt_for_values() {
  echo "Enter your configuration values:"
  echo ""

  read -p "Database Type (postgres/mysql) [postgres]: " DB_TYPE
  DB_TYPE="${DB_TYPE:-postgres}"

  read -p "Database Endpoint (e.g., mydb.xxxxx.rds.amazonaws.com): " DB_ENDPOINT
  if [ -z "$DB_ENDPOINT" ]; then
    echo "✗ Database endpoint is required"
    return 1
  fi

  read -p "Database User (e.g., postgres/admin): " DB_USER
  if [ -z "$DB_USER" ]; then
    echo "✗ Database user is required"
    return 1
  fi

  read -sp "Database Password: " DB_PASSWORD
  echo ""
  if [ -z "$DB_PASSWORD" ]; then
    echo "✗ Database password is required"
    return 1
  fi

  read -p "Database Name [ha-tt-db]: " DB_NAME
  DB_NAME="${DB_NAME:-ha-tt-db}"

  if [ "$DB_TYPE" = "postgres" ]; then
    read -p "Database Port [5432]: " DB_PORT
    DB_PORT="${DB_PORT:-5432}"
  else
    read -p "Database Port [3306]: " DB_PORT
    DB_PORT="${DB_PORT:-3306}"
  fi

  read -p "Application Port [8000]: " APP_PORT
  APP_PORT="${APP_PORT:-8000}"

  read -p "Application Directory [/opt/app]: " APP_DIR
  APP_DIR="${APP_DIR:-/opt/app}"

  echo ""
  return 0
}

generate_env_file() {
  local output_file="$1"

  cat > "$output_file" <<EOF
# Application Configuration
NODE_ENV=production
APP_PORT=$APP_PORT

# Database Configuration
DB_TYPE=$DB_TYPE
DB_ENDPOINT=$DB_ENDPOINT
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_NAME=$DB_NAME
DB_PORT=$DB_PORT
EOF

  echo "✓ .env file generated: $output_file"
}

generate_user_data_script() {
  local output_file="$1"

  if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "✗ Error: Template file not found: $TEMPLATE_FILE"
    return 1
  fi

  # Copy template and replace configuration variables
  sed \
    -e "s|DB_TYPE=\".*\"|DB_TYPE=\"$DB_TYPE\"|" \
    -e "s|DB_ENDPOINT=\".*\"|DB_ENDPOINT=\"$DB_ENDPOINT\"|" \
    -e "s|DB_USER=\".*\"|DB_USER=\"$DB_USER\"|" \
    -e "s|DB_PASSWORD=\".*\"|DB_PASSWORD=\"$DB_PASSWORD\"|" \
    -e "s|DB_NAME=\".*\"|DB_NAME=\"$DB_NAME\"|" \
    -e "s|DB_PORT=\".*\"|DB_PORT=\"$DB_PORT\"|" \
    -e "s|APP_PORT=.*|APP_PORT=$APP_PORT|" \
    -e "s|APP_DIR=\".*\"|APP_DIR=\"$APP_DIR\"|" \
    "$TEMPLATE_FILE" > "$output_file"

  chmod +x "$output_file"
  echo "✓ User data script generated: $output_file"
  echo "  Ready to paste into AWS Launch Template"
}

# Main menu loop
print_header

while true; do
  print_menu
  read -p "Select option: " choice

  case "$choice" in
    1)
      mkdir -p "$OUTPUT_DIR"
      if prompt_for_values; then
        generate_env_file "$OUTPUT_DIR/.env"
      fi
      ;;
    2)
      mkdir -p "$OUTPUT_DIR"
      if prompt_for_values; then
        generate_user_data_script "$OUTPUT_DIR/userdata-custom.sh"
      fi
      ;;
    3)
      mkdir -p "$OUTPUT_DIR"
      if prompt_for_values; then
        generate_env_file "$OUTPUT_DIR/.env"
        generate_user_data_script "$OUTPUT_DIR/userdata-custom.sh"
        echo ""
        echo "✓ Complete configuration package generated:"
        echo "  - $OUTPUT_DIR/.env"
        echo "  - $OUTPUT_DIR/userdata-custom.sh"
      fi
      ;;
    Q|q)
      echo "Goodbye!"
      exit 0
      ;;
    *)
      echo "✗ Invalid option. Please select 1, 2, 3, or Q"
      ;;
  esac

  echo ""
done
