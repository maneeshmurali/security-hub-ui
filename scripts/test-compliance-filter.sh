#!/bin/bash

echo "🧪 Testing Compliance Filter (FAILED status only)"
echo "================================================"

# Test the API version first
echo "🔍 API Version:"
curl -s http://localhost:8000/api/test/version | jq .

echo ""

# Test database status to see current findings
echo "🗄️  Current Database Status:"
curl -s http://localhost:8000/api/test/database-status | jq .

echo ""

# Test compliance filter specifically
echo "✅ Testing Compliance Filter - FAILED only:"
curl -s "http://localhost:8000/api/findings?compliance_status=FAILED&limit=5" | jq '.[] | {id, title, compliance_status, severity}' || echo "No findings with FAILED compliance status"

echo ""

# Test severity + compliance filter
echo "🔴 Testing HIGH + FAILED compliance:"
curl -s "http://localhost:8000/api/findings?severity=HIGH&compliance_status=FAILED&limit=3" | jq '.[] | {id, title, compliance_status, severity}' || echo "No HIGH severity findings with FAILED compliance"

echo ""

# Test controls endpoint with compliance filter
echo "🎛️  Testing Controls with FAILED compliance:"
curl -s "http://localhost:8000/api/controls?compliance_status=FAILED" | jq '.total_controls' || echo "No controls with FAILED compliance"

echo ""

# Test manual fetch to get new data
echo "🔄 Triggering manual fetch to get latest data..."
curl -X POST "http://localhost:8000/api/findings/fetch" -H "Content-Type: application/json" &
FETCH_PID=$!

# Wait a bit for fetch to start
sleep 5

echo "📊 Checking fetch status..."
curl -s "http://localhost:8000/api/scheduler/status" | jq .

echo ""

echo "✅ Compliance filter test complete!"
echo "📋 Check the logs: docker-compose logs -f security-hub-app" 