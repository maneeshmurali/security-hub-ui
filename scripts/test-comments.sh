#!/bin/bash

echo "💬 Testing Enhanced Comments System"
echo "=================================="

# Test the API version first
echo "🔍 API Version:"
curl -s http://localhost:8000/api/test/version | jq .

echo ""

# Test finding comments
echo "🔍 Testing Finding Comments:"
echo "1. Get a sample finding ID:"
FINDING_ID=$(curl -s "http://localhost:8000/api/findings?limit=1" | jq -r '.[0].id // empty')
if [ -n "$FINDING_ID" ]; then
    echo "   Found finding: $FINDING_ID"
    
    echo "2. Check existing comments:"
    curl -s "http://localhost:8000/api/test/comments-by-query?finding_id=$FINDING_ID" | jq '.comments | length'
    
    echo "3. Add a test comment:"
    curl -s -X POST "http://localhost:8000/api/test/comments-add?finding_id=$FINDING_ID&comment=Test comment from script&author=TestUser&is_internal=false" | jq .
    
    echo "4. Check comments again:"
    curl -s "http://localhost:8000/api/test/comments-by-query?finding_id=$FINDING_ID" | jq '.comments | length'
else
    echo "   No findings available"
fi

echo ""

# Test control comments
echo "🎛️  Testing Control Comments:"
echo "1. Get a sample control:"
CONTROL_RESPONSE=$(curl -s "http://localhost:8000/api/controls?limit=1")
CONTROL_ID=$(echo "$CONTROL_RESPONSE" | jq -r '.controls[0].control_id // empty')
if [ -n "$CONTROL_ID" ]; then
    echo "   Found control: $CONTROL_ID"
    
    echo "2. Get control details:"
    curl -s "http://localhost:8000/api/controls/$CONTROL_ID" | jq '.total_affected_resources'
    
    echo "3. Check if control has findings with comments:"
    curl -s "http://localhost:8000/api/controls/$CONTROL_ID" | jq '.affected_resources | length'
else
    echo "   No controls available"
fi

echo ""

# Test comments endpoint
echo "📋 Testing Comments Endpoints:"
echo "1. Simple comments test:"
curl -s "http://localhost:8000/api/test/comments-simple" | jq .

echo ""

echo "✅ Comments system test complete!"
echo "📋 Check the UI to test comment functionality manually"
echo "🔍 Monitor logs: docker-compose logs -f security-hub-app" 