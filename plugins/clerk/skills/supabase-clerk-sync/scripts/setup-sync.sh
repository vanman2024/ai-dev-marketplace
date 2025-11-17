#!/bin/bash
# Setup Supabase to accept Clerk JWT tokens
# Usage: ./setup-sync.sh [project-ref]

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Supabase-Clerk JWT Setup${NC}"
echo "======================================"

# Check required environment variables
if [ -z "$CLERK_PUBLISHABLE_KEY" ]; then
  echo -e "${RED}Error: CLERK_PUBLISHABLE_KEY not set${NC}"
  echo "Get from: https://dashboard.clerk.com/last-active?path=api-keys"
  exit 1
fi

if [ -z "$SUPABASE_PROJECT_REF" ] && [ -z "$1" ]; then
  echo -e "${RED}Error: SUPABASE_PROJECT_REF not set and no project ref provided${NC}"
  echo "Usage: ./setup-sync.sh <project-ref>"
  echo "Or set: export SUPABASE_PROJECT_REF=your_project_ref"
  exit 1
fi

PROJECT_REF="${1:-$SUPABASE_PROJECT_REF}"

# Extract Clerk Frontend API from publishable key
# Format: pk_test_xxx or pk_live_xxx
if [[ $CLERK_PUBLISHABLE_KEY == pk_test_* ]]; then
  CLERK_INSTANCE="https://clerk.your-domain.clerk.accounts.dev"
  echo -e "${YELLOW}Note: Using test environment${NC}"
elif [[ $CLERK_PUBLISHABLE_KEY == pk_live_* ]]; then
  CLERK_INSTANCE="https://clerk.your-domain.com"
  echo -e "${GREEN}Using production environment${NC}"
else
  echo -e "${RED}Error: Invalid CLERK_PUBLISHABLE_KEY format${NC}"
  exit 1
fi

# Extract JWKS URL from Clerk
echo -e "\n${GREEN}Step 1: Extracting Clerk JWKS URL${NC}"
CLERK_JWKS_URL="${CLERK_INSTANCE}/.well-known/jwks.json"
echo "JWKS URL: $CLERK_JWKS_URL"

# Verify JWKS endpoint is accessible
echo -e "\n${GREEN}Step 2: Verifying JWKS endpoint${NC}"
if command -v curl &> /dev/null; then
  JWKS_RESPONSE=$(curl -s "$CLERK_JWKS_URL")
  if echo "$JWKS_RESPONSE" | grep -q "keys"; then
    echo -e "${GREEN}✓ JWKS endpoint accessible${NC}"
  else
    echo -e "${RED}✗ JWKS endpoint not accessible${NC}"
    echo "Response: $JWKS_RESPONSE"
    exit 1
  fi
else
  echo -e "${YELLOW}Warning: curl not found, skipping JWKS verification${NC}"
fi

# Generate JWT secret configuration for Supabase
echo -e "\n${GREEN}Step 3: Generating JWT configuration${NC}"
cat > clerk-jwt-config.json <<EOF
{
  "jwks_uri": "$CLERK_JWKS_URL",
  "issuer": "$CLERK_INSTANCE",
  "claims": {
    "sub": "{{user.id}}",
    "email": "{{user.primary_email_address}}",
    "email_verified": "{{user.primary_email_address_verified}}",
    "role": "{{user.public_metadata.role}}",
    "org_id": "{{user.organization_id}}",
    "org_role": "{{user.organization_role}}"
  }
}
EOF

echo "JWT configuration saved to: clerk-jwt-config.json"

# Instructions for Supabase dashboard configuration
echo -e "\n${GREEN}Step 4: Configure Supabase${NC}"
echo "======================================"
echo "1. Go to: https://app.supabase.com/project/$PROJECT_REF/settings/auth"
echo "2. Navigate to 'JWT Settings' section"
echo "3. Set JWT Secret to:"
echo ""
echo -e "${YELLOW}JWKS URI:${NC} $CLERK_JWKS_URL"
echo ""
echo "4. Add custom claims in 'Additional Settings':"
cat clerk-jwt-config.json | grep -A 10 "claims"
echo ""
echo "5. Save changes and wait for config to propagate (1-2 minutes)"

# Generate SQL for JWT claim extraction
echo -e "\n${GREEN}Step 5: Creating helper functions${NC}"
cat > jwt-helpers.sql <<'EOF'
-- Helper function to extract Clerk user ID from JWT
CREATE OR REPLACE FUNCTION auth.clerk_user_id()
RETURNS TEXT AS $$
  SELECT COALESCE(
    current_setting('request.jwt.claims', true)::json->>'sub',
    NULL
  )::TEXT;
$$ LANGUAGE SQL STABLE;

-- Helper function to extract user email
CREATE OR REPLACE FUNCTION auth.clerk_user_email()
RETURNS TEXT AS $$
  SELECT COALESCE(
    current_setting('request.jwt.claims', true)::json->>'email',
    NULL
  )::TEXT;
$$ LANGUAGE SQL STABLE;

-- Helper function to extract organization ID
CREATE OR REPLACE FUNCTION auth.clerk_org_id()
RETURNS TEXT AS $$
  SELECT COALESCE(
    current_setting('request.jwt.claims', true)::json->>'org_id',
    NULL
  )::TEXT;
$$ LANGUAGE SQL STABLE;

-- Helper function to extract user role
CREATE OR REPLACE FUNCTION auth.clerk_role()
RETURNS TEXT AS $$
  SELECT COALESCE(
    current_setting('request.jwt.claims', true)::json->>'role',
    'user'
  )::TEXT;
$$ LANGUAGE SQL STABLE;

-- Helper function to check if user is admin
CREATE OR REPLACE FUNCTION auth.is_clerk_admin()
RETURNS BOOLEAN AS $$
  SELECT auth.clerk_role() = 'admin';
$$ LANGUAGE SQL STABLE;
EOF

echo "SQL helpers saved to: jwt-helpers.sql"
echo ""
echo "Run in Supabase SQL Editor:"
echo "  cat jwt-helpers.sql | supabase db execute"
echo ""
echo "Or manually execute the SQL in the dashboard"

# Generate environment variables template
echo -e "\n${GREEN}Step 6: Environment variables${NC}"
cat > .env.clerk-supabase <<EOF
# Clerk Configuration
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=$CLERK_PUBLISHABLE_KEY
CLERK_SECRET_KEY=your_clerk_secret_key_here
CLERK_WEBHOOK_SECRET=your_webhook_secret_here

# Supabase Configuration
NEXT_PUBLIC_SUPABASE_URL=https://$PROJECT_REF.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key_here
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here

# Clerk Instance (for JWT validation)
CLERK_FRONTEND_API=$CLERK_INSTANCE
CLERK_JWKS_URL=$CLERK_JWKS_URL
EOF

echo "Environment template saved to: .env.clerk-supabase"
echo ""
echo -e "${YELLOW}Warning: Fill in the placeholder values with actual keys${NC}"

# Summary
echo -e "\n${GREEN}Setup Complete!${NC}"
echo "======================================"
echo "Files created:"
echo "  - clerk-jwt-config.json (JWT configuration)"
echo "  - jwt-helpers.sql (Database helper functions)"
echo "  - .env.clerk-supabase (Environment variables)"
echo ""
echo "Next steps:"
echo "  1. Configure Supabase JWT settings (see Step 4 above)"
echo "  2. Execute jwt-helpers.sql in Supabase"
echo "  3. Fill in .env.clerk-supabase with actual keys"
echo "  4. Run ./configure-rls.sh to set up RLS policies"
echo "  5. Run ./create-webhooks.sh to enable user sync"
echo ""
echo -e "${GREEN}Documentation: See SKILL.md for integration patterns${NC}"
