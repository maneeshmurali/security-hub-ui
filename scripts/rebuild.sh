#!/bin/bash

echo "🔄 Force rebuilding Security Hub application..."

# Stop all containers
echo "📦 Stopping all containers..."
docker-compose down

# Remove all containers and images to force complete rebuild
echo "🗑️  Removing all containers and images..."
docker-compose rm -f
docker rmi $(docker images -q security-hub-ui-security-hub-app) 2>/dev/null || true
docker rmi $(docker images -q postgres) 2>/dev/null || true
docker rmi $(docker images -q redis) 2>/dev/null || true

# Clean up everything
echo "🧹 Cleaning up all unused containers, networks, and images..."
docker system prune -f --volumes

# Remove any cached layers
echo "🗑️  Removing build cache..."
docker builder prune -f

# Rebuild everything from scratch
echo "🔨 Rebuilding all containers from scratch..."
docker-compose build --no-cache --force-rm

# Start all services
echo "🚀 Starting all services..."
docker-compose up -d

# Wait for containers to be ready
echo "⏳ Waiting for containers to be ready..."
sleep 15

# Check status
echo "📊 Container status:"
docker-compose ps

# Check if containers are healthy
echo "🏥 Health check:"
docker-compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

echo "✅ Complete rebuild finished!"
echo "📋 Check the logs with: docker-compose logs -f security-hub-app"
echo "🔍 Check version with: curl -s http://localhost:8000/api/test/version | jq ." 