#!/bin/bash
# Test JWT validation and claim extraction
# Usage: ./test-jwt.sh [jwt-token]

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Clerk JWT Testing Utility${NC}"
echo "======================================"

# Check if JWT provided
if [ -z "$1" ]; then
  echo "Usage: ./test-jwt.sh <jwt-token>"
  echo ""
  echo "Get JWT from:"
  echo "  - Browser DevTools (Application > Storage > Local Storage)"
  echo "  - Clerk session.getToken() in JavaScript console"
  echo "  - curl request to Clerk API"
  exit 1
fi

JWT_TOKEN="$1"

# Check for jq
if ! command -v jq &> /dev/null; then
  echo -e "${RED}Error: jq not found${NC}"
  echo "Install: sudo apt install jq"
  exit 1
fi

echo -e "\n${GREEN}Step 1: Decoding JWT${NC}"

# Split JWT into parts
IFS='.' read -ra JWT_PARTS <<< "$JWT_TOKEN"

if [ ${#JWT_PARTS[@]} -ne 3 ]; then
  echo -e "${RED}Error: Invalid JWT format${NC}"
  echo "JWT should have 3 parts separated by dots"
  exit 1
fi

HEADER="${JWT_PARTS[0]}"
PAYLOAD="${JWT_PARTS[1]}"
SIGNATURE="${JWT_PARTS[2]}"

# Decode header
echo -e "\n${YELLOW}Header:${NC}"
echo "$HEADER" | base64 -d 2>/dev/null | jq '.' || echo "$HEADER" | base64 -d

# Decode payload
echo -e "\n${YELLOW}Payload:${NC}"
DECODED_PAYLOAD=$(echo "$PAYLOAD" | base64 -d 2>/dev/null | jq '.')
echo "$DECODED_PAYLOAD"

# Extract claims
echo -e "\n${GREEN}Step 2: Extracting Claims${NC}"

USER_ID=$(echo "$DECODED_PAYLOAD" | jq -r '.sub // empty')
EMAIL=$(echo "$DECODED_PAYLOAD" | jq -r '.email // empty')
ORG_ID=$(echo "$DECODED_PAYLOAD" | jq -r '.org_id // empty')
ROLE=$(echo "$DECODED_PAYLOAD" | jq -r '.role // "user"')
ISS=$(echo "$DECODED_PAYLOAD" | jq -r '.iss // empty')
EXP=$(echo "$DECODED_PAYLOAD" | jq -r '.exp // empty')

echo "User ID (sub):    $USER_ID"
echo "Email:            $EMAIL"
echo "Organization:     ${ORG_ID:-"(none)"}"
echo "Role:             $ROLE"
echo "Issuer (iss):     $ISS"
echo "Expires (exp):    $EXP"

# Check expiration
if [ -n "$EXP" ]; then
  CURRENT_TIME=$(date +%s)
  if [ "$EXP" -lt "$CURRENT_TIME" ]; then
    echo -e "${RED}⚠ Token is EXPIRED${NC}"
  else
    REMAINING=$((EXP - CURRENT_TIME))
    echo -e "${GREEN}✓ Token valid for $((REMAINING / 60)) minutes${NC}"
  fi
fi

# Generate SQL for testing RLS
echo -e "\n${GREEN}Step 3: Generating Test SQL${NC}"

cat > test-jwt-claims.sql <<EOF
-- Test JWT Claims Extraction
-- Run this in Supabase SQL Editor to verify claim extraction

-- Set JWT claims (simulating authenticated request)
SET request.jwt.claims = '$DECODED_PAYLOAD';

-- Test helper functions
SELECT
  auth.clerk_user_id() as user_id,
  auth.clerk_user_email() as email,
  auth.clerk_org_id() as org_id,
  auth.clerk_role() as role,
  auth.is_clerk_admin() as is_admin;

-- Test with actual table query
-- Replace 'users' with your table name
SELECT * FROM users WHERE clerk_id = auth.clerk_user_id() LIMIT 5;

-- Reset
RESET request.jwt.claims;
EOF

echo "SQL test saved to: test-jwt-claims.sql"
echo ""
echo "Run in Supabase SQL Editor to verify claim extraction"

# Test with Supabase if configured
if [ -n "$SUPABASE_URL" ] && [ -n "$SUPABASE_SERVICE_ROLE_KEY" ]; then
  echo -e "\n${GREEN}Step 4: Testing with Supabase${NC}"

  # Make authenticated request to Supabase
  RESPONSE=$(curl -s "$SUPABASE_URL/rest/v1/users?limit=1" \
    -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
    -H "Authorization: Bearer $JWT_TOKEN")

  echo "Response:"
  echo "$RESPONSE" | jq '.'

  if echo "$RESPONSE" | jq -e '.code' > /dev/null 2>&1; then
    echo -e "${RED}✗ Request failed${NC}"
    echo "Error: $(echo "$RESPONSE" | jq -r '.message')"
  else
    echo -e "${GREEN}✓ Request successful${NC}"
  fi
else
  echo -e "\n${YELLOW}Skipping Supabase test (SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set)${NC}"
fi

# Validate JWT structure
echo -e "\n${GREEN}Step 5: JWT Validation Checklist${NC}"

CHECKS_PASSED=0
CHECKS_TOTAL=5

# Check 1: Has user ID
if [ -n "$USER_ID" ]; then
  echo -e "${GREEN}✓${NC} User ID (sub) present"
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
  echo -e "${RED}✗${NC} User ID (sub) missing"
fi

# Check 2: Has issuer
if [ -n "$ISS" ]; then
  echo -e "${GREEN}✓${NC} Issuer (iss) present"
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
  echo -e "${RED}✗${NC} Issuer (iss) missing"
fi

# Check 3: Not expired
if [ -n "$EXP" ] && [ "$EXP" -gt "$(date +%s)" ]; then
  echo -e "${GREEN}✓${NC} Token not expired"
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
  echo -e "${RED}✗${NC} Token expired or expiration missing"
fi

# Check 4: Has email
if [ -n "$EMAIL" ]; then
  echo -e "${GREEN}✓${NC} Email present"
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
  echo -e "${YELLOW}⚠${NC} Email missing (optional)"
fi

# Check 5: Issuer matches Clerk
if [[ "$ISS" == *"clerk"* ]]; then
  echo -e "${GREEN}✓${NC} Issuer is Clerk"
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
  echo -e "${RED}✗${NC} Issuer doesn't match Clerk"
fi

echo ""
echo "Validation: $CHECKS_PASSED/$CHECKS_TOTAL checks passed"

if [ "$CHECKS_PASSED" -eq "$CHECKS_TOTAL" ]; then
  echo -e "${GREEN}✓ JWT is valid${NC}"
else
  echo -e "${YELLOW}⚠ JWT has issues (see above)${NC}"
fi

echo ""
echo -e "${GREEN}Testing complete!${NC}"
