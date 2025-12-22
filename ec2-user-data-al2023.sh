#!/bin/bash
# EC2 User Data Script for Compta EI Application - Amazon Linux 2023
# This script runs automatically when the EC2 instance is launched
# Add this script to the "User data" field when launching your EC2 instance

set -e  # Exit on error

# Log everything to a file
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "=========================================="
echo "Compta EI - EC2 User Data Setup"
echo "Amazon Linux 2023"
echo "Started at: $(date)"
echo "=========================================="

# Configuration
DB_NAME="compta_ei"
DB_USER="compta_user"
DB_PASSWORD="ComptaPass$(openssl rand -hex 8)"
BACKEND_PORT=3000
APP_DIR="/home/ec2-user/compta"
GITHUB_REPO="https://github.com/supersls/compta.git"  # Update with your repo

# Update system
echo "📦 Updating system packages..."
dnf update -y

# Install PostgreSQL 15
echo "📦 Installing PostgreSQL 15..."
dnf install -y postgresql15-server postgresql15-contrib

# Initialize PostgreSQL
echo "🔧 Initializing PostgreSQL..."
postgresql-setup --initdb

# Start and enable PostgreSQL
systemctl start postgresql
systemctl enable postgresql

# Configure PostgreSQL to allow password authentication
echo "🔧 Configuring PostgreSQL authentication..."
PG_VERSION=15
PG_DATA="/var/lib/pgsql/data"

# Backup original files
cp ${PG_DATA}/pg_hba.conf ${PG_DATA}/pg_hba.conf.backup

# Update pg_hba.conf to allow password authentication
cat > ${PG_DATA}/pg_hba.conf <<EOF
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             all                                     peer
host    all             all             127.0.0.1/32            md5
host    all             all             ::1/128                 md5
EOF

# Restart PostgreSQL to apply changes
systemctl restart postgresql

# Configure PostgreSQL - Create database and user
echo "🗄️ Creating database and user..."
sudo -u postgres psql <<EOF
CREATE DATABASE ${DB_NAME};
CREATE USER ${DB_USER} WITH ENCRYPTED PASSWORD '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};
\c ${DB_NAME}
GRANT ALL ON SCHEMA public TO ${DB_USER};
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ${DB_USER};
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ${DB_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ${DB_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO ${DB_USER};
\q
EOF

echo "✅ Database created"

# Install Node.js 20.x
echo "📦 Installing Node.js 20.x..."
curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
dnf install -y nodejs

# Verify installation
node --version
npm --version

# Install PM2
echo "📦 Installing PM2..."
npm install -g pm2

# Install Nginx
echo "📦 Installing Nginx..."
dnf install -y nginx

# Install Git
echo "📦 Installing Git..."
dnf install -y git

# Setup application directory
echo "📂 Setting up application..."
mkdir -p ${APP_DIR}
chown -R ec2-user:ec2-user ${APP_DIR}

# Clone repository (if using GitHub)
if [ ! -z "$GITHUB_REPO" ]; then
    echo "📥 Cloning repository..."
    sudo -u ec2-user git clone ${GITHUB_REPO} ${APP_DIR}
fi

# Run database schema
if [ -f "${APP_DIR}/schema.sql" ]; then
    echo "🗄️ Running database schema..."
    PGPASSWORD=${DB_PASSWORD} psql -U ${DB_USER} -h localhost -d ${DB_NAME} -f ${APP_DIR}/schema.sql
    echo "✅ Schema created"
fi

# Run seed data if exists
if [ -f "${APP_DIR}/seed.sql" ]; then
    echo "🌱 Loading seed data..."
    PGPASSWORD=${DB_PASSWORD} psql -U ${DB_USER} -h localhost -d ${DB_NAME} -f ${APP_DIR}/seed.sql
fi

# Install backend dependencies
if [ -d "${APP_DIR}/backend" ]; then
    echo "📦 Installing backend dependencies..."
    cd ${APP_DIR}/backend
    sudo -u ec2-user npm install --production
fi

# Create .env file
echo "🔧 Creating .env file..."
cat > ${APP_DIR}/backend/.env <<EOF
NODE_ENV=production
PORT=${BACKEND_PORT}

# PostgreSQL Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=${DB_NAME}
DB_USER=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}
DATABASE_URL=postgresql://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}

# Storage Configuration
STORAGE_MODE=local
LOCAL_STORAGE_PATH=${APP_DIR}/storage/justificatifs

# AWS S3 (configure later if needed)
# AWS_REGION=us-east-1
# AWS_S3_BUCKET=your-bucket-name
# AWS_ACCESS_KEY_ID=your-access-key
# AWS_SECRET_ACCESS_KEY=your-secret-key
EOF

chown ec2-user:ec2-user ${APP_DIR}/backend/.env

# Create storage directories
mkdir -p ${APP_DIR}/storage/justificatifs/archives
chown -R ec2-user:ec2-user ${APP_DIR}/storage

# Start backend with PM2
echo "🚀 Starting backend..."
cd ${APP_DIR}/backend
sudo -u ec2-user pm2 start server.js --name compta-backend
sudo -u ec2-user pm2 startup systemd -u ec2-user --hp /home/ec2-user
sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u ec2-user --hp /home/ec2-user
sudo -u ec2-user pm2 save

# Configure Nginx
echo "🔧 Configuring Nginx..."
cat > /etc/nginx/conf.d/compta.conf <<EOF
server {
    listen 80;
    server_name _;

    # Backend API
    location /api {
        proxy_pass http://localhost:${BACKEND_PORT}/api;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    # Health check
    location /health {
        proxy_pass http://localhost:${BACKEND_PORT}/api/health;
    }
}
EOF

# Test and start Nginx
nginx -t
systemctl start nginx
systemctl enable nginx

# Configure firewall (Amazon Linux 2023 uses firewalld)
echo "🔒 Configuring firewall..."
systemctl start firewalld
systemctl enable firewalld
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --permanent --add-service=ssh
firewall-cmd --reload

# Save credentials to a file for admin
cat > /home/ec2-user/CREDENTIALS.txt <<EOF
========================================
COMPTA EI - CREDENTIALS
========================================

Database:
  - Name: ${DB_NAME}
  - User: ${DB_USER}
  - Password: ${DB_PASSWORD}
  - Connection: postgresql://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}

Backend:
  - Port: ${BACKEND_PORT}
  - Status: pm2 status
  - Logs: pm2 logs compta-backend
  - Restart: pm2 restart compta-backend

Access:
  - API: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/api
  - Health: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/health

Setup completed at: $(date)
EOF

chown ec2-user:ec2-user /home/ec2-user/CREDENTIALS.txt
chmod 600 /home/ec2-user/CREDENTIALS.txt

echo ""
echo "=========================================="
echo "✅ Setup Complete!"
echo "=========================================="
echo "Credentials saved to: /home/ec2-user/CREDENTIALS.txt"
echo "Finished at: $(date)"
