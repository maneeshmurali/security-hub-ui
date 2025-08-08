#!/bin/bash

echo "🏭 Production Readiness Test"
echo "==========================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_pattern="$3"
    
    echo -e "\n${BLUE}🧪 Testing: $test_name${NC}"
    echo "Command: $test_command"
    
    # Run the test command
    local result
    result=$(eval "$test_command" 2>&1)
    local exit_code=$?
    
    if [ $exit_code -eq 0 ] && [[ "$result" =~ $expected_pattern ]]; then
        echo -e "${GREEN}✅ PASSED${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ FAILED${NC}"
        echo "Result: $result"
        echo "Exit code: $exit_code"
        ((TESTS_FAILED++))
    fi
}

# Test 1: API Version Check
run_test "API Version" \
    "curl -s http://localhost:8000/api/test/version | jq -r '.build'" \
    "2025-08-08-v8"

# Test 2: Health Check
run_test "Health Check" \
    "curl -s http://localhost:8000/api/test/health | jq -r '.status'" \
    "healthy"

# Test 3: Database Connection
run_test "Database Connection" \
    "curl -s http://localhost:8000/api/test/database-status | jq -r '.database_status'" \
    "connected"

# Test 4: Manual Fetch (should work)
run_test "Manual Fetch" \
    "curl -s -X POST http://localhost:8000/api/findings/fetch | jq -r '.message'" \
    "Manual fetch completed successfully"

# Wait a bit for fetch to complete
echo -e "\n${YELLOW}⏳ Waiting 10 seconds for fetch to complete...${NC}"
sleep 10

# Test 5: Findings Count (should be > 0)
run_test "Findings Count" \
    "curl -s http://localhost:8000/api/findings?limit=1 | jq 'length'" \
    "[1-9][0-9]*"

# Test 6: Controls Count (should be > 0)
run_test "Controls Count" \
    "curl -s http://localhost:8000/api/controls | jq -r '.total_controls'" \
    "[1-9][0-9]*"

# Test 7: Stats Endpoint
run_test "Stats Endpoint" \
    "curl -s http://localhost:8000/api/stats | jq -r '.total_findings'" \
    "[1-9][0-9]*"

# Test 8: Scheduler Status
run_test "Scheduler Status" \
    "curl -s http://localhost:8000/api/scheduler/status | jq -r '.running'" \
    "true"

# Test 9: Finding Details
run_test "Finding Details" \
    "curl -s http://localhost:8000/api/findings?limit=1 | jq -r '.[0].id' | head -1 | xargs -I {} curl -s http://localhost:8000/api/findings/{} | jq -r '.id'" \
    "arn:aws:"

# Test 10: Control Details
run_test "Control Details" \
    "curl -s http://localhost:8000/api/controls | jq -r '.controls[0].control_id' | head -1 | xargs -I {} curl -s http://localhost:8000/api/controls/{} | jq -r '.control.control_id'" \
    "[A-Za-z0-9._-]+"

# Test 11: Comments System
run_test "Comments System" \
    "curl -s http://localhost:8000/api/test/comments-simple | jq -r '.status'" \
    "comments-endpoint-working"

# Test 12: Export Functionality
run_test "Export CSV" \
    "curl -s http://localhost:8000/api/findings/export/csv | head -1" \
    "id,title,severity"

# Test 13: Filter Functionality
run_test "Severity Filter" \
    "curl -s 'http://localhost:8000/api/findings?severity=HIGH&limit=5' | jq 'length'" \
    "[0-9]+"

# Test 14: Compliance Filter
run_test "Compliance Filter" \
    "curl -s 'http://localhost:8000/api/findings?compliance_status=FAILED&limit=5' | jq 'length'" \
    "[0-9]+"

# Test 15: Workflow Filter
run_test "Workflow Filter" \
    "curl -s 'http://localhost:8000/api/findings?workflow_status=NEW&limit=5' | jq 'length'" \
    "[0-9]+"

# Test 16: Container Health
run_test "Container Health" \
    "docker-compose ps | grep -E 'Up|healthy' | wc -l" \
    "[1-9][0-9]*"

# Test 17: Database Tables
run_test "Database Tables" \
    "docker-compose exec -T postgres psql -U postgres -d security_hub -c '\dt' | grep -E 'findings|comments|history' | wc -l" \
    "[1-9][0-9]*"

# Test 18: Log Check (no errors)
run_test "Error Log Check" \
    "docker-compose logs --tail=50 security-hub-app | grep -i error | wc -l" \
    "0"

# Test 19: Memory Usage
run_test "Memory Usage" \
    "docker stats --no-stream --format 'table {{.Container}}\t{{.MemUsage}}' | grep security-hub-app | awk '{print \$2}' | sed 's/MiB//' | awk '\$1 < 1000'" \
    "[0-9]+"

# Test 20: Response Time
run_test "Response Time" \
    "curl -s -w '%{time_total}' -o /dev/null http://localhost:8000/api/test/health | awk '\$1 < 2'" \
    "[0-9.]+"

echo -e "\n${BLUE}📊 Test Results Summary${NC}"
echo "=========================="
echo -e "${GREEN}✅ Tests Passed: $TESTS_PASSED${NC}"
echo -e "${RED}❌ Tests Failed: $TESTS_FAILED${NC}"
echo -e "${BLUE}📈 Total Tests: $((TESTS_PASSED + TESTS_FAILED))${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}🎉 ALL TESTS PASSED! Production ready! 🎉${NC}"
    exit 0
else
    echo -e "\n${RED}⚠️  SOME TESTS FAILED! Please review the issues above. ⚠️${NC}"
    exit 1
fi 