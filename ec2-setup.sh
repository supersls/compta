#!/bin/bash
# EC2 Setup Script for Compta EI Application
# Run this script on a fresh Ubuntu 22.04 EC2 instance
# Usage: sudo bash ec2-setup.sh

set -e  # Exit on error

echo "=========================================="
echo "Compta EI - EC2 Setup Script"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration variables
DB_NAME="compta_ei"
DB_USER="compta_user"
DB_PASSWORD="compta_password_$(openssl rand -hex 8)"
BACKEND_PORT=3000
APP_DIR="/home/ubuntu/compta"

echo -e "${GREEN}📦 Step 1: Update system packages${NC}"
sudo apt update && sudo apt upgrade -y

echo ""
echo -e "${GREEN}📦 Step 2: Install PostgreSQL 15${NC}"
sudo apt install -y postgresql postgresql-contrib

# Start PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql

echo ""
echo -e "${GREEN}🔧 Step 3: Configure PostgreSQL${NC}"

# Create database and user
sudo -u postgres psql <<EOF
-- Create database
CREATE DATABASE ${DB_NAME};

-- Create user
CREATE USER ${DB_USER} WITH ENCRYPTED PASSWORD '${DB_PASSWORD}';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};

-- Connect to database and grant schema privileges
\c ${DB_NAME}
GRANT ALL ON SCHEMA public TO ${DB_USER};
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ${DB_USER};
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ${DB_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ${DB_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO ${DB_USER};

\q
EOF

echo -e "${GREEN}✅ Database '${DB_NAME}' and user '${DB_USER}' created${NC}"

echo ""
echo -e "${GREEN}📦 Step 4: Install Node.js 20.x${NC}"
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Verify installation
node --version
npm --version

echo ""
echo -e "${GREEN}📦 Step 5: Install PM2 (Process Manager)${NC}"
sudo npm install -g pm2

echo ""
echo -e "${GREEN}📦 Step 6: Install Nginx${NC}"
sudo apt install -y nginx

echo ""
echo -e "${GREEN}📂 Step 7: Setup application directory${NC}"
sudo mkdir -p ${APP_DIR}
sudo chown -R ubuntu:ubuntu ${APP_DIR}

# If this script is run from the repo directory, copy files
if [ -d "backend" ] && [ -f "schema.sql" ]; then
    echo -e "${YELLOW}Copying application files...${NC}"
    cp -r backend ${APP_DIR}/
    cp schema.sql ${APP_DIR}/ 2>/dev/null || true
    cp seed.sql ${APP_DIR}/ 2>/dev/null || true
    echo -e "${GREEN}✅ Files copied${NC}"
fi

echo ""
echo -e "${GREEN}🗄️  Step 8: Run database schema${NC}"
if [ -f "${APP_DIR}/schema.sql" ]; then
    sudo -u postgres PGPASSWORD=${DB_PASSWORD} psql -U ${DB_USER} -d ${DB_NAME} -f ${APP_DIR}/schema.sql
    echo -e "${GREEN}✅ Schema created${NC}"
else
    echo -e "${YELLOW}⚠️  schema.sql not found, skipping...${NC}"
fi

# Run seed data if exists
if [ -f "${APP_DIR}/seed.sql" ]; then
    echo -e "${YELLOW}Running seed data...${NC}"
    sudo -u postgres PGPASSWORD=${DB_PASSWORD} psql -U ${DB_USER} -d ${DB_NAME} -f ${APP_DIR}/seed.sql
    echo -e "${GREEN}✅ Seed data loaded${NC}"
fi

echo ""
echo -e "${GREEN}📦 Step 9: Install backend dependencies${NC}"
if [ -d "${APP_DIR}/backend" ]; then
    cd ${APP_DIR}/backend
    npm install --production
    echo -e "${GREEN}✅ Backend dependencies installed${NC}"
else
    echo -e "${RED}❌ Backend directory not found${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🔧 Step 10: Create backend .env file${NC}"
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
LOCAL_STORAGE_PATH=/home/ubuntu/compta/storage/justificatifs

# AWS S3 (if using cloud storage)
# AWS_REGION=us-east-1
# AWS_S3_BUCKET=your-bucket-name
# AWS_ACCESS_KEY_ID=your-access-key
# AWS_SECRET_ACCESS_KEY=your-secret-key
EOF

echo -e "${GREEN}✅ .env file created${NC}"

echo ""
echo -e "${GREEN}📁 Step 11: Create storage directories${NC}"
mkdir -p ${APP_DIR}/storage/justificatifs/archives
sudo chown -R ubuntu:ubuntu ${APP_DIR}/storage

echo ""
echo -e "${GREEN}🚀 Step 12: Start backend with PM2${NC}"
cd ${APP_DIR}/backend
pm2 start server.js --name compta-backend
pm2 startup
pm2 save

echo ""
echo -e "${GREEN}🔧 Step 13: Configure Nginx${NC}"
sudo tee /etc/nginx/sites-available/compta <<EOF
server {
    listen 80;
    server_name _;  # Replace with your domain or EC2 IP

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
        proxy_http_version 1.1;
    }
}
EOF

# Enable site
sudo ln -sf /etc/nginx/sites-available/compta /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test and restart nginx
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl enable nginx

echo ""
echo -e "${GREEN}🔒 Step 14: Configure firewall${NC}"
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw --force enable

echo ""
echo "=========================================="
echo -e "${GREEN}✅ Setup Complete!${NC}"
echo "=========================================="
echo ""
echo -e "${YELLOW}Important Information:${NC}"
echo ""
echo "📊 Database:"
echo "  - Name: ${DB_NAME}"
echo "  - User: ${DB_USER}"
echo "  - Password: ${DB_PASSWORD}"
echo ""
echo "🚀 Backend:"
echo "  - Port: ${BACKEND_PORT}"
echo "  - Status: pm2 status"
echo "  - Logs: pm2 logs compta-backend"
echo ""
echo "🌐 Access:"
echo "  - API: http://YOUR_EC2_IP/api"
echo "  - Health: http://YOUR_EC2_IP/health"
echo ""
echo "💾 Save these credentials securely!"
echo ""
echo "Next steps:"
echo "1. Update security group to allow HTTP (80) and HTTPS (443)"
echo "2. Configure domain name (optional)"
echo "3. Setup SSL with certbot (optional): sudo certbot --nginx"
echo "4. Deploy frontend to S3"
echo ""
