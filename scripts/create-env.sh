#!/bin/bash

echo "🔧 Creating Basic .env File"
echo "==========================="

# Create a basic .env file
cat > .env << 'EOF'
# AWS Configuration
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_SESSION_TOKEN=

# Database Configuration
DATABASE_URL=postgresql://postgres:postgres@postgres:5432/security_hub
POSTGRES_DB=security_hub
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres

# Application Settings
HOST=0.0.0.0
PORT=8000
DEBUG=false
LOG_LEVEL=INFO

# Polling and Scheduling
POLLING_INTERVAL_MINUTES=1440
ENABLE_MULTI_REGION=true
MAX_REGIONS=0
MAX_PAGES_PER_REGION=50

# Security
SECRET_KEY=$(openssl rand -hex 32)

# Redis Configuration
REDIS_URL=redis://redis:6379/0

# Feature Flags
ENABLE_COMMENTS=true
ENABLE_HISTORY_TRACKING=true
ENABLE_EXPORT_FEATURES=true
ENABLE_S3_BACKUP=false

# S3 Configuration (Optional)
S3_BUCKET_NAME=
S3_PREFIX=security-hub-backups/
EOF

echo "✅ Basic .env file created successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Review the .env file: cat .env"
echo "2. Update AWS credentials if needed"
echo "3. Run deployment: ./scripts/deploy-production.sh"
echo ""
echo "⚠️  Note: For production, ensure AWS credentials are properly configured" 