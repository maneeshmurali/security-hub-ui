# AWS Security Hub Findings Dashboard - Makefile
# Provides easy commands for managing the Docker setup

.PHONY: help setup start stop restart status logs health backup restore cleanup dev monitoring nginx traefik build test

# Default target
help: ## Show this help message
	@echo "AWS Security Hub Findings Dashboard - Docker Management"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Initial setup
setup: ## Initial setup (create directories, .env file)
	@echo "🚀 Setting up Security Hub Dashboard..."
	@chmod +x scripts/start.sh
	@./scripts/start.sh setup

# Start services
start: ## Start services (default profile)
	@echo "🚀 Starting Security Hub Dashboard..."
	@./scripts/start.sh start







# Stop and restart
stop: ## Stop all services
	@echo "🛑 Stopping services..."
	@./scripts/start.sh stop

restart: ## Restart all services
	@echo "🔄 Restarting services..."
	@./scripts/start.sh restart

# Status and monitoring
status: ## Show service status and URLs
	@./scripts/start.sh status

logs: ## Show application logs
	@./scripts/start.sh logs

health: ## Check service health
	@./scripts/start.sh health

# Backup and restore


# Maintenance
cleanup: ## Clean up Docker resources
	@echo "🧹 Cleaning up Docker resources..."
	@./scripts/start.sh cleanup

build: ## Build Docker images
	@echo "🔨 Building Docker images..."
	@docker-compose build

# Development
test: ## Run tests
	@echo "🧪 Running tests..."
	@docker-compose exec security-hub-app python test_app.py

shell: ## Open shell in application container
	@echo "🐚 Opening shell in application container..."
	@docker-compose exec security-hub-app /bin/bash

# Database operations
db-shell: ## Open database shell
	@echo "🗄️ Opening database shell..."
	@docker-compose exec security-hub-app sqlite3 /app/data/security_hub_findings.db

db-backup: ## Create database backup
	@echo "💾 Creating database backup..."
	@docker-compose exec security-hub-app sqlite3 /app/data/security_hub_findings.db ".backup /app/backups/db_backup_$(shell date +%Y%m%d_%H%M%S).db"



# SSL certificate management


# Quick commands
quick-start: ## Quick start (setup + start)
	@make setup
	@make start





# Production deployment
prod-deploy: ## Production deployment
	@echo "🚀 Deploying to production..."
	@make setup
	@make build
	@make start

prod-update: ## Update production deployment
	@echo "🔄 Updating production deployment..."
	@make stop
	@make build
	@make start

# Utility commands
ps: ## Show running containers
	@docker-compose ps

images: ## Show Docker images
	@docker images | grep security-hub

volumes: ## Show Docker volumes
	@docker volume ls | grep security-hub

networks: ## Show Docker networks
	@docker network ls | grep security-hub

# Environment management
env-edit: ## Edit environment file
	@if command -v code >/dev/null 2>&1; then \
		code .env; \
	elif command -v nano >/dev/null 2>&1; then \
		nano .env; \
	elif command -v vim >/dev/null 2>&1; then \
		vim .env; \
	else \
		echo "Please edit .env file manually"; \
	fi

env-show: ## Show current environment variables
	@echo "Current environment variables:"
	@cat .env | grep -v '^#' | grep -v '^$$' || echo "No .env file found"

# Log management
logs-app: ## Show application logs
	@docker-compose logs -f security-hub-app

logs-redis: ## Show Redis logs
	@docker-compose logs -f redis



logs-all: ## Show all logs
	@docker-compose logs -f

# Performance monitoring
stats: ## Show container statistics
	@docker stats --no-stream

top: ## Show container resource usage
	@docker stats

# Security
security-scan: ## Run security scan on images
	@echo "🔍 Running security scan..."
	@docker-compose exec security-hub-app python -m bandit -r /app -f json -o /app/security_scan.json || echo "Security scan completed"

# Documentation
docs: ## Generate documentation
	@echo "📚 Generating documentation..."
	@docker-compose exec security-hub-app python -c "import pydoc; pydoc.writedocs('/app/docs')" || echo "Documentation generation completed"



# Health checks
health-app: ## Check application health
	@curl -f http://localhost:8000/api/stats || echo "Application health check failed"

health-redis: ## Check Redis health
	@docker-compose exec redis redis-cli ping || echo "Redis health check failed"

health-all: ## Check all services health
	@make health-app
	@make health-redis 