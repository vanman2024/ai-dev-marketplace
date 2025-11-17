#!/bin/bash
# Manually trigger user synchronization from Clerk to Supabase
# Usage: ./sync-users.sh [--all|--user-id=USER_ID]

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}Manual User Sync: Clerk → Supabase${NC}"
echo "======================================"

# Check environment variables
if [ -z "$CLERK_SECRET_KEY" ]; then
  echo -e "${RED}Error: CLERK_SECRET_KEY not set${NC}"
  exit 1
fi

if [ -z "$SUPABASE_URL" ]; then
  echo -e "${RED}Error: SUPABASE_URL not set${NC}"
  exit 1
fi

if [ -z "$SUPABASE_SERVICE_ROLE_KEY" ]; then
  echo -e "${RED}Error: SUPABASE_SERVICE_ROLE_KEY not set${NC}"
  exit 1
fi

# Check for jq
if ! command -v jq &> /dev/null; then
  echo -e "${RED}Error: jq not found${NC}"
  echo "Install: sudo apt install jq"
  exit 1
fi

# Parse arguments
SYNC_ALL=false
USER_ID=""

for arg in "$@"; do
  case $arg in
    --all)
      SYNC_ALL=true
      ;;
    --user-id=*)
      USER_ID="${arg#*=}"
      ;;
    *)
      echo "Usage: ./sync-users.sh [--all|--user-id=USER_ID]"
      exit 1
      ;;
  esac
done

# Function to sync a single user
sync_user() {
  local CLERK_USER_ID="$1"

  echo -e "\n${BLUE}Fetching user from Clerk: $CLERK_USER_ID${NC}"

  # Fetch user from Clerk
  USER_DATA=$(curl -s "https://api.clerk.com/v1/users/$CLERK_USER_ID" \
    -H "Authorization: Bearer $CLERK_SECRET_KEY")

  if echo "$USER_DATA" | jq -e '.errors' > /dev/null 2>&1; then
    echo -e "${RED}✗ Failed to fetch user${NC}"
    echo "$USER_DATA" | jq '.errors'
    return 1
  fi

  # Extract user fields
  CLERK_ID=$(echo "$USER_DATA" | jq -r '.id')
  EMAIL=$(echo "$USER_DATA" | jq -r '.email_addresses[0].email_address // empty')
  FIRST_NAME=$(echo "$USER_DATA" | jq -r '.first_name // empty')
  LAST_NAME=$(echo "$USER_DATA" | jq -r '.last_name // empty')
  AVATAR_URL=$(echo "$USER_DATA" | jq -r '.image_url // empty')
  USERNAME=$(echo "$USER_DATA" | jq -r '.username // empty')
  METADATA=$(echo "$USER_DATA" | jq -c '.public_metadata')
  UPDATED_AT=$(echo "$USER_DATA" | jq -r '.updated_at')

  echo "  Email: $EMAIL"
  echo "  Name: $FIRST_NAME $LAST_NAME"

  # Prepare Supabase payload
  SUPABASE_PAYLOAD=$(jq -n \
    --arg clerk_id "$CLERK_ID" \
    --arg email "$EMAIL" \
    --arg first_name "$FIRST_NAME" \
    --arg last_name "$LAST_NAME" \
    --arg avatar_url "$AVATAR_URL" \
    --arg username "$USERNAME" \
    --argjson metadata "$METADATA" \
    --arg updated_at "$(date -d @$((UPDATED_AT / 1000)) -Iseconds)" \
    '{
      clerk_id: $clerk_id,
      email: $email,
      first_name: $first_name,
      last_name: $last_name,
      avatar_url: $avatar_url,
      username: $username,
      metadata: $metadata,
      updated_at: $updated_at
    }')

  echo -e "\n${BLUE}Syncing to Supabase...${NC}"

  # Upsert to Supabase
  RESPONSE=$(curl -s -X POST "$SUPABASE_URL/rest/v1/users" \
    -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
    -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
    -H "Content-Type: application/json" \
    -H "Prefer: resolution=merge-duplicates" \
    -d "$SUPABASE_PAYLOAD")

  if [ -z "$RESPONSE" ] || [ "$RESPONSE" = "null" ]; then
    echo -e "${GREEN}✓ User synced successfully${NC}"
    return 0
  elif echo "$RESPONSE" | jq -e '.code' > /dev/null 2>&1; then
    echo -e "${RED}✗ Sync failed${NC}"
    echo "$RESPONSE" | jq '.'
    return 1
  else
    echo -e "${GREEN}✓ User synced successfully${NC}"
    return 0
  fi
}

# Sync all users
if [ "$SYNC_ALL" = true ]; then
  echo -e "\n${YELLOW}Syncing ALL users from Clerk${NC}"
  echo "This may take a while..."
  echo ""

  OFFSET=0
  LIMIT=100
  TOTAL_SYNCED=0
  TOTAL_FAILED=0

  while true; do
    echo -e "${BLUE}Fetching users (offset: $OFFSET, limit: $LIMIT)${NC}"

    USERS=$(curl -s "https://api.clerk.com/v1/users?offset=$OFFSET&limit=$LIMIT" \
      -H "Authorization: Bearer $CLERK_SECRET_KEY")

    USER_COUNT=$(echo "$USERS" | jq 'length')

    if [ "$USER_COUNT" -eq 0 ]; then
      break
    fi

    # Process each user
    for i in $(seq 0 $((USER_COUNT - 1))); do
      USER_ID=$(echo "$USERS" | jq -r ".[$i].id")

      if sync_user "$USER_ID"; then
        TOTAL_SYNCED=$((TOTAL_SYNCED + 1))
      else
        TOTAL_FAILED=$((TOTAL_FAILED + 1))
      fi
    done

    OFFSET=$((OFFSET + LIMIT))

    # Check if we got fewer users than the limit (end of pagination)
    if [ "$USER_COUNT" -lt "$LIMIT" ]; then
      break
    fi
  done

  echo ""
  echo -e "${GREEN}Sync complete!${NC}"
  echo "  Synced: $TOTAL_SYNCED users"
  echo "  Failed: $TOTAL_FAILED users"

# Sync single user
elif [ -n "$USER_ID" ]; then
  sync_user "$USER_ID"
  echo ""
  echo -e "${GREEN}Sync complete!${NC}"

# No arguments - show help
else
  echo "Usage:"
  echo "  ./sync-users.sh --all              # Sync all users"
  echo "  ./sync-users.sh --user-id=user_xxx # Sync specific user"
  echo ""
  echo "Environment variables required:"
  echo "  CLERK_SECRET_KEY"
  echo "  SUPABASE_URL"
  echo "  SUPABASE_SERVICE_ROLE_KEY"
  exit 1
fi
