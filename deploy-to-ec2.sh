#!/bin/bash
# Quick Deploy Script - Run this after initial setup to update the backend
# Usage: ./deploy-to-ec2.sh your-key.pem ubuntu@YOUR_EC2_IP

if [ $# -ne 2 ]; then
    echo "Usage: $0 <path-to-pem-key> <ubuntu@EC2_IP>"
    exit 1
fi

KEY_FILE=$1
EC2_HOST=$2
APP_DIR="/home/ubuntu/compta"

echo "=========================================="
echo "Deploying to EC2..."
echo "=========================================="

# Upload backend code
echo "📦 Uploading backend code..."
rsync -avz --exclude 'node_modules' --exclude '.env' -e "ssh -i $KEY_FILE" backend/ $EC2_HOST:$APP_DIR/backend/

# Upload SQL scripts if they exist
if [ -f "schema.sql" ]; then
    echo "📦 Uploading schema.sql..."
    scp -i "$KEY_FILE" schema.sql $EC2_HOST:$APP_DIR/
fi

if [ -f "seed.sql" ]; then
    echo "📦 Uploading seed.sql..."
    scp -i "$KEY_FILE" seed.sql $EC2_HOST:$APP_DIR/
fi

# Restart backend
echo "🔄 Restarting backend..."
ssh -i "$KEY_FILE" "$EC2_HOST" << 'EOF'
cd /home/ubuntu/compta/backend
npm install --production
pm2 restart compta-backend
pm2 save
EOF

echo ""
echo "=========================================="
echo "✅ Deployment complete!"
echo "=========================================="
echo ""
echo "Check logs with:"
echo "  ssh -i $KEY_FILE $EC2_HOST 'pm2 logs compta-backend'"
echo ""
