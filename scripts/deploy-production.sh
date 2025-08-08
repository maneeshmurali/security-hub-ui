#!/bin/bash

echo "🚀 Production Deployment Script"
echo "==============================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to log with timestamp
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

# Function to check step result
check_result() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ SUCCESS${NC}"
    else
        echo -e "${RED}❌ FAILED${NC}"
        exit 1
    fi
}

# Check prerequisites
log "Checking prerequisites..."
if ! command_exists docker; then
    echo -e "${RED}❌ Docker is not installed${NC}"
    exit 1
fi

if ! command_exists docker-compose; then
    echo -e "${RED}❌ Docker Compose is not installed${NC}"
    exit 1
fi

if ! command_exists curl; then
    echo -e "${RED}❌ curl is not installed${NC}"
    exit 1
fi

if ! command_exists jq; then
    echo -e "${RED}❌ jq is not installed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All prerequisites met${NC}"

# Check if .env file exists
log "Checking configuration..."
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠️  .env file not found${NC}"
    echo -e "${BLUE}Creating basic .env file...${NC}"
    
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
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Basic .env file created${NC}"
        echo -e "${YELLOW}⚠️  Please review and update AWS credentials in .env file${NC}"
    else
        echo -e "${RED}❌ Failed to create .env file${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✅ Configuration found${NC}"

# Stop existing containers
log "Stopping existing containers..."
docker-compose down
check_result

# Clean up old images and containers
log "Cleaning up old images and containers..."
docker system prune -f
docker builder prune -f
check_result

# Remove old app image specifically
log "Removing old app image..."
docker rmi $(docker images -q security-hub-ui-security-hub-app) 2>/dev/null || true
check_result

# Build new images
log "Building new images..."
docker-compose build --no-cache --force-rm
check_result

# Start services
log "Starting services..."
docker-compose up -d
check_result

# Wait for services to be ready
log "Waiting for services to be ready..."
sleep 15

# Check container status
log "Checking container status..."
docker-compose ps
check_result

# Wait for database to be ready
log "Waiting for database to be ready..."
for i in {1..30}; do
    if docker-compose exec -T postgres pg_isready -U postgres >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Database is ready${NC}"
        break
    fi
    echo -n "."
    sleep 2
done

# Check if database is ready
if ! docker-compose exec -T postgres pg_isready -U postgres >/dev/null 2>&1; then
    echo -e "${RED}❌ Database failed to start${NC}"
    exit 1
fi

# Wait for application to be ready
log "Waiting for application to be ready..."
for i in {1..30}; do
    if curl -s http://localhost:8000/api/test/health >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Application is ready${NC}"
        break
    fi
    echo -n "."
    sleep 2
done

# Check if application is ready
if ! curl -s http://localhost:8000/api/test/health >/dev/null 2>&1; then
    echo -e "${RED}❌ Application failed to start${NC}"
    exit 1
fi

# Verify version
log "Verifying application version..."
VERSION=$(curl -s http://localhost:8000/api/test/version | jq -r '.build')
if [ "$VERSION" = "2025-08-08-v8" ]; then
    echo -e "${GREEN}✅ Correct version deployed: $VERSION${NC}"
else
    echo -e "${RED}❌ Wrong version: $VERSION (expected: 2025-08-08-v8)${NC}"
    exit 1
fi

# Trigger initial data fetch
log "Triggering initial data fetch..."
MANUAL_FETCH_RESULT=$(curl -s -X POST http://localhost:8000/api/findings/fetch | jq -r '.message')
if [[ "$MANUAL_FETCH_RESULT" == *"completed successfully"* ]]; then
    echo -e "${GREEN}✅ Initial fetch completed${NC}"
else
    echo -e "${YELLOW}⚠️  Manual fetch result: $MANUAL_FETCH_RESULT${NC}"
fi

# Wait for fetch to complete
log "Waiting for fetch to complete..."
sleep 20

# Verify data is loaded
log "Verifying data is loaded..."
FINDINGS_COUNT=$(curl -s http://localhost:8000/api/findings?limit=1 | jq 'length')
if [ "$FINDINGS_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✅ Findings loaded: $FINDINGS_COUNT${NC}"
else
    echo -e "${YELLOW}⚠️  No findings found yet${NC}"
fi

CONTROLS_COUNT=$(curl -s http://localhost:8000/api/controls | jq -r '.total_controls')
if [ "$CONTROLS_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✅ Controls loaded: $CONTROLS_COUNT${NC}"
else
    echo -e "${YELLOW}⚠️  No controls found yet${NC}"
fi

# Check scheduler status
log "Checking scheduler status..."
SCHEDULER_RUNNING=$(curl -s http://localhost:8000/api/scheduler/status | jq -r '.running')
if [ "$SCHEDULER_RUNNING" = "true" ]; then
    echo -e "${GREEN}✅ Scheduler is running${NC}"
else
    echo -e "${RED}❌ Scheduler is not running${NC}"
    exit 1
fi

# Final health check
log "Performing final health check..."
HEALTH_STATUS=$(curl -s http://localhost:8000/api/test/health | jq -r '.status')
if [ "$HEALTH_STATUS" = "healthy" ]; then
    echo -e "${GREEN}✅ Application is healthy${NC}"
else
    echo -e "${RED}❌ Application is not healthy: $HEALTH_STATUS${NC}"
    exit 1
fi

# Display final status
echo -e "\n${GREEN}🎉 DEPLOYMENT COMPLETED SUCCESSFULLY! 🎉${NC}"
echo "================================================"
echo -e "${BLUE}📊 Application Status:${NC}"
echo "  • Version: $VERSION"
echo "  • Health: $HEALTH_STATUS"
echo "  • Scheduler: Running"
echo "  • Findings: $FINDINGS_COUNT"
echo "  • Controls: $CONTROLS_COUNT"

echo -e "\n${BLUE}🔗 Access URLs:${NC}"
echo "  • Dashboard: http://localhost:8000"
echo "  • API Health: http://localhost:8000/api/test/health"
echo "  • API Version: http://localhost:8000/api/test/version"

echo -e "\n${BLUE}📋 Useful Commands:${NC}"
echo "  • View logs: docker-compose logs -f security-hub-app"
echo "  • Check status: docker-compose ps"
echo "  • Manual fetch: curl -X POST http://localhost:8000/api/findings/fetch"
echo "  • Run tests: ./scripts/production-test.sh"

echo -e "\n${GREEN}✅ Production deployment is ready!${NC}" 