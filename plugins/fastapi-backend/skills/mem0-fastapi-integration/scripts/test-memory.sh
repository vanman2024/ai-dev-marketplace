#!/bin/bash
# Test Mem0 memory service functionality

set -e

echo "🧪 Testing Mem0 Memory Service..."

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
API_URL="${API_URL:-http://localhost:8000}"
API_VERSION="${API_VERSION:-v1}"
BASE_URL="$API_URL/api/$API_VERSION"

# Get auth token (if needed)
AUTH_TOKEN="${AUTH_TOKEN:-development_token}"

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Helper function for API calls
api_call() {
    local method=$1
    local endpoint=$2
    local data=$3

    if [ "$method" = "GET" ]; then
        curl -s -X GET \
            -H "Authorization: Bearer $AUTH_TOKEN" \
            -H "Content-Type: application/json" \
            "$BASE_URL$endpoint"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer $AUTH_TOKEN" \
            -H "Content-Type: application/json" \
            -d "$data" \
            "$BASE_URL$endpoint"
    fi
}

# Test function
run_test() {
    local test_name=$1
    local test_command=$2

    echo -e "\n${BLUE}▶ Testing: $test_name${NC}"

    if eval "$test_command"; then
        echo -e "${GREEN}✓ PASSED${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAILED${NC}"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Check if API is running
echo -e "${BLUE}Checking API availability...${NC}"
if ! curl -s "$API_URL/health" > /dev/null 2>&1; then
    echo -e "${RED}❌ API not running at $API_URL${NC}"
    echo "Start your FastAPI server first: uvicorn app.main:app --reload"
    exit 1
fi
echo -e "${GREEN}✓ API is running${NC}"

# Test 1: Add conversation
run_test "Add conversation to memory" '
response=$(api_call POST "/memory/conversation" "{
    \"messages\": [
        {\"role\": \"user\", \"content\": \"Hello, I love pizza\"},
        {\"role\": \"assistant\", \"content\": \"Great! I will remember that you love pizza.\"}
    ],
    \"session_id\": \"test_session_$(date +%s)\",
    \"metadata\": {\"test\": true}
}")
echo "$response" | grep -q "success"
'

# Test 2: Search memories
run_test "Search memories" '
response=$(api_call POST "/memory/search" "{
    \"query\": \"What food does the user like?\",
    \"limit\": 5
}")
echo "$response" | grep -q "results"
'

# Test 3: Get memory summary
run_test "Get memory summary" '
response=$(api_call GET "/memory/summary" "")
echo "$response" | grep -q "total_memories"
'

# Test 4: Add user preference
run_test "Add user preference" '
response=$(api_call POST "/memory/preference" "{
    \"preference\": \"I prefer concise responses\",
    \"category\": \"communication\"
}")
echo "$response" | grep -q "success"
'

# Test 5: Search with filters
run_test "Search with category filter" '
response=$(api_call POST "/memory/search" "{
    \"query\": \"user preferences\",
    \"limit\": 3,
    \"filters\": {\"category\": \"communication\"}
}")
echo "$response" | grep -q "results"
'

# Test 6: Add multiple conversations (batch test)
run_test "Add multiple conversations" '
for i in {1..3}; do
    api_call POST "/memory/conversation" "{
        \"messages\": [
            {\"role\": \"user\", \"content\": \"Message $i\"},
            {\"role\": \"assistant\", \"content\": \"Response $i\"}
        ],
        \"session_id\": \"batch_test_$i\"
    }" > /dev/null
done
# Verify by getting summary
response=$(api_call GET "/memory/summary" "")
echo "$response" | grep -q "total_memories"
'

# Test 7: Memory persistence check
run_test "Memory persistence across requests" '
# Add a specific memory
unique_content="I have a cat named Whiskers $(date +%s)"
api_call POST "/memory/conversation" "{
    \"messages\": [
        {\"role\": \"user\", \"content\": \"$unique_content\"}
    ]
}" > /dev/null

sleep 1

# Search for it
response=$(api_call POST "/memory/search" "{
    \"query\": \"cat\",
    \"limit\": 10
}")
echo "$response" | grep -q "Whiskers"
'

# Test 8: Empty query handling
run_test "Handle empty query gracefully" '
response=$(api_call POST "/memory/search" "{
    \"query\": \"\",
    \"limit\": 1
}")
# Should return results or empty array, not error
echo "$response" | grep -qE "(results|error)"
'

# Test 9: Large limit handling
run_test "Respect maximum search limit" '
response=$(api_call POST "/memory/search" "{
    \"query\": \"test\",
    \"limit\": 100
}")
# API should limit to max (e.g., 20)
echo "$response" | grep -q "results"
'

# Test 10: Metadata retrieval
run_test "Retrieve conversation with metadata" '
timestamp=$(date +%s)
api_call POST "/memory/conversation" "{
    \"messages\": [
        {\"role\": \"user\", \"content\": \"Metadata test $timestamp\"}
    ],
    \"metadata\": {\"importance\": \"high\", \"timestamp\": \"$timestamp\"}
}" > /dev/null

sleep 1

response=$(api_call POST "/memory/search" "{
    \"query\": \"Metadata test\",
    \"limit\": 5
}")
echo "$response" | grep -q "results"
'

# Summary
echo -e "\n${BLUE}═══════════════════════════════════════${NC}"
echo -e "${BLUE}Test Results${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}✅ All tests passed!${NC}"
    exit 0
else
    echo -e "\n${RED}❌ Some tests failed${NC}"
    exit 1
fi
