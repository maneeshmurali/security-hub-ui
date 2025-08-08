# AWS Security Hub Findings Dashboard

A comprehensive Python application that runs on AWS EC2 instances to fetch, store, and manage AWS Security Hub findings with a modern web interface. This application provides real-time monitoring, advanced filtering, and export capabilities for Security Hub findings.

## 🚀 Features

- **Automated Data Collection**: Periodically fetches Security Hub findings using Boto3
- **Local Storage**: Stores findings and their history in SQLite database
- **Optional S3 Backup**: Uploads findings to S3 bucket for backup and archival
- **Modern Web UI**: Beautiful, responsive dashboard with filtering and search capabilities
- **RESTful API**: Complete API for programmatic access to findings data
- **Change Tracking**: Monitors and stores history of finding changes over time
- **Export Capabilities**: Export findings as CSV or JSON
- **Real-time Statistics**: Live dashboard with finding statistics and distributions
- **IAM Role Authentication**: Secure authentication using AWS IAM roles (no hardcoded credentials)
- **Docker Support**: Complete containerized deployment with multiple profiles
- **Platform Independent**: Works on any Linux distribution (Ubuntu, Amazon Linux, etc.)

## 📋 Prerequisites

### AWS Requirements
- AWS Account with Security Hub enabled
- EC2 instance (t3.medium or larger recommended)
- IAM role with Security Hub read permissions
- Security Group with port 8000 open (and 80/443 for reverse proxy)

### System Requirements
- Linux distribution (Ubuntu 20.04+, Amazon Linux 2023, etc.)
- 4GB RAM minimum (8GB recommended)
- 20GB disk space minimum
- Internet connectivity for Docker installation

## 🏗️ Detailed Deployment Steps

### Step 1: Launch EC2 Instance

#### 1.1 Create EC2 Instance
```bash
# Launch EC2 instance with these specifications:
# - AMI: Amazon Linux 2023 or Ubuntu 20.04 LTS
# - Instance Type: t3.medium (2 vCPU, 4GB RAM)
# - Storage: 20GB GP3 SSD
# - Security Group: Custom (see Step 1.2)
```

#### 1.2 Configure Security Group
Create a security group with these rules:

| Type | Protocol | Port Range | Source | Description |
|------|----------|------------|--------|-------------|
| SSH | TCP | 22 | Your IP | SSH access |
| HTTP | TCP | 80 | 0.0.0.0/0 | HTTP (for reverse proxy) |
| HTTPS | TCP | 443 | 0.0.0.0/0 | HTTPS (for reverse proxy) |
| Custom TCP | TCP | 8000 | 0.0.0.0/0 | Application port |

#### 1.3 Create IAM Role

Create an IAM role with the following policy and attach it to your EC2 instance:

**Trust Policy:**
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
```

**Permission Policy:**
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "SecurityHubReadOnly",
            "Effect": "Allow",
            "Action": [
                "securityhub:GetFindings",
                "securityhub:DescribeHub",
                "securityhub:ListEnabledProductsForImport",
                "securityhub:ListFindings",
                "securityhub:ListInvitations",
                "securityhub:ListMembers",
                "securityhub:ListOrganizationAdminAccounts",
                "securityhub:ListSecurityControlDefinitions",
                "securityhub:ListStandardsControlAssociations",
                "securityhub:ListStandards",
                "securityhub:ListTagsForResource",
                "securityhub:GetEnabledStandards",
                "securityhub:GetInsights",
                "securityhub:GetInvitationsCount",
                "securityhub:GetMasterAccount",
                "securityhub:GetMembers",
                "securityhub:GetSecurityControlDefinition",
                "securityhub:GetStandardsControl",
                "securityhub:GetUsage"
            ],
            "Resource": "*"
        },
        {
            "Sid": "STSReadOnly",
            "Effect": "Allow",
            "Action": [
                "sts:GetCallerIdentity"
            ],
            "Resource": "*"
        }
    ]
}
```

**For S3 backup functionality (optional), add:**
```json
{
    "Sid": "S3OptionalAccess",
    "Effect": "Allow",
    "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket"
    ],
    "Resource": [
        "arn:aws:s3:::YOUR-S3-BUCKET-NAME",
        "arn:aws:s3:::YOUR-S3-BUCKET-NAME/*"
    ]
}
```

### Step 2: Connect to EC2 Instance

```bash
# Connect via SSH
ssh -i your-key.pem ec2-user@your-ec2-ip

# For Ubuntu instances, use:
ssh -i your-key.pem ubuntu@your-ec2-ip
```

### Step 3: Deploy the Application

#### Option A: One-Command Deployment (Recommended)

```bash
# Download and run the deployment script
curl -fsSL https://raw.githubusercontent.com/your-repo/security-hub/main/scripts/deploy.sh | bash -s -- -r https://github.com/your-repo/security-hub.git

# Or with custom options:
curl -fsSL https://raw.githubusercontent.com/your-repo/security-hub/main/scripts/deploy.sh | bash -s -- \
  -r https://github.com/your-repo/security-hub.git \
  -d /opt/security-hub \
  -p nginx
```

#### Option B: Manual Deployment

```bash
# 1. Clone the repository
git clone https://github.com/your-repo/security-hub.git
cd security-hub

# 2. Make scripts executable
chmod +x scripts/*.sh

# 3. Run initial setup
./scripts/start.sh setup

# 4. Configure environment
nano .env

# 5. Start the application
./scripts/start.sh start
```

### Step 4: Configure Environment

Edit the `.env` file with your specific settings:

```env
# AWS Configuration
AWS_REGION=us-east-1

# Application Configuration
APP_PORT=8000
HOST=0.0.0.0
POLLING_INTERVAL_MINUTES=30

# Database Configuration
DATABASE_URL=sqlite:///./data/security_hub_findings.db

# S3 Configuration (optional)
S3_BUCKET_NAME=your-security-hub-bucket
S3_PREFIX=security-hub-findings/

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

### Step 5: Start the Application

```bash
./scripts/start.sh start
# OR
make start
```

**Production Setup:**
- Application + Redis + SQLite
- Port 8000
- Optimized for production use

### Step 6: Verify Deployment

```bash
# Check service status
docker-compose ps

# Check application health
curl -f http://localhost:8000/api/stats

# View logs
docker-compose logs -f security-hub-app

# Get server IP
curl -s http://checkip.amazonaws.com
```

### Step 7: Access the Application

- **Dashboard**: `http://YOUR_EC2_IP:8000`
- **API Documentation**: `http://YOUR_EC2_IP:8000/docs`
- **Health Check**: `http://YOUR_EC2_IP:8000/api/stats`

## 🔧 Management Commands

### Service Management
```bash
# Start services
make start

# Stop services
make stop

# Restart services
make restart

# Check status
make status

# View logs
make logs
```

### Development Commands
```bash
# Start development environment
make dev

# Run tests
make test

# Access shell
make shell

# Build images
make build
```

### Health and Maintenance
```bash
# Check health
make health

# Cleanup resources
make cleanup

# Generate SSL certificates
make ssl-generate
```

### Database Operations
```bash
# Backup database
make db-backup

# Restore database
make db-restore

# Access database shell
make db-shell
```

## 🌐 Usage Guide

### Web Dashboard Features

1. **Statistics Dashboard**
   - Real-time finding counts by severity
   - Status distribution
   - Product distribution
   - Trend indicators

2. **Advanced Filtering**
   - Severity (Critical, High, Medium, Low, Informational)
   - Status (Active, Suppressed)
   - Product name
   - AWS Region
   - AWS Account
   - Date range
   - Compliance standards

3. **Finding Management**
   - Detailed finding view
   - Change history tracking
   - Export capabilities
   - Bulk operations

4. **Export Options**
   - CSV export with filters
   - JSON export with filters
   - Bulk export selected findings

### API Endpoints

#### Get Findings
```bash
GET /api/findings?severity=HIGH&status=ACTIVE&limit=100
```

#### Get Specific Finding
```bash
GET /api/findings/{finding_id}
```

#### Get Finding History
```bash
GET /api/findings/{finding_id}/history
```

#### Manual Fetch
```bash
POST /api/findings/fetch
```

#### Export CSV
```bash
GET /api/findings/export/csv?severity=CRITICAL
```

#### Export JSON
```bash
GET /api/findings/export/json?status=ACTIVE
```

#### Get Statistics
```bash
GET /api/stats
```

#### Scheduler Status
```bash
GET /api/scheduler/status
```

## 🔒 Security Configuration

### SSL/TLS Setup
```bash
# Generate self-signed certificates
make ssl-generate

# Enable HTTPS in .env
# ENABLE_HTTPS=true
```

### Firewall Configuration
```bash
# Allow application port
sudo ufw allow 8000/tcp

# Allow reverse proxy ports (if using nginx/traefik)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Enable firewall
sudo ufw enable
```

### Security Headers
The application includes security headers:
- X-Content-Type-Options: nosniff
- X-Frame-Options: DENY
- X-XSS-Protection: 1; mode=block
- Strict-Transport-Security (when HTTPS enabled)

## 📊 Monitoring and Logging

### Application Logs
```bash
# View application logs
docker-compose logs -f security-hub-app

# View all logs
docker-compose logs -f

# Check specific service
docker-compose logs -f redis
```

### Health Monitoring
```bash
# Check application health
curl http://localhost:8000/api/stats

# Check service status
docker-compose ps

# Monitor resource usage
docker stats
```

### Database Monitoring
```bash
# Check database size
ls -lh data/security_hub_findings.db

# Backup database
make db-backup

# Check database integrity
docker-compose exec security-hub-app sqlite3 /app/data/security_hub_findings.db "PRAGMA integrity_check;"
```

## 🔧 Troubleshooting

### Common Issues

#### 1. Permission Denied Errors
```bash
# Check IAM role attachment
aws sts get-caller-identity

# Verify Security Hub access
aws securityhub describe-hub --region us-east-1
```

#### 2. Service Won't Start
```bash
# Check Docker status
sudo systemctl status docker

# Check container logs
docker-compose logs security-hub-app

# Check disk space
df -h

# Check memory usage
free -h
```

#### 3. No Findings Retrieved
```bash
# Check Security Hub status
aws securityhub describe-hub --region us-east-1

# Check for findings manually
aws securityhub get-findings --region us-east-1 --max-items 1

# Review application logs
docker-compose logs -f security-hub-app
```

#### 4. Database Issues
```bash
# Check database permissions
ls -la data/

# Check SQLite installation
docker-compose exec security-hub-app sqlite3 --version

# Repair database
docker-compose exec security-hub-app sqlite3 /app/data/security_hub_findings.db "VACUUM;"
```

#### 5. Network Issues
```bash
# Check port availability
netstat -tlnp | grep :8000

# Check firewall status
sudo ufw status

# Test connectivity
curl -v http://localhost:8000/api/stats
```

### Log Locations
- **Application logs**: `docker-compose logs -f security-hub-app`
- **Database file**: `./data/security_hub_findings.db`
- **Configuration**: `./.env`
- **Docker logs**: `docker-compose logs`

## 🔄 Updates and Maintenance

### Update Application
```bash
# Pull latest changes
git pull

# Rebuild and restart
docker-compose down
docker-compose up -d --build

# Or use make command
make update
```

### Backup and Restore
```bash
# Create backup
make db-backup

# Restore from backup
make db-restore

# List backups
ls -la backups/
```

### Cleanup
```bash
# Clean up Docker resources
make cleanup

# Remove old images
docker image prune -f

# Clean up logs
docker system prune -f
```

## 📈 Performance Optimization

### Resource Recommendations
- **CPU**: 2+ vCPUs (t3.medium or larger)
- **Memory**: 4GB+ RAM (8GB recommended)
- **Storage**: 20GB+ SSD
- **Network**: Standard or better

### Configuration Tuning
```env
# Performance settings in .env
REDIS_MAX_MEMORY=512mb
WORKER_PROCESSES=4
POLLING_INTERVAL_MINUTES=30
```

### Scaling Considerations
- Use load balancer for multiple instances
- Consider RDS for database scaling
- Use ElastiCache for Redis scaling
- Implement auto-scaling groups

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

### Getting Help
1. Check the [troubleshooting section](#troubleshooting)
2. Review [application logs](#monitoring-and-logging)
3. Check [GitHub Issues](https://github.com/your-repo/security-hub/issues)
4. Open a new issue with detailed information

### Useful Resources
- [AWS Security Hub Documentation](https://docs.aws.amazon.com/securityhub/)
- [Docker Documentation](https://docs.docker.com/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)

## 🔗 Quick Links

- [Quick Start Guide](QUICK-START.md)
- [Docker Deployment Guide](README-Docker.md)
- [Detailed Deployment Steps](DEPLOYMENT.md)
- [API Documentation](http://localhost:8000/docs) (when running)

---

**Note**: This application is designed to run on EC2 instances with proper IAM roles. Ensure you have the necessary AWS permissions and Security Hub enabled in your account before deployment. 