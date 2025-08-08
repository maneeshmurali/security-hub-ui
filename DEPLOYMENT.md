# 🚀 Complete Deployment Guide - Platform Independent

This guide provides **step-by-step instructions** to deploy the AWS Security Hub Findings Dashboard on **any Linux distribution** (Ubuntu, Amazon Linux, CentOS, etc.) using Docker. Everything runs in containers - no platform dependencies!

## 📋 Prerequisites

### System Requirements
- **Linux Distribution**: Any (Ubuntu, Amazon Linux, CentOS, RHEL, Debian, etc.)
- **Docker**: Version 20.10 or higher
- **Docker Compose**: Version 2.0 or higher
- **Git**: For cloning the repository
- **Internet Connection**: For downloading Docker images
- **AWS IAM Role**: With Security Hub permissions (for EC2 deployment)

### Minimum Hardware
- **CPU**: 2 cores
- **RAM**: 4GB
- **Storage**: 20GB free space
- **Network**: Internet access

## 🔧 Step 1: Install Docker (Platform Independent)

### Automatic Docker Installation
```bash
# Download and run Docker installation script
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add current user to docker group
sudo usermod -aG docker $USER

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Verify installation
docker --version
docker-compose --version
```

### Manual Docker Installation (Alternative)

#### For Ubuntu/Debian:
```bash
# Update package index
sudo apt-get update

# Install prerequisites
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group
sudo usermod -aG docker $USER
```

#### For Amazon Linux/RHEL/CentOS:
```bash
# Update system
sudo yum update -y

# Install Docker
sudo yum install -y docker

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### Verify Docker Installation
```bash
# Logout and login again for group changes to take effect
# OR run this command to apply group changes immediately
newgrp docker

# Test Docker installation
docker run hello-world

# Test Docker Compose
docker-compose --version
```

## 📥 Step 2: Clone and Setup Repository

### Clone the Repository
```bash
# Create directory for the application
mkdir -p ~/security-hub
cd ~/security-hub

# Clone the repository
git clone <repository-url> .
# OR if you have the files locally, copy them to this directory
```

### Verify Repository Structure
```bash
# Check if all required files are present
ls -la

# Expected files and directories:
# - docker-compose.yml
# - Dockerfile
# - env.docker
# - scripts/
# - nginx/
# - Makefile
# - README-Docker.md
```

## ⚙️ Step 3: Initial Setup

### Create Environment File
```bash
# Copy the environment template
cp env.docker .env

# Verify the file was created
ls -la .env
```

### Review and Configure Environment
```bash
# View the environment file
cat .env

# Edit the environment file (choose your preferred editor)
nano .env
# OR
vim .env
# OR
code .env  # if you have VS Code installed
```

### Essential Configuration (Required)
Edit `.env` and configure these **essential** settings:

```env
# =============================================================================
# ESSENTIAL CONFIGURATION - REQUIRED
# =============================================================================

# AWS Region where Security Hub is enabled
AWS_REGION=us-east-1

# Application Port (change if 8000 is already in use)
APP_PORT=8000

# Polling interval for Security Hub findings (in minutes)
POLLING_INTERVAL_MINUTES=30

# Default severity filters (comma-separated)
DEFAULT_SEVERITY_FILTER=CRITICAL,HIGH,MEDIUM,LOW,INFORMATIONAL

# Default status filters (comma-separated)
DEFAULT_STATUS_FILTER=ACTIVE,SUPPRESSED
```

### Optional Configuration (Advanced)
```env
# =============================================================================
# OPTIONAL CONFIGURATION - ADVANCED
# =============================================================================

# S3 Backup Configuration (leave empty to disable)
S3_BUCKET_NAME=
S3_PREFIX=security-hub-findings/

# Monitoring Configuration
PROMETHEUS_PORT=9090
GRAFANA_PORT=3000
GRAFANA_PASSWORD=admin

# Security Configuration
ENABLE_HTTPS=false
SSL_CERT_PATH=./nginx/ssl/cert.pem
SSL_KEY_PATH=./nginx/ssl/key.pem

# Performance Configuration
REDIS_MAX_MEMORY=256mb
WORKER_PROCESSES=4



# Logging Configuration
LOG_LEVEL=INFO
ENABLE_STRUCTURED_LOGGING=true
```

## 🚀 Step 4: Deploy the Application

### Option A: Quick Start (Recommended for First Time)
```bash
# Make scripts executable
chmod +x scripts/start.sh

# Run initial setup and start
./scripts/start.sh setup
./scripts/start.sh start
```

### Option B: Using Make Commands
```bash
# Make scripts executable
chmod +x scripts/start.sh

# Initial setup
make setup

# Start the application
make start
```

### Option C: Manual Docker Compose
```bash
# Create necessary directories
mkdir -p data logs config
mkdir -p nginx/ssl traefik

# Build and start services
docker-compose up -d --build
```

## 🔍 Step 5: Verify Deployment

### Check Service Status
```bash
# Check if all containers are running
docker-compose ps

# Expected output:
# Name                    Command               State           Ports
# -----------------------------------------------------------------------------
# security-hub-app       python main.py                       Up      0.0.0.0:8000->8000/tcp
# security-hub-redis     docker-entrypoint.sh redis ...       Up      0.0.0.0:6379->6379/tcp
```

### Check Application Health
```bash
# Test the application endpoint
curl -f http://localhost:8000/api/stats

# Expected output: JSON response with statistics
```

### Check Logs
```bash
# View application logs
docker-compose logs security-hub-app

# View all logs
docker-compose logs

# Follow logs in real-time
docker-compose logs -f
```

### Access the Application
```bash
# Get your server's IP address
curl -s http://checkip.amazonaws.com
# OR
hostname -I

# Access URLs:
# - Dashboard: http://YOUR_SERVER_IP:8000
# - API Documentation: http://YOUR_SERVER_IP:8000/docs
```

## 🎯 Step 6: Choose Deployment Profile

### Basic Production (Default)
```bash
# Already running from previous step
# Includes: App + Redis + SQLite
```

### Development Environment
```bash
# Stop current services
docker-compose down

# Start development environment
./scripts/start.sh start dev
# OR
make dev
```



### Production with Nginx Reverse Proxy
```bash
# Stop current services
docker-compose down

# Start with Nginx
./scripts/start.sh start nginx
# OR
make nginx
```

### Production with Traefik Reverse Proxy
```bash
# Stop current services
docker-compose down

# Start with Traefik
./scripts/start.sh start traefik
# OR
make traefik
```

## 🔒 Step 7: Security Configuration

### Generate SSL Certificates (Optional)
```bash
# Generate self-signed certificates
make ssl-generate

# Enable HTTPS in .env
# Edit .env and set:
# ENABLE_HTTPS=true
```

### Configure Firewall
```bash
# Allow application port
sudo ufw allow 8000/tcp



# Allow reverse proxy ports (if using nginx/traefik)
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS

# Enable firewall
sudo ufw enable

# Check firewall status
sudo ufw status
```

### AWS IAM Role Configuration (for EC2)
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
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::your-backup-bucket",
                "arn:aws:s3:::your-backup-bucket/*"
            ],
            "Condition": {
                "StringEquals": {
                    "aws:RequestTag/Application": "SecurityHub"
                }
            }
        }
    ]
}
```

## 📊 Step 8: Monitoring and Management

### Access Monitoring Dashboards
```bash
# If using monitoring profile, access:
# Prometheus: http://YOUR_SERVER_IP:9090
# Grafana: http://YOUR_SERVER_IP:3000 (admin/admin)
```

### Health Checks
```bash
# Check application health
make health-app

# Check all services health
make health-all

# Check Redis health
make health-redis
```

### View Logs
```bash
# Application logs
make logs-app

# All logs
make logs-all

# Follow logs
docker-compose logs -f
```

### Container Management
```bash
# Show running containers
make ps

# Show container statistics
make stats

# Show resource usage
make top
```

## 💾 Step 9: Backup and Recovery

### Create Backup
```bash
# Create manual backup
make backup

# List available backups
make backup-list
```

### Restore from Backup
```bash
# Restore from backup file
make restore FILE=backup_20231201_120000.tar.gz
```

### Configure Automated Backups
```bash
# Add to crontab for daily backups at 2 AM
crontab -e

# Add this line:
0 2 * * * cd /home/ubuntu/security-hub && make backup
```

## 🔧 Step 10: Troubleshooting

### Common Issues and Solutions

#### 1. Port Already in Use
```bash
# Check what's using the port
sudo netstat -tulpn | grep :8000

# Change port in .env
# APP_PORT=8001

# Restart services
make restart
```

#### 2. Permission Denied
```bash
# Fix directory permissions
sudo chown -R $USER:$USER data logs backups

# Fix script permissions
chmod +x scripts/*.sh
```

#### 3. Docker Not Running
```bash
# Start Docker service
sudo systemctl start docker

# Check Docker status
sudo systemctl status docker
```

#### 4. Memory Issues
```bash
# Check available memory
free -h

# Increase swap if needed
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

#### 5. Application Not Starting
```bash
# Check logs
docker-compose logs security-hub-app

# Check container status
docker-compose ps

# Restart services
make restart
```

### Debug Mode
```bash
# Enable debug in .env
# DEBUG=true
# LOG_LEVEL=DEBUG

# Restart with debug
make restart
```

## 🔄 Step 11: Updates and Maintenance

### Update Application
```bash
# Pull latest code
git pull

# Rebuild and restart
make prod-update
```

### Database Maintenance
```bash
# Backup before maintenance
make backup

# Access database shell
make db-shell

# Create database backup
make db-backup
```

### Clean Up Resources
```bash
# Clean up old containers and images
make cleanup

# Clean up old backups
make backup-cleanup
```

## 📈 Step 12: Scaling and Performance

### Horizontal Scaling
```bash
# Scale application to 3 instances
docker-compose up -d --scale security-hub-app=3
```

### Resource Limits
Edit `.env` for performance tuning:
```env
# Memory limits
REDIS_MAX_MEMORY=512mb
WORKER_PROCESSES=8

# Database connections
DB_POOL_SIZE=20
MAX_CONCURRENT_REQUESTS=200
```

### Performance Monitoring
```bash
# Monitor resource usage
make stats

# Check application performance
curl -w "@-" -o /dev/null -s "http://localhost:8000/api/stats" <<'EOF'
     time_namelookup:  %{time_namelookup}\n
        time_connect:  %{time_connect}\n
     time_appconnect:  %{time_appconnect}\n
    time_pretransfer:  %{time_pretransfer}\n
       time_redirect:  %{time_redirect}\n
  time_starttransfer:  %{time_starttransfer}\n
                     ----------\n
          time_total:  %{time_total}\n
EOF
```

## 🆘 Step 12: Support and Help

### Getting Help
```bash
# Show all available commands
make help

# Show service status
make status

# Check configuration
make env-show

# View logs
make logs
```

### Common Commands Reference
```bash
# Service management
make start stop restart status

# Development
make dev test shell

# Monitoring
make health prometheus grafana

# Backup
make backup backup-list restore

# Maintenance
make cleanup build ssl-generate
```

### Log Locations
```bash
# Application logs
tail -f logs/app.log

# Docker logs
docker-compose logs -f

# System logs
sudo journalctl -u docker
```

## ✅ Verification Checklist

After deployment, verify these items:

- [ ] Docker and Docker Compose installed and running
- [ ] Repository cloned and files present
- [ ] Environment file configured (`.env`)
- [ ] All containers running (`docker-compose ps`)
- [ ] Application responding (`curl http://localhost:8000/api/stats`)
- [ ] Dashboard accessible (`http://YOUR_SERVER_IP:8000`)
- [ ] Logs showing no errors (`docker-compose logs`)
- [ ] Health checks passing (`make health`)
- [ ] Backup working (`make backup`)
- [ ] Firewall configured (if applicable)
- [ ] SSL certificates generated (if using HTTPS)

## 🎉 Success!

Your AWS Security Hub Findings Dashboard is now deployed and running! 

**Access URLs:**
- **Dashboard**: http://YOUR_SERVER_IP:8000
- **API Documentation**: http://YOUR_SERVER_IP:8000/docs
- **Prometheus**: http://YOUR_SERVER_IP:9090 (if monitoring enabled)
- **Grafana**: http://YOUR_SERVER_IP:3000 (if monitoring enabled)

**Next Steps:**
1. Configure your AWS credentials/role
2. Set up automated backups
3. Configure monitoring alerts
4. Set up SSL certificates for production
5. Configure reverse proxy for domain access

This deployment is **completely platform-independent** and will work on any Linux distribution with Docker support! 