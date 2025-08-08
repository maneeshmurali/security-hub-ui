#!/bin/bash

# AWS Security Hub Findings Application Deployment Script
# This script sets up the application on an Amazon Linux 2023 EC2 instance

set -e

echo "🚀 Starting Security Hub Application Deployment..."

# Update system packages
echo "📦 Updating system packages..."
sudo dnf update -y

# Install required packages
echo "🔧 Installing required packages..."
sudo dnf install -y \
    python3 \
    python3-pip \
    python3-devel \
    gcc \
    sqlite \
    git \
    curl \
    wget

# Create application directory
echo "📁 Creating application directory..."
sudo mkdir -p /opt/security-hub-app
sudo chown ec2-user:ec2-user /opt/security-hub-app

# Navigate to application directory
cd /opt/security-hub-app

# Create virtual environment
echo "🐍 Setting up Python virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip

# Install Python dependencies
echo "📚 Installing Python dependencies..."
pip install -r requirements.txt

# Create necessary directories
echo "📂 Creating data and log directories..."
mkdir -p data logs
chmod 755 data logs

# Copy systemd service file
echo "⚙️ Setting up systemd service..."
sudo cp security-hub-app.service /etc/systemd/system/
sudo systemctl daemon-reload

# Enable and start the service
echo "🚀 Starting the application service..."
sudo systemctl enable security-hub-app
sudo systemctl start security-hub-app

# Check service status
echo "📊 Checking service status..."
sudo systemctl status security-hub-app --no-pager

# Configure firewall (if using firewalld)
if command -v firewall-cmd &> /dev/null; then
    echo "🔥 Configuring firewall..."
    sudo firewall-cmd --permanent --add-port=8000/tcp
    sudo firewall-cmd --reload
fi

# Create environment file
echo "⚙️ Creating environment configuration..."
cat > .env << EOF
# AWS Settings
AWS_REGION=us-east-1

# Database settings
DATABASE_URL=sqlite:///./data/security_hub_findings.db

# S3 Settings (optional - uncomment and configure if needed)
# S3_BUCKET_NAME=your-security-hub-bucket
# S3_PREFIX=security-hub-findings/

# Polling settings
POLLING_INTERVAL_MINUTES=30

# API settings
HOST=0.0.0.0
PORT=8000
EOF

echo "✅ Deployment completed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Configure your .env file with your specific settings"
echo "2. Ensure your EC2 instance has the correct IAM role attached"
echo "3. Access the application at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8000"
echo ""
echo "🔧 Useful commands:"
echo "  - View logs: sudo journalctl -u security-hub-app -f"
echo "  - Restart service: sudo systemctl restart security-hub-app"
echo "  - Stop service: sudo systemctl stop security-hub-app"
echo "  - Check status: sudo systemctl status security-hub-app"
echo ""
echo "📚 For more information, see the README.md file" 