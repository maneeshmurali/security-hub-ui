# 🐳 Docker Deployment Guide

This guide provides complete automation for deploying the AWS Security Hub Findings Dashboard using Docker. You only need to configure the `.env` file!

## 🚀 Quick Start

### 1. Clone and Setup
```bash
git clone <repository-url>
cd Security-Hub
```

### 2. One-Command Deployment
```bash
# Copy environment template and start
cp env.docker .env
make quick-start
```

That's it! Your application will be running at `http://localhost:8000`

## 📋 Prerequisites

- **Docker** (version 20.10+)
- **Docker Compose** (version 2.0+)
- **AWS IAM Role** with Security Hub permissions (for EC2 deployment)

## ⚙️ Configuration

### Environment File Setup

The only file you need to configure is `.env`. Copy the template:

```bash
cp env.docker .env
```

### Essential Configuration

Edit `.env` and configure these essential settings:

```env
# AWS Configuration
AWS_REGION=us-east-1

# Application Port
APP_PORT=8000

# Polling Interval (minutes)
POLLING_INTERVAL_MINUTES=30

# S3 Backup (optional)
S3_BUCKET_NAME=your-backup-bucket
```

### Advanced Configuration

The `.env` file includes many optional settings:

```env
# Monitoring
PROMETHEUS_PORT=9090
GRAFANA_PORT=3000
GRAFANA_PASSWORD=admin

# Reverse Proxy
NGINX_PORT=80
TRAEFIK_PORT=8080

# Security
ENABLE_HTTPS=false
SSL_CERT_PATH=./nginx/ssl/cert.pem
SSL_KEY_PATH=./nginx/ssl/key.pem

# Performance
REDIS_MAX_MEMORY=256mb
WORKER_PROCESSES=4

# Backup
BACKUP_RETENTION_DAYS=30
BACKUP_SCHEDULE=0 2 * * *
```

## 🎯 Deployment Profiles

### 1. Basic Production
```bash
make start
```
- Main application
- Redis cache
- SQLite database

### 2. Development Environment
```bash
make dev
```
- Hot reloading
- Debug mode
- PostgreSQL database
- Development tools

### 3. Production with Monitoring
```bash
make monitoring
```
- Prometheus metrics
- Grafana dashboards
- Enhanced logging

### 4. Production with Nginx
```bash
make nginx
```
- Nginx reverse proxy
- SSL termination
- Rate limiting
- Security headers

### 5. Production with Traefik
```bash
make traefik
```
- Traefik reverse proxy
- Automatic SSL
- Service discovery

## 🛠️ Management Commands

### Basic Operations
```bash
# Start services
make start

# Stop services
make stop

# Restart services
make restart

# Show status
make status

# View logs
make logs
```

### Development Commands
```bash
# Development environment
make dev

# Run tests
make test

# Open shell
make shell

# Database shell
make db-shell
```

### Monitoring Commands
```bash
# Check health
make health

# View Prometheus
make prometheus

# View Grafana
make grafana

# Container stats
make stats
```

### Backup Commands
```bash
# Create backup
make backup

# List backups
make backup-list

# Restore backup
make restore FILE=backup_20231201_120000.tar.gz

# Clean old backups
make backup-cleanup
```

### Maintenance Commands
```bash
# Build images
make build

# Clean up resources
make cleanup

# Generate SSL certificates
make ssl-generate

# Security scan
make security-scan
```

## 🌐 Service URLs

After deployment, access these services:

| Service | URL | Description |
|---------|-----|-------------|
| Main App | http://localhost:8000 | Security Hub Dashboard |
| API Docs | http://localhost:8000/docs | FastAPI Documentation |
| Prometheus | http://localhost:9090 | Metrics & Monitoring |
| Grafana | http://localhost:3000 | Dashboards (admin/admin) |
| Traefik | http://localhost:8080 | Reverse Proxy Dashboard |

## 📊 Monitoring & Observability

### Prometheus Metrics
The application exposes metrics at `/metrics`:
- Request counts and durations
- Database connection stats
- Security Hub API calls
- Scheduler status

### Grafana Dashboards
Pre-configured dashboards include:
- Application performance
- Security findings trends
- System resource usage
- Error rates and alerts

### Health Checks
```bash
# Check all services
make health-all

# Check application only
make health-app

# Check Redis
make health-redis
```

## 🔒 Security Features

### SSL/TLS Configuration
```bash
# Generate self-signed certificates
make ssl-generate

# Enable HTTPS in .env
ENABLE_HTTPS=true
```

### Security Headers
- X-Frame-Options
- X-Content-Type-Options
- X-XSS-Protection
- Content-Security-Policy
- Strict-Transport-Security

### Rate Limiting
- API endpoints: 10 requests/second
- Burst allowance: 20 requests
- Configurable limits in `.env`

## 💾 Backup & Recovery

### Automated Backups
```bash
# Create backup
make backup

# List available backups
make backup-list

# Restore from backup
make restore FILE=backup_20231201_120000.tar.gz
```

### S3 Integration
Configure S3 backup in `.env`:
```env
S3_BUCKET_NAME=your-backup-bucket
S3_PREFIX=security-hub-findings/
AWS_REGION=us-east-1
```

### Backup Retention
- Local backups: 30 days (configurable)
- S3 backups: 30 days (configurable)
- Automatic cleanup of old backups

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
   ```

3. **Docker Not Running**
   ```bash
   # Start Docker
   sudo systemctl start docker
   ```

4. **Memory Issues**
   ```bash
   # Increase Docker memory limit
   # Edit Docker Desktop settings
   ```

### Log Analysis
```bash
# Application logs
make logs-app

# All logs
make logs-all

# Follow logs
docker-compose logs -f
```

### Debug Mode
```bash
# Enable debug in .env
DEBUG=true
LOG_LEVEL=DEBUG

# Restart with debug
make restart
```

## 🚀 Production Deployment

### 1. EC2 Deployment
```bash
# On EC2 instance
git clone <repository-url>
cd Security-Hub
cp env.docker .env
# Edit .env with your settings
make prod-deploy
```

### 2. ECS Deployment
```bash
# Build and push to ECR
docker build -t security-hub-app .
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account>.dkr.ecr.us-east-1.amazonaws.com
docker tag security-hub-app:latest <account>.dkr.ecr.us-east-1.amazonaws.com/security-hub-app:latest
docker push <account>.dkr.ecr.us-east-1.amazonaws.com/security-hub-app:latest
```

### 3. Kubernetes Deployment
```bash
# Apply Kubernetes manifests
kubectl apply -f k8s/
kubectl get pods
kubectl port-forward svc/security-hub-app 8000:8000
```

## 📈 Scaling

### Horizontal Scaling
```bash
# Scale application
docker-compose up -d --scale security-hub-app=3

# Scale with load balancer
docker-compose -f docker-compose.yml -f docker-compose.scale.yml up -d
```

### Resource Limits
Configure in `.env`:
```env
# Memory limits
REDIS_MAX_MEMORY=512mb
WORKER_PROCESSES=8

# Database connections
DB_POOL_SIZE=20
MAX_CONCURRENT_REQUESTS=200
```

## 🔄 Updates

### Application Updates
```bash
# Pull latest code
git pull

# Rebuild and restart
make prod-update
```

### Database Migrations
```bash
# Backup before migration
make backup

# Apply migrations
docker-compose exec security-hub-app python -m alembic upgrade head
```

## 📚 Additional Resources

### Scripts
- `scripts/start.sh` - Main management script
- `scripts/backup.sh` - Backup automation
- `Makefile` - Convenient commands

### Configuration Files
- `docker-compose.yml` - Main services
- `docker-compose.override.yml` - Development overrides
- `nginx/nginx.conf` - Reverse proxy configuration

### Monitoring
- `monitoring/prometheus.yml` - Metrics configuration
- `monitoring/grafana/` - Dashboard definitions

## 🆘 Support

### Getting Help
1. Check logs: `make logs`
2. Verify health: `make health`
3. Review configuration: `make env-show`
4. Check Docker status: `make ps`

### Common Commands Reference
```bash
# Quick reference
make help

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

This Docker setup provides complete automation - you only need to configure the `.env` file and run `make start` to get a fully functional Security Hub dashboard! 