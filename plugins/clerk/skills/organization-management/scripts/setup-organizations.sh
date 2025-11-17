#!/bin/bash
# setup-organizations.sh - Enable and configure Clerk organizations
# Usage: ./setup-organizations.sh

set -e

echo "================================================"
echo "Clerk Organization Setup"
echo "================================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running in a project directory
if [ ! -f "package.json" ]; then
  echo -e "${RED}Error: package.json not found. Run this script from your project root.${NC}"
  exit 1
fi

echo -e "${BLUE}This script will guide you through enabling Clerk organizations.${NC}"
echo ""

# Step 1: Clerk Dashboard Configuration
echo -e "${GREEN}Step 1: Enable Organizations in Clerk Dashboard${NC}"
echo ""
echo "Visit your Clerk Dashboard and complete these steps:"
echo ""
echo "1. Go to https://dashboard.clerk.com"
echo "2. Select your application"
echo "3. Navigate to 'Configure' → 'Organizations'"
echo "4. Click 'Enable Organizations'"
echo "5. Configure organization settings:"
echo "   - Allow users to create organizations: YES/NO"
echo "   - Max organizations per user: Set limit or unlimited"
echo "   - Enable organization profiles: YES"
echo "   - Enable organization domains: YES (if using verified domains)"
echo ""
echo -e "${YELLOW}Press Enter after completing Clerk Dashboard setup...${NC}"
read -r

# Step 2: Check Clerk package installation
echo ""
echo -e "${GREEN}Step 2: Verify Clerk Package Installation${NC}"
echo ""

CLERK_PACKAGE=""
if grep -q "@clerk/nextjs" package.json; then
  CLERK_PACKAGE="@clerk/nextjs"
  echo -e "${GREEN}✓ Found @clerk/nextjs${NC}"
elif grep -q "@clerk/clerk-react" package.json; then
  CLERK_PACKAGE="@clerk/clerk-react"
  echo -e "${GREEN}✓ Found @clerk/clerk-react${NC}"
else
  echo -e "${RED}✗ Clerk package not found. Please install @clerk/nextjs or @clerk/clerk-react first.${NC}"
  exit 1
fi

# Step 3: Check environment variables
echo ""
echo -e "${GREEN}Step 3: Verify Environment Variables${NC}"
echo ""

ENV_FILE=".env.local"
if [ ! -f "$ENV_FILE" ]; then
  ENV_FILE=".env"
fi

if [ -f "$ENV_FILE" ]; then
  if grep -q "NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY" "$ENV_FILE" && grep -q "CLERK_SECRET_KEY" "$ENV_FILE"; then
    echo -e "${GREEN}✓ Clerk environment variables found in $ENV_FILE${NC}"
  else
    echo -e "${YELLOW}⚠ Missing Clerk environment variables in $ENV_FILE${NC}"
    echo ""
    echo "Add these to your $ENV_FILE:"
    echo ""
    echo "NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_your_clerk_key_here"
    echo "CLERK_SECRET_KEY=sk_test_your_clerk_secret_here"
    echo ""
    echo -e "${YELLOW}Press Enter after adding environment variables...${NC}"
    read -r
  fi
else
  echo -e "${YELLOW}⚠ No .env file found. Creating .env.example...${NC}"
  cat > .env.example << 'EOF'
# Clerk Configuration
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_your_clerk_key_here
CLERK_SECRET_KEY=sk_test_your_clerk_secret_here

# Organization Feature Flags (optional)
NEXT_PUBLIC_ENABLE_ORG_CREATION=true
NEXT_PUBLIC_MAX_ORGS_PER_USER=5
EOF
  echo -e "${GREEN}✓ Created .env.example${NC}"
  echo -e "${YELLOW}Copy .env.example to .env.local and add your actual keys.${NC}"
  exit 0
fi

# Step 4: Create organization components directory (if not exists)
echo ""
echo -e "${GREEN}Step 4: Create Organization Components Directory${NC}"
echo ""

COMPONENTS_DIR="src/components/organizations"
if [ ! -d "$COMPONENTS_DIR" ]; then
  mkdir -p "$COMPONENTS_DIR"
  echo -e "${GREEN}✓ Created $COMPONENTS_DIR${NC}"
else
  echo -e "${BLUE}→ Directory already exists: $COMPONENTS_DIR${NC}"
fi

# Step 5: Summary and next steps
echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}Organization Setup Complete!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo "Next steps:"
echo ""
echo "1. Configure RBAC roles and permissions:"
echo "   ./scripts/configure-roles.sh [basic|advanced|custom]"
echo ""
echo "2. Add organization components to your app:"
echo "   - Copy templates/organization-switcher.tsx to your components"
echo "   - Add organization context to your layout"
echo ""
echo "3. Test organization features:"
echo "   - Create a test organization in your app"
echo "   - Invite team members"
echo "   - Test organization switching"
echo ""
echo "4. (Optional) Setup organization data isolation:"
echo "   - Follow templates/organization-schema.md for database setup"
echo "   - Run ./scripts/test-org-isolation.sh to verify"
echo ""
echo -e "${BLUE}See SKILL.md for complete documentation and examples.${NC}"
echo ""
