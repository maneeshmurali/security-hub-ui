#!/bin/bash

echo "🔍 Deployment Verification"
echo "========================="

# Check container status
echo "📊 Container Status:"
docker-compose ps

echo ""

# Check version
echo "🔍 API Version Check:"
curl -s http://localhost:8000/api/test/version 2>/dev/null | jq . || echo "❌ Service not responding"

echo ""

# Check database status
echo "🗄️  Database Status:"
curl -s http://localhost:8000/api/test/database-status 2>/dev/null | jq '.total_findings' || echo "❌ Database status not available"

echo ""

# Check if controls endpoint works
echo "🎛️  Controls Endpoint:"
curl -s http://localhost:8000/api/controls 2>/dev/null | jq '.total_controls' || echo "❌ Controls endpoint not available"

echo ""

# Check container logs for errors
echo "📋 Recent Logs (last 10 lines):"
docker-compose logs --tail=10 security-hub-app

echo ""
echo "✅ Verification complete!" 