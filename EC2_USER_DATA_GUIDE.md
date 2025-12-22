# EC2 User Data Script Setup Guide

## How to Use User Data Script

The **User Data** script runs automatically when you launch a new EC2 instance, performing all setup steps without manual intervention.

### Step 1: Prepare Your Repository

Make sure your code is pushed to GitHub:
```bash
git add -A
git commit -m "Ready for deployment"
git push origin main
```

### Step 2: Update Script Configuration

Edit `ec2-user-data.sh` and update:
```bash
GITHUB_REPO="https://github.com/YOUR_USERNAME/compta.git"
```

### Step 3: Launch EC2 Instance with User Data

1. **Go to EC2 Console** → Launch Instance

2. **Configure Instance**:
   - **Name**: `compta-server`
   - **AMI**: Ubuntu 22.04 LTS
   - **Instance type**: `t2.small` (minimum 2GB RAM)
   - **Key pair**: Select or create a key pair
   - **Storage**: 20 GB gp3

3. **Configure Security Group**:
   - SSH (22): Your IP
   - HTTP (80): 0.0.0.0/0
   - HTTPS (443): 0.0.0.0/0

4. **Advanced details** → Scroll to **User data**:
   - Copy the entire contents of `ec2-user-data.sh`
   - Paste into the User data text box

5. **Launch Instance**

### Step 4: Wait for Setup to Complete

The setup takes about 5-10 minutes. To check progress:

```bash
# SSH to the instance
ssh -i your-key.pem ubuntu@YOUR_EC2_IP

# Check the setup log
tail -f /var/log/user-data.log

# Or check cloud-init logs
tail -f /var/log/cloud-init-output.log
```

### Step 5: Get Your Credentials

```bash
# View the credentials file
cat ~/CREDENTIALS.txt
```

This file contains:
- Database credentials
- API endpoints
- Backend status commands

### Step 6: Verify Installation

```bash
# Check backend status
pm2 status

# Check backend logs
pm2 logs compta-backend

# Test API
curl http://localhost:3000/api/health
```

### Step 7: Access Your Application

- **API**: `http://YOUR_EC2_IP/api`
- **Health Check**: `http://YOUR_EC2_IP/health`

---

## Alternative: Manual Upload Method

If your repository is private or you prefer manual setup:

### Option A: Upload files during launch

1. Launch EC2 **without** the GitHub clone part
2. After instance is running, upload files:
   ```bash
   scp -i your-key.pem -r backend schema.sql ubuntu@YOUR_EC2_IP:/home/ubuntu/compta/
   ```

### Option B: Use a modified User Data script

Remove this section from `ec2-user-data.sh`:
```bash
# Clone repository (if using GitHub)
if [ ! -z "$GITHUB_REPO" ]; then
    echo "📥 Cloning repository..."
    sudo -u ubuntu git clone ${GITHUB_REPO} ${APP_DIR}
fi
```

Then upload files after launch.

---

## Troubleshooting

### Check if User Data ran successfully:
```bash
cat /var/log/cloud-init-output.log
```

### If setup failed:
```bash
# Check the custom log
cat /var/log/user-data.log

# Re-run the setup manually
sudo bash /var/lib/cloud/instances/*/user-data.txt
```

### Database connection issues:
```bash
# Check PostgreSQL is running
sudo systemctl status postgresql

# Test database connection
psql -U compta_user -d compta_ei -h localhost
```

### Backend not starting:
```bash
# Check PM2 status
pm2 status

# View logs
pm2 logs compta-backend

# Restart backend
pm2 restart compta-backend
```

---

## Security Recommendations

After setup:

1. **Restrict SSH access**:
   - Update security group to allow SSH only from your IP

2. **Setup SSL** (if using domain):
   ```bash
   sudo apt install certbot python3-certbot-nginx
   sudo certbot --nginx -d yourdomain.com
   ```

3. **Change database password**:
   ```bash
   sudo -u postgres psql
   ALTER USER compta_user WITH PASSWORD 'new_secure_password';
   ```
   Then update `.env` file

4. **Setup automated backups**:
   ```bash
   # Add to crontab
   0 2 * * * pg_dump -U compta_user compta_ei > /home/ubuntu/backup-$(date +\%Y\%m\%d).sql
   ```

---

## Cost Estimate

**Monthly Cost (AWS us-east-1)**:
- EC2 t2.small: ~$17/month
- EBS 20GB: ~$2/month
- Data transfer: ~$1/month
- **Total**: ~$20/month

**Free Tier Eligible** (first 12 months):
- 750 hours/month of t2.micro (can use instead of t2.small)
- 30 GB EBS storage
- Potential cost: $0-5/month
