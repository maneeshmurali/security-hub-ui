# EC2 Setup Guide for Security Hub Dashboard

This guide provides detailed step-by-step instructions for setting up an EC2 instance to run the Security Hub Dashboard.

## 🎯 Quick Overview

The deployment script will run **inside the EC2 instance** after you connect to it. You need to:

1. **Create EC2 instance** with proper specifications
2. **Create IAM role** with Security Hub permissions
3. **Configure security group** to allow necessary ports
4. **Connect to instance** and run the deployment script

## 🏗️ Step 1: Create EC2 Instance

### 1.1 Launch EC2 Instance

1. **Go to AWS Console** → **EC2** → **Launch Instance**

2. **Choose AMI**:
   - **Amazon Linux 2023** (recommended)
   - **Ubuntu 20.04 LTS** (alternative)

3. **Choose Instance Type**:
   - **t3.medium** (2 vCPU, 4GB RAM) - minimum
   - **t3.large** (2 vCPU, 8GB RAM) - recommended
   - **t3.xlarge** (4 vCPU, 16GB RAM) - for high load

4. **Configure Instance Details**:
   - **Network**: Default VPC
   - **Subnet**: Any public subnet
   - **IAM role**: Leave empty (we'll create it next)
   - **Shutdown behavior**: Stop
   - **Enable termination protection**: Yes

5. **Add Storage**:
   - **Size**: 20GB (minimum)
   - **Type**: GP3 SSD
   - **Delete on termination**: No (recommended)

6. **Add Tags**:
   ```
   Key: Name
   Value: Security-Hub-Dashboard
   ```

7. **Configure Security Group**: Create new (see Step 1.2)

8. **Review and Launch**:
   - Choose existing key pair or create new
   - Launch instance

### 1.2 Create Security Group

1. **Go to EC2** → **Security Groups** → **Create Security Group**

2. **Basic Settings**:
   - **Name**: `security-hub-dashboard-sg`
   - **Description**: Security group for Security Hub Dashboard
   - **VPC**: Default VPC

3. **Inbound Rules**:

| Type | Protocol | Port Range | Source | Description |
|------|----------|------------|--------|-------------|
| SSH | TCP | 22 | Your IP | SSH access |
| HTTP | TCP | 80 | 0.0.0.0/0 | HTTP (for reverse proxy) |
| HTTPS | TCP | 443 | 0.0.0.0/0 | HTTPS (for reverse proxy) |
| Custom TCP | TCP | 8000 | 0.0.0.0/0 | Application port |

4. **Outbound Rules**:
   - **Type**: All traffic
   - **Protocol**: All
   - **Port Range**: All
   - **Destination**: 0.0.0.0/0

5. **Create Security Group**

## 🔐 Step 2: Create IAM Role

### 2.1 Create IAM Role

1. **Go to IAM** → **Roles** → **Create Role**

2. **Trusted Entity**:
   - **AWS Service**
   - **EC2** (use case)

3. **Permissions**:
   - **Create Policy** (we'll create custom policy)

4. **Role Details**:
   - **Role name**: `SecurityHubDashboardRole`
   - **Description**: IAM role for Security Hub Dashboard EC2 instance

5. **Create Role**

### 2.2 Create Permission Policy

1. **Go to IAM** → **Policies** → **Create Policy**

2. **JSON Tab** - Paste this policy:

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

3. **Policy Details**:
   - **Name**: `SecurityHubDashboardPolicy`
   - **Description**: Policy for Security Hub Dashboard read access

4. **Create Policy**

### 2.3 Attach Policy to Role

1. **Go to IAM** → **Roles** → **SecurityHubDashboardRole**

2. **Add Permissions** → **Attach Policies**

3. **Search and select**: `SecurityHubDashboardPolicy`

4. **Add Permissions**

### 2.4 Attach Role to EC2 Instance

1. **Go to EC2** → **Instances** → **Select your instance**

2. **Actions** → **Security** → **Modify IAM Role**

3. **IAM Role**: Select `SecurityHubDashboardRole`

4. **Update IAM Role**

## 🔗 Step 3: Connect to EC2 Instance

### 3.1 Get Instance Details

1. **Go to EC2** → **Instances**
2. **Select your instance**
3. **Note the Public IP address**

### 3.2 Connect via SSH

**For Amazon Linux 2023:**
```bash
ssh -i your-key.pem ec2-user@YOUR_EC2_IP
```

**For Ubuntu:**
```bash
ssh -i your-key.pem ubuntu@YOUR_EC2_IP
```

**Replace:**
- `your-key.pem` with your actual key file path
- `YOUR_EC2_IP` with your instance's public IP

### 3.3 Verify Connection

```bash
# Check if you're connected
whoami

# Check instance details
curl -s http://169.254.169.254/latest/meta-data/instance-id

# Check IAM role
aws sts get-caller-identity
```

## 🚀 Step 4: Deploy the Application

### 4.1 One-Command Deployment (Recommended)

```bash
# Download and run deployment script
curl -fsSL https://raw.githubusercontent.com/your-repo/security-hub/main/scripts/deploy.sh | bash -s -- -r https://github.com/your-repo/security-hub.git
```

### 4.2 Manual Deployment

```bash
# Clone repository
git clone https://github.com/your-repo/security-hub.git
cd security-hub

# Make scripts executable
chmod +x scripts/*.sh

# Run setup
./scripts/start.sh setup

# Configure environment
nano .env

# Start application
./scripts/start.sh start
```

## ✅ Step 5: Verify Deployment

### 5.1 Check Services

```bash
# Check if containers are running
docker-compose ps

# Check application health
curl -f http://localhost:8000/api/stats

# View logs
docker-compose logs -f security-hub-app
```

### 5.2 Access Application

- **Dashboard**: `http://YOUR_EC2_IP:8000`
- **API Docs**: `http://YOUR_EC2_IP:8000/docs`

## 🔧 Step 6: Security Hub Setup

### 6.1 Enable Security Hub (if not already enabled)

```bash
# Enable Security Hub in your region
aws securityhub enable-security-hub --region us-east-1

# Check Security Hub status
aws securityhub describe-hub --region us-east-1
```

### 6.2 Verify Permissions

```bash
# Test Security Hub access
aws securityhub get-findings --region us-east-1 --max-items 1

# Check for findings
aws securityhub list-findings --region us-east-1
```

## 🛡️ Step 7: Security Hardening

### 7.1 Configure Firewall

```bash
# Install UFW (if not installed)
sudo apt-get install ufw  # Ubuntu
sudo dnf install ufw      # Amazon Linux

# Allow SSH
sudo ufw allow ssh

# Allow application ports
sudo ufw allow 8000/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status
```

### 7.2 Generate SSL Certificates (Optional)

```bash
# Generate self-signed certificates
make ssl-generate

# Enable HTTPS in .env
# ENABLE_HTTPS=true
```

## 🔍 Step 8: Troubleshooting

### 8.1 Common Issues

#### Permission Denied
```bash
# Check IAM role
aws sts get-caller-identity

# Test Security Hub access
aws securityhub describe-hub --region us-east-1
```

#### Service Won't Start
```bash
# Check Docker
sudo systemctl status docker

# Check logs
docker-compose logs security-hub-app

# Check resources
free -h
df -h
```

#### No Findings Retrieved
```bash
# Check Security Hub
aws securityhub describe-hub --region us-east-1

# Check for findings
aws securityhub get-findings --region us-east-1 --max-items 1
```

### 8.2 Useful Commands

```bash
# Get instance metadata
curl -s http://169.254.169.254/latest/meta-data/

# Check IAM role
curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/

# Check Security Hub
aws securityhub describe-hub --region us-east-1

# Check application logs
docker-compose logs -f security-hub-app

# Restart application
docker-compose restart
```

## 📊 Step 9: Monitoring

### 9.1 Check Application Status

```bash
# Service status
docker-compose ps

# Application health
curl http://localhost:8000/api/stats

# Resource usage
docker stats
```

### 9.2 View Logs

```bash
# Application logs
docker-compose logs -f security-hub-app

# All logs
docker-compose logs -f

# Recent logs
docker-compose logs --tail=100 security-hub-app
```

## 🔄 Step 10: Maintenance

### 10.1 Update Application

```bash
# Pull latest changes
git pull

# Rebuild and restart
docker-compose down
docker-compose up -d --build
```

### 10.2 Backup Database

```bash
# Create backup
make db-backup

# List backups
ls -la backups/
```

### 10.3 Cleanup

```bash
# Clean Docker resources
make cleanup

# Remove old images
docker image prune -f
```

## 📋 Checklist

- [ ] EC2 instance created with t3.medium or larger
- [ ] Security group configured with required ports
- [ ] IAM role created with Security Hub permissions
- [ ] IAM role attached to EC2 instance
- [ ] Connected to EC2 instance via SSH
- [ ] Deployment script executed successfully
- [ ] Application accessible at http://YOUR_EC2_IP:8000
- [ ] Security Hub enabled and accessible
- [ ] Firewall configured
- [ ] SSL certificates generated (optional)

## 🆘 Support

If you encounter issues:

1. **Check logs**: `docker-compose logs -f security-hub-app`
2. **Verify permissions**: `aws sts get-caller-identity`
3. **Test Security Hub**: `aws securityhub describe-hub --region us-east-1`
4. **Check resources**: `free -h && df -h`
5. **Review this guide** for troubleshooting steps

## 🔗 Related Documentation

- [Main README](README.md)
- [Quick Start Guide](QUICK-START.md)
- [Docker Deployment Guide](README-Docker.md)
- [Detailed Deployment Steps](DEPLOYMENT.md)

---

**Note**: This guide assumes you're running the deployment script **inside the EC2 instance** after connecting via SSH. The script will handle Docker installation, application setup, and configuration automatically. 