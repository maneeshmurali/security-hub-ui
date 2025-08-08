# 🚀 Quick Start Guide - One Command Deployment

This guide provides the **simplest possible deployment** for the AWS Security Hub Findings Dashboard on **any Linux distribution**.

## ⚡ Ultra-Quick Start (3 Commands)

### Step 1: Download and Run Deployment Script
```bash
# Download the deployment script
curl -fsSL https://raw.githubusercontent.com/your-repo/security-hub/main/scripts/deploy.sh -o deploy.sh

# Make it executable
chmod +x deploy.sh

# Run deployment (replace with your repository URL)
./deploy.sh -r https://github.com/your-repo/security-hub.git
```

### Step 2: Wait for Completion
The script will automatically:
- ✅ Install Docker (if not present)
- ✅ Clone the repository
- ✅ Configure the environment
- ✅ Deploy the application
- ✅ Set up monitoring and backups

### Step 3: Access Your Dashboard
```bash
# Get your server IP
curl -s http://checkip.amazonaws.com

# Access the dashboard
# http://YOUR_SERVER_IP:8000
```

**That's it!** Your Security Hub Dashboard is now running.

## 🎯 Deployment Profiles

### Basic Production (Default)
```bash
./deploy.sh -r https://github.com/your-repo/security-hub.git
```
- Main application
- Redis cache
- SQLite database

### Development Environment
```bash
./deploy.sh -r https://github.com/your-repo/security-hub.git -p dev
```
- Hot reloading
- Debug mode
- PostgreSQL database



### Production with Nginx
```bash
./deploy.sh -r https://github.com/your-repo/security-hub.git -p nginx
```
- Nginx reverse proxy
- SSL termination
- Security headers

### Production with Traefik
```bash
./deploy.sh -r https://github.com/your-repo/security-hub.git -p traefik
```
- Traefik reverse proxy
- Automatic SSL
- Service discovery

## 🔧 Manual Quick Start (Alternative)

If you prefer manual steps:

### 1. Install Docker
```bash
# Universal Docker installation
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker
```

### 2. Clone and Deploy
```bash
# Clone repository
git clone https://github.com/your-repo/security-hub.git
cd security-hub

# Setup environment
cp env.docker .env

# Start application
make quick-start
```

### 3. Access Dashboard
```bash
# Get server IP
curl -s http://checkip.amazonaws.com

# Access dashboard
# http://YOUR_SERVER_IP:8000
```

## 📋 System Requirements

### Minimum Requirements
- **OS**: Any Linux distribution (Ubuntu, Amazon Linux, CentOS, etc.)
- **CPU**: 2 cores
- **RAM**: 4GB
- **Storage**: 20GB free space
- **Network**: Internet access

### Recommended Requirements
- **CPU**: 4 cores
- **RAM**: 8GB
- **Storage**: 50GB free space
- **Network**: Stable internet connection

## ⚙️ Configuration

### Essential Settings (Required)
Edit `.env` file:
```env
# AWS Region where Security Hub is enabled
AWS_REGION=us-east-1

# Application Port
APP_PORT=8000

# Polling interval (minutes)
POLLING_INTERVAL_MINUTES=30
```

### Optional Settings
```env
# S3 Backup (optional)
S3_BUCKET_NAME=your-backup-bucket

# Monitoring
PROMETHEUS_PORT=9090
GRAFANA_PORT=3000

# Security
ENABLE_HTTPS=false
```

## 🌐 Access URLs

After deployment, access these services:

| Service | URL | Description |
|---------|-----|-------------|
| Dashboard | http://YOUR_SERVER_IP:8000 | Main Security Hub Dashboard |
| API Docs | http://YOUR_SERVER_IP:8000/docs | FastAPI Documentation |


## 🛠️ Management Commands

### Basic Operations
```bash
# View logs
docker-compose logs -f

# Check status
docker-compose ps

# Restart services
docker-compose restart

# Stop services
docker-compose down
```

### Using Make Commands
```bash
# Start services
make start

# Stop services
make stop

# Check health
make health

# Create backup
make backup

# View logs
make logs
```

## 🔒 Security Setup

### AWS IAM Role (for EC2)
If deploying on EC2, ensure the instance has an IAM role with these permissions:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "securityhub:GetFindings",
                "securityhub:DescribeHub",
                "securityhub:ListFindings",
                "sts:GetCallerIdentity"
            ],
            "Resource": "*"
        }
    ]
}
```

### Firewall Configuration
```bash
# Allow application port
sudo ufw allow 8000/tcp



# Enable firewall
sudo ufw enable
```

## 🔧 Troubleshooting

### Common Issues

1. **Port Already in Use**
   ```bash
   # Change port in .env
   APP_PORT=8001
   make restart
   ```

2. **Permission Denied**
   ```bash
   # Fix permissions
   sudo chown -R $USER:$USER data logs backups
   chmod +x scripts/*.sh
   ```

3. **Docker Not Running**
   ```bash
   # Start Docker
   sudo systemctl start docker
   sudo systemctl enable docker
   ```

4. **Application Not Starting**
   ```bash
   # Check logs
   docker-compose logs security-hub-app
   
   # Restart services
   make restart
   ```

### Debug Mode
```bash
# Enable debug in .env
DEBUG=true
LOG_LEVEL=DEBUG

# Restart with debug
make restart
```

## 📊 Monitoring

### Health Checks
```bash
# Check application health
curl -f http://localhost:8000/api/stats

# Check all services
make health-all
```

### Performance Monitoring
```bash
# View container stats
docker stats

# Check resource usage
htop
```

## 💾 Backup and Recovery

### Manual Backup
```bash
# Create backup
make backup

# List backups
make backup-list

# Restore backup
make restore FILE=backup_20231201_120000.tar.gz
```



## 🔄 Updates

### Update Application
```bash
# Pull latest code
git pull

# Rebuild and restart
make prod-update
```

## 🆘 Getting Help

### Show All Commands
```bash
make help
```

### Check Status
```bash
make status
```

### View Logs
```bash
make logs
```

### Common Commands Reference
```bash
# Service management
make start stop restart status

# Development
make dev test shell

# Monitoring
make health



# Maintenance
make cleanup build ssl-generate
```

## ✅ Verification Checklist

After deployment, verify:
- [ ] Docker containers running (`docker-compose ps`)
- [ ] Application responding (`curl http://localhost:8000/api/stats`)
- [ ] Dashboard accessible (`http://YOUR_SERVER_IP:8000`)
- [ ] Logs showing no errors (`docker-compose logs`)
- [ ] Health checks passing (`make health`)

## 🎉 Success!

Your AWS Security Hub Findings Dashboard is now deployed and running!

**Next Steps:**
1. Configure AWS credentials/role
2. Set up monitoring alerts
3. Configure SSL certificates
4. Set up domain access

This deployment is **completely platform-independent** and works on any Linux distribution with Docker support! 