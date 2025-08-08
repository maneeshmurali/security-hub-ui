#!/bin/bash

echo "🔧 Setting up Environment Configuration"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if .env already exists
if [ -f ".env" ]; then
    echo -e "${YELLOW}⚠️  .env file already exists${NC}"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Keeping existing .env file${NC}"
        exit 0
    fi
fi

# Check if config.env.example exists
if [ ! -f "config.env.example" ]; then
    echo -e "${RED}❌ config.env.example not found${NC}"
    exit 1
fi

# Copy the template to .env
echo -e "${BLUE}📋 Creating .env file from template...${NC}"
cp config.env.example .env

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ .env file created successfully${NC}"
else
    echo -e "${RED}❌ Failed to create .env file${NC}"
    exit 1
fi

# Generate a random secret key
echo -e "${BLUE}🔑 Generating random secret key...${NC}"
SECRET_KEY=$(openssl rand -hex 32)
sed -i.bak "s/your-super-secret-key-change-this-in-production/$SECRET_KEY/" .env
rm -f .env.bak

echo -e "${GREEN}✅ Secret key generated and updated${NC}"

# Ask for AWS region
echo -e "${BLUE}🌍 AWS Configuration${NC}"
read -p "Enter AWS Region (default: us-east-1): " aws_region
aws_region=${aws_region:-us-east-1}
sed -i.bak "s/AWS_REGION=us-east-1/AWS_REGION=$aws_region/" .env
rm -f .env.bak

echo -e "${GREEN}✅ AWS region set to: $aws_region${NC}"

# Ask for polling interval
echo -e "${BLUE}⏰ Polling Configuration${NC}"
read -p "Enter polling interval in minutes (default: 1440 = 24 hours): " polling_interval
polling_interval=${polling_interval:-1440}
sed -i.bak "s/POLLING_INTERVAL_MINUTES=1440/POLLING_INTERVAL_MINUTES=$polling_interval/" .env
rm -f .env.bak

echo -e "${GREEN}✅ Polling interval set to: $polling_interval minutes${NC}"

# Ask for S3 configuration
echo -e "${BLUE}📦 S3 Configuration (Optional)${NC}"
read -p "Do you want to enable S3 backup/export? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "Enter S3 bucket name: " s3_bucket
    if [ -n "$s3_bucket" ]; then
        sed -i.bak "s/S3_BUCKET_NAME=/S3_BUCKET_NAME=$s3_bucket/" .env
        sed -i.bak "s/ENABLE_S3_BACKUP=false/ENABLE_S3_BACKUP=true/" .env
        rm -f .env.bak
        echo -e "${GREEN}✅ S3 backup enabled with bucket: $s3_bucket${NC}"
    fi
fi

# Display summary
echo -e "\n${GREEN}🎉 Environment Configuration Complete!${NC}"
echo "================================================"
echo -e "${BLUE}📋 Configuration Summary:${NC}"
echo "  • AWS Region: $aws_region"
echo "  • Polling Interval: $polling_interval minutes"
echo "  • Secret Key: Generated"
echo "  • S3 Backup: $([ -n "$s3_bucket" ] && echo "Enabled ($s3_bucket)" || echo "Disabled")"

echo -e "\n${BLUE}📋 Next Steps:${NC}"
echo "  1. Review the .env file: cat .env"
echo "  2. Update AWS credentials if needed"
echo "  3. Run deployment: ./scripts/deploy-production.sh"
echo "  4. Or run tests: ./scripts/production-test.sh"

echo -e "\n${YELLOW}⚠️  Important Notes:${NC}"
echo "  • For production, ensure AWS credentials are properly configured"
echo "  • Consider using IAM roles instead of access keys"
echo "  • Review and adjust other settings in .env as needed"

echo -e "\n${GREEN}✅ Ready for deployment!${NC}" 