#!/bin/bash

echo "🔄 Force rebuilding Security Hub application..."

# Stop all containers
echo "📦 Stopping all containers..."
docker-compose down

# Remove all images to force rebuild
echo "🗑️  Removing old images..."
docker rmi security-hub-ui-security-hub-app 2>/dev/null || true
docker rmi postgres:15 2>/dev/null || true
docker rmi redis:7-alpine 2>/dev/null || true

# Clean up any dangling images
echo "🧹 Cleaning up dangling images..."
docker image prune -f

# Rebuild and start
echo "🔨 Rebuilding and starting containers..."
docker-compose up -d --build --force-recreate

# Wait for containers to be ready
echo "⏳ Waiting for containers to be ready..."
sleep 10

# Check status
echo "📊 Container status:"
docker-compose ps

echo "✅ Rebuild complete! Check the logs with: docker-compose logs -f security-hub-app" 