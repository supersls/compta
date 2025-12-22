#!/bin/bash
# EC2 User Data Script for Compta EI Application
# This script runs automatically when the EC2 instance is launched
# Add this script to the "User data" field when launching your EC2 instance

set -e  # Exit on error

# Log everything to a file
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "=========================================="
echo "Compta EI - EC2 User Data Setup"
echo "Started at: $(date)"
echo "=========================================="

# Configuration
DB_NAME="compta_ei"
DB_USER="compta_user"
DB_PASSWORD="ComptaPass$(openssl rand -hex 8)"
BACKEND_PORT=3000
APP_DIR="/home/ubuntu/compta"
GITHUB_REPO="https://github.com/supersls/compta.git"  # Update with your repo

# Update system
echo "📦 Updating system packages..."
apt update && apt upgrade -y

# Install PostgreSQL 15
echo "📦 Installing PostgreSQL 15..."
apt install -y postgresql postgresql-contrib

# Start PostgreSQL
systemctl start postgresql
systemctl enable postgresql

# Configure PostgreSQL
echo "🔧 Configuring PostgreSQL..."
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
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

# Install PM2
echo "📦 Installing PM2..."
npm install -g pm2

# Install Nginx
echo "📦 Installing Nginx..."
apt install -y nginx

# Install Git
echo "📦 Installing Git..."
apt install -y git

# Setup application directory
echo "📂 Setting up application..."
mkdir -p ${APP_DIR}
chown -R ubuntu:ubuntu ${APP_DIR}

# Clone repository (if using GitHub)
if [ ! -z "$GITHUB_REPO" ]; then
    echo "📥 Cloning repository..."
    sudo -u ubuntu git clone ${GITHUB_REPO} ${APP_DIR}
fi

# Run database schema
if [ -f "${APP_DIR}/schema.sql" ]; then
    echo "🗄️ Running database schema..."
    sudo -u postgres PGPASSWORD=${DB_PASSWORD} psql -U ${DB_USER} -d ${DB_NAME} -f ${APP_DIR}/schema.sql
    echo "✅ Schema created"
fi

# Run seed data if exists
if [ -f "${APP_DIR}/seed.sql" ]; then
    echo "🌱 Loading seed data..."
    sudo -u postgres PGPASSWORD=${DB_PASSWORD} psql -U ${DB_USER} -d ${DB_NAME} -f ${APP_DIR}/seed.sql
fi

# Install backend dependencies
if [ -d "${APP_DIR}/backend" ]; then
    echo "📦 Installing backend dependencies..."
    cd ${APP_DIR}/backend
    sudo -u ubuntu npm install --production
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

chown ubuntu:ubuntu ${APP_DIR}/backend/.env

# Create storage directories
mkdir -p ${APP_DIR}/storage/justificatifs/archives
chown -R ubuntu:ubuntu ${APP_DIR}/storage

# Start backend with PM2
echo "🚀 Starting backend..."
cd ${APP_DIR}/backend
sudo -u ubuntu pm2 start server.js --name compta-backend
sudo -u ubuntu pm2 startup systemd -u ubuntu --hp /home/ubuntu
sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u ubuntu --hp /home/ubuntu
sudo -u ubuntu pm2 save

# Configure Nginx
echo "🔧 Configuring Nginx..."
cat > /etc/nginx/sites-available/compta <<EOF
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

ln -sf /etc/nginx/sites-available/compta /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx
systemctl enable nginx

# Configure firewall
echo "🔒 Configuring firewall..."
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# Save credentials to a file for admin
cat > /home/ubuntu/CREDENTIALS.txt <<EOF
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

chown ubuntu:ubuntu /home/ubuntu/CREDENTIALS.txt
chmod 600 /home/ubuntu/CREDENTIALS.txt

echo ""
echo "=========================================="
echo "✅ Setup Complete!"
echo "=========================================="
echo "Credentials saved to: /home/ubuntu/CREDENTIALS.txt"
echo "Finished at: $(date)"
