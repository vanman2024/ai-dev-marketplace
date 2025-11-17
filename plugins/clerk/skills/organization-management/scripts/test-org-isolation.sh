#!/bin/bash
# test-org-isolation.sh - Test organization data isolation
# Usage: ./test-org-isolation.sh

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "================================================"
echo "Organization Data Isolation Test"
echo "================================================"
echo ""

echo -e "${BLUE}This script tests multi-tenant data isolation.${NC}"
echo ""

# Check if we're in a project directory
if [ ! -f "package.json" ]; then
  echo -e "${RED}Error: package.json not found. Run from project root.${NC}"
  exit 1
fi

echo -e "${YELLOW}Prerequisites:${NC}"
echo "1. Application is running (dev or production)"
echo "2. Database has organization_id columns on all tables"
echo "3. RLS policies are enabled (if using Supabase/Postgres)"
echo "4. You have test accounts in multiple organizations"
echo ""
echo -e "${YELLOW}Press Enter to continue...${NC}"
read -r

# Test checklist
echo ""
echo -e "${GREEN}Manual Test Checklist:${NC}"
echo ""

tests=(
  "Create a resource (project/item) in Organization A"
  "Switch to Organization B"
  "Verify resource from Org A is NOT visible in Org B"
  "Create a different resource in Organization B"
  "Switch back to Organization A"
  "Verify resource from Org B is NOT visible in Org A"
  "Verify both organizations can have resources with same names"
  "Test that deleting resource in Org A doesn't affect Org B"
)

for i in "${!tests[@]}"; do
  num=$((i + 1))
  echo -e "${BLUE}Test $num:${NC} ${tests[$i]}"
  echo -n "  Result (pass/fail/skip): "
  read -r result

  case "$result" in
    pass|p)
      echo -e "  ${GREEN}✓ PASSED${NC}"
      ;;
    fail|f)
      echo -e "  ${RED}✗ FAILED${NC}"
      echo -e "  ${YELLOW}Action needed: Fix data isolation before continuing${NC}"
      ;;
    skip|s)
      echo -e "  ${YELLOW}○ SKIPPED${NC}"
      ;;
    *)
      echo -e "  ${YELLOW}○ SKIPPED (invalid input)${NC}"
      ;;
  esac
  echo ""
done

# Database-specific tests
echo ""
echo -e "${GREEN}Database Isolation Tests:${NC}"
echo ""

# Check if using Supabase
if grep -q "@supabase/supabase-js" package.json 2>/dev/null; then
  echo -e "${BLUE}Detected Supabase.${NC}"
  echo ""
  echo "RLS Policy Checklist:"
  echo ""
  echo "1. All tables have organization_id column"
  echo "2. RLS is enabled on all tables (ALTER TABLE ... ENABLE ROW LEVEL SECURITY)"
  echo "3. RLS policies filter by organization_id"
  echo "4. Policies use authenticated user's organization context"
  echo ""
  echo -e "${YELLOW}Verify these in your Supabase dashboard.${NC}"
  echo ""
fi

# Check if using Prisma
if [ -f "prisma/schema.prisma" ]; then
  echo -e "${BLUE}Detected Prisma.${NC}"
  echo ""
  echo "Checking schema for organization_id fields..."
  echo ""

  # Count models with organizationId
  models_with_org=$(grep -c "organizationId" prisma/schema.prisma || echo "0")
  total_models=$(grep -c "^model " prisma/schema.prisma || echo "0")

  if [ "$models_with_org" -eq 0 ]; then
    echo -e "${RED}✗ No models have organizationId field${NC}"
    echo -e "${YELLOW}Add organizationId String to all tenant-scoped models${NC}"
  elif [ "$models_with_org" -lt "$total_models" ]; then
    echo -e "${YELLOW}⚠ Only $models_with_org/$total_models models have organizationId${NC}"
    echo -e "${YELLOW}Review schema to ensure all tenant data includes organizationId${NC}"
  else
    echo -e "${GREEN}✓ All $total_models models include organizationId${NC}"
  fi
  echo ""
fi

# Role-based access tests
echo ""
echo -e "${GREEN}RBAC Tests:${NC}"
echo ""

rbac_tests=(
  "Admin can invite members to organization"
  "Member cannot access admin-only features"
  "Viewer (if exists) has read-only access"
  "Users cannot access organizations they don't belong to"
  "Role changes take effect immediately"
)

for i in "${!rbac_tests[@]}"; do
  num=$((i + 1))
  echo -e "${BLUE}RBAC Test $num:${NC} ${rbac_tests[$i]}"
  echo -n "  Result (pass/fail/skip): "
  read -r result

  case "$result" in
    pass|p)
      echo -e "  ${GREEN}✓ PASSED${NC}"
      ;;
    fail|f)
      echo -e "  ${RED}✗ FAILED${NC}"
      echo -e "  ${YELLOW}Action needed: Review RBAC configuration${NC}"
      ;;
    skip|s)
      echo -e "  ${YELLOW}○ SKIPPED${NC}"
      ;;
    *)
      echo -e "  ${YELLOW}○ SKIPPED (invalid input)${NC}"
      ;;
  esac
  echo ""
done

# Summary
echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}Test Summary${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo "Review test results above."
echo ""
echo "Common issues:"
echo ""
echo "1. ${YELLOW}Data leaking between orgs:${NC}"
echo "   - Missing organizationId in queries"
echo "   - RLS policies not configured correctly"
echo "   - Frontend not filtering by organization"
echo ""
echo "2. ${YELLOW}RBAC not working:${NC}"
echo "   - Roles not defined in Clerk Dashboard"
echo "   - Permission checks missing in code"
echo "   - Middleware not checking roles"
echo ""
echo "3. ${YELLOW}Organization switching issues:${NC}"
echo "   - Context not updating after switch"
echo "   - Cached data not refreshing"
echo "   - API calls using old organization ID"
echo ""
echo -e "${BLUE}See SKILL.md and templates/ for troubleshooting guidance.${NC}"
echo ""
