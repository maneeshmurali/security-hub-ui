#!/bin/bash

echo "🚀 Force Rebuild - Security Hub Application"
echo "=========================================="

# Stop everything
echo "🛑 Stopping all containers..."
docker-compose down

# Remove the app container specifically
echo "🗑️  Removing app container and image..."
docker-compose rm -f security-hub-app
docker rmi $(docker images -q security-hub-ui-security-hub-app) 2>/dev/null || true

# Clean build cache
echo "🧹 Cleaning build cache..."
docker builder prune -f

# Rebuild with no cache
echo "🔨 Rebuilding app container with no cache..."
docker-compose build --no-cache security-hub-app

# Start all services
echo "🚀 Starting all services..."
docker-compose up -d

# Wait and check
echo "⏳ Waiting for startup..."
sleep 10

echo "📊 Container Status:"
docker-compose ps

echo "🔍 Version Check:"
curl -s http://localhost:8000/api/test/version 2>/dev/null | jq . || echo "Service not ready yet"

echo "✅ Force rebuild complete!"
echo "📋 Monitor logs: docker-compose logs -f security-hub-app" 