#!/usr/bin/env bash
# test-auth-flows.sh - Run E2E authentication flow tests for Clerk
# Usage: bash test-auth-flows.sh [--playwright|--cypress] [--headed] [--debug]

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Default configuration
TEST_FRAMEWORK="playwright"
HEADED_MODE=false
DEBUG_MODE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --playwright)
      TEST_FRAMEWORK="playwright"
      shift
      ;;
    --cypress)
      TEST_FRAMEWORK="cypress"
      shift
      ;;
    --headed)
      HEADED_MODE=true
      shift
      ;;
    --debug)
      DEBUG_MODE=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--playwright|--cypress] [--headed] [--debug]"
      exit 1
      ;;
  esac
done

echo "🧪 Clerk Authentication Flow Testing"
echo "====================================="
echo "Framework: $TEST_FRAMEWORK"
echo "Mode: $([ "$HEADED_MODE" = true ] && echo "Headed" || echo "Headless")"
echo ""

# Check for test environment file
if [[ ! -f .env.test ]]; then
  echo -e "${YELLOW}⚠${NC} .env.test not found, creating template..."
  cat > .env.test << 'EOF'
# Clerk Test Configuration
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_your_publishable_key_here
CLERK_SECRET_KEY=sk_test_your_secret_key_here

# Test User Credentials
TEST_USER_EMAIL=test_user@example.com
TEST_USER_PASSWORD=test_password_here
TEST_ADMIN_EMAIL=admin_user@example.com
TEST_ADMIN_PASSWORD=admin_password_here

# OAuth Test Credentials (optional)
TEST_GOOGLE_EMAIL=google_test@example.com
TEST_GOOGLE_PASSWORD=google_password_here

# Application URLs
BASE_URL=http://localhost:3000
SIGN_IN_URL=http://localhost:3000/sign-in
SIGN_UP_URL=http://localhost:3000/sign-up
DASHBOARD_URL=http://localhost:3000/dashboard
EOF
  echo -e "${GREEN}✓${NC} Created .env.test template - please update with real test credentials"
  exit 1
fi

# Load test environment
set -a
source .env.test
set +a

echo -e "${GREEN}✓${NC} Loaded test environment variables"

# Check if app is running
if ! curl -s "$BASE_URL" > /dev/null 2>&1; then
  echo -e "${RED}✗${NC} Application not running at $BASE_URL"
  echo "Please start your development server first:"
  echo "  npm run dev  (or)  pnpm dev"
  exit 1
fi

echo -e "${GREEN}✓${NC} Application running at $BASE_URL"

# Run tests based on framework
if [[ "$TEST_FRAMEWORK" == "playwright" ]]; then
  echo ""
  echo "🎭 Running Playwright tests..."

  # Check if Playwright is installed
  if ! command -v playwright &> /dev/null && ! npx playwright --version &> /dev/null; then
    echo -e "${RED}✗${NC} Playwright not installed"
    echo "Install with: npm install -D @playwright/test"
    exit 1
  fi

  # Build test command
  TEST_CMD="npx playwright test"

  if [[ "$HEADED_MODE" == true ]]; then
    TEST_CMD="$TEST_CMD --headed"
  fi

  if [[ "$DEBUG_MODE" == true ]]; then
    TEST_CMD="$TEST_CMD --debug"
  fi

  # Add Clerk-specific test filter
  TEST_CMD="$TEST_CMD --grep clerk"

  echo "Running: $TEST_CMD"
  eval "$TEST_CMD" || {
    echo -e "${RED}✗${NC} Playwright tests failed"
    exit 1
  }

  echo -e "${GREEN}✓${NC} Playwright tests completed successfully"

elif [[ "$TEST_FRAMEWORK" == "cypress" ]]; then
  echo ""
  echo "🌲 Running Cypress tests..."

  # Check if Cypress is installed
  if ! command -v cypress &> /dev/null && ! npx cypress --version &> /dev/null; then
    echo -e "${RED}✗${NC} Cypress not installed"
    echo "Install with: npm install -D cypress"
    exit 1
  fi

  # Build test command
  if [[ "$HEADED_MODE" == true ]]; then
    TEST_CMD="npx cypress open"
  else
    TEST_CMD="npx cypress run --spec 'cypress/e2e/**/*clerk*.cy.{js,ts}'"
  fi

  echo "Running: $TEST_CMD"
  eval "$TEST_CMD" || {
    echo -e "${RED}✗${NC} Cypress tests failed"
    exit 1
  }

  echo -e "${GREEN}✓${NC} Cypress tests completed successfully"
fi

# Generate coverage report if available
echo ""
echo "📊 Test Coverage Report"
echo "======================="

if [[ -d "coverage" ]] || [[ -d "playwright-report" ]]; then
  if [[ -f "coverage/coverage-summary.json" ]]; then
    echo "Coverage report available at: coverage/index.html"
  fi

  if [[ -d "playwright-report" ]]; then
    echo "Playwright report available at: playwright-report/index.html"
    if [[ "$DEBUG_MODE" == false ]]; then
      echo ""
      echo "To view the report, run:"
      echo "  npx playwright show-report"
    fi
  fi
else
  echo "No coverage report generated"
fi

echo ""
echo -e "${GREEN}✓${NC} Authentication flow tests completed successfully!"
echo ""
echo "Test Summary:"
echo "  Framework: $TEST_FRAMEWORK"
echo "  Mode: $([ "$HEADED_MODE" = true ] && echo "Headed" || echo "Headless")"
echo "  Environment: .env.test"
echo ""
