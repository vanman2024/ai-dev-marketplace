#!/bin/bash
# Test Clerk middleware authentication guards and protection

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Usage information
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Test Clerk middleware authentication guards and route protection"
    echo ""
    echo "Options:"
    echo "  --url <url>        Base URL to test (default: http://localhost:3000)"
    echo "  --public <routes>  Comma-separated public routes to test"
    echo "  --protected <routes> Comma-separated protected routes to test"
    echo "  --verbose          Show detailed output"
    echo "  --help, -h         Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --url http://localhost:3000 --public '/' --protected '/dashboard'"
    echo "  $0 --verbose --public '/,/about' --protected '/dashboard,/profile'"
    exit 0
}

# Default values
BASE_URL="http://localhost:3000"
PUBLIC_ROUTES="/"
PROTECTED_ROUTES="/dashboard"
VERBOSE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --url)
            BASE_URL="$2"
            shift 2
            ;;
        --public)
            PUBLIC_ROUTES="$2"
            shift 2
            ;;
        --protected)
            PROTECTED_ROUTES="$2"
            shift 2
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            usage
            ;;
        *)
            echo -e "${RED}Error: Unknown option $1${NC}"
            usage
            ;;
    esac
done

# Check if curl is available
if ! command -v curl &> /dev/null; then
    echo -e "${RED}Error: curl is required but not installed${NC}"
    exit 1
fi

# Test results tracking
PASSED=0
FAILED=0
TOTAL=0

# Test a route
test_route() {
    local route="$1"
    local expected_status="$2"
    local description="$3"

    TOTAL=$((TOTAL + 1))

    local url="${BASE_URL}${route}"
    local status=$(curl -s -o /dev/null -w "%{http_code}" -L "$url" 2>/dev/null || echo "000")

    if [ "$VERBOSE" = true ]; then
        echo "Testing: $url"
        echo "Expected: $expected_status"
        echo "Got: $status"
        echo ""
    fi

    if [ "$status" = "$expected_status" ]; then
        echo -e "${GREEN}✓ PASS${NC}: $description"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: $description (expected $expected_status, got $status)"
        FAILED=$((FAILED + 1))
    fi
}

# Test public routes should be accessible
test_public_routes() {
    echo -e "${BLUE}Testing Public Routes (should be accessible)${NC}"
    echo ""

    IFS=',' read -ra ROUTES <<< "$PUBLIC_ROUTES"
    for route in "${ROUTES[@]}"; do
        route=$(echo "$route" | xargs) # trim whitespace
        test_route "$route" "200" "Public route accessible: $route"
    done

    echo ""
}

# Test protected routes should redirect
test_protected_routes() {
    echo -e "${BLUE}Testing Protected Routes (should redirect to sign-in)${NC}"
    echo ""

    IFS=',' read -ra ROUTES <<< "$PROTECTED_ROUTES"
    for route in "${ROUTES[@]}"; do
        route=$(echo "$route" | xargs) # trim whitespace
        # Protected routes should either return 307 (redirect) or 401 (unauthorized)
        local status=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL$route" 2>/dev/null || echo "000")

        if [ "$status" = "307" ] || [ "$status" = "401" ] || [ "$status" = "302" ]; then
            echo -e "${GREEN}✓ PASS${NC}: Protected route redirects: $route (status: $status)"
            PASSED=$((PASSED + 1))
        else
            echo -e "${RED}✗ FAIL${NC}: Protected route should redirect: $route (got $status)"
            FAILED=$((FAILED + 1))
        fi
        TOTAL=$((TOTAL + 1))
    done

    echo ""
}

# Test API routes
test_api_routes() {
    echo -e "${BLUE}Testing API Routes Protection${NC}"
    echo ""

    # Test common API routes
    local api_routes=(
        "/api/user"
        "/api/profile"
        "/api/data"
    )

    for route in "${api_routes[@]}"; do
        # Check if route exists first
        local status=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL$route" 2>/dev/null || echo "000")

        if [ "$status" = "404" ]; then
            if [ "$VERBOSE" = true ]; then
                echo -e "${YELLOW}⊘ SKIP${NC}: API route not found: $route"
            fi
            continue
        fi

        # API routes should return 401 if protected
        if [ "$status" = "401" ] || [ "$status" = "403" ]; then
            echo -e "${GREEN}✓ PASS${NC}: API route protected: $route"
            PASSED=$((PASSED + 1))
        else
            echo -e "${YELLOW}⚠ WARNING${NC}: API route may not be protected: $route (status: $status)"
        fi
        TOTAL=$((TOTAL + 1))
    done

    echo ""
}

# Test middleware configuration
test_middleware_config() {
    echo -e "${BLUE}Testing Middleware Configuration${NC}"
    echo ""

    # Check if middleware.ts exists
    if [ -f "middleware.ts" ]; then
        echo -e "${GREEN}✓${NC} middleware.ts found"

        # Check for required imports
        if grep -q "@clerk/nextjs" middleware.ts; then
            echo -e "${GREEN}✓${NC} Clerk imports found"
        else
            echo -e "${RED}✗${NC} Missing Clerk imports"
            FAILED=$((FAILED + 1))
        fi

        # Check for matcher configuration
        if grep -q "matcher" middleware.ts; then
            echo -e "${GREEN}✓${NC} Route matcher configured"
        else
            echo -e "${YELLOW}⚠${NC} Route matcher not found"
        fi

        # Check for clerkMiddleware
        if grep -q "clerkMiddleware" middleware.ts; then
            echo -e "${GREEN}✓${NC} clerkMiddleware function used"
        else
            echo -e "${RED}✗${NC} clerkMiddleware function not found"
            FAILED=$((FAILED + 1))
        fi
    else
        echo -e "${RED}✗${NC} middleware.ts not found"
        FAILED=$((FAILED + 1))
    fi

    echo ""
}

# Test environment configuration
test_env_config() {
    echo -e "${BLUE}Testing Environment Configuration${NC}"
    echo ""

    # Check for .env.local
    if [ -f ".env.local" ]; then
        echo -e "${GREEN}✓${NC} .env.local found"

        # Check for required variables (without showing values)
        if grep -q "NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY" .env.local; then
            echo -e "${GREEN}✓${NC} NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY configured"
        else
            echo -e "${RED}✗${NC} Missing NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY"
            FAILED=$((FAILED + 1))
        fi

        if grep -q "CLERK_SECRET_KEY" .env.local; then
            echo -e "${GREEN}✓${NC} CLERK_SECRET_KEY configured"
        else
            echo -e "${RED}✗${NC} Missing CLERK_SECRET_KEY"
            FAILED=$((FAILED + 1))
        fi
    else
        echo -e "${YELLOW}⚠${NC} .env.local not found (may be using environment variables)"
    fi

    echo ""
}

# Main execution
echo -e "${BLUE}=== Clerk Middleware Protection Tests ===${NC}"
echo "Base URL: $BASE_URL"
echo ""

# Check if server is running
if ! curl -s --head --max-time 2 "$BASE_URL" > /dev/null 2>&1; then
    echo -e "${YELLOW}Warning: Server may not be running at $BASE_URL${NC}"
    echo "Starting static tests only..."
    echo ""

    test_middleware_config
    test_env_config
else
    echo -e "${GREEN}✓ Server is running${NC}"
    echo ""

    # Run all tests
    test_middleware_config
    test_env_config
    test_public_routes
    test_protected_routes
    test_api_routes
fi

# Summary
echo -e "${BLUE}=== Test Summary ===${NC}"
echo "Total tests: $TOTAL"
echo -e "${GREEN}Passed: $PASSED${NC}"
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}Failed: $FAILED${NC}"
else
    echo "Failed: 0"
fi
echo ""

# Exit with appropriate code
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}✗ Some tests failed${NC}"
    exit 1
else
    echo -e "${GREEN}✓ All tests passed${NC}"
    exit 0
fi
