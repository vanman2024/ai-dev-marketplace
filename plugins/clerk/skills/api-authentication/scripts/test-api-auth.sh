#!/bin/bash

# test-api-auth.sh - Test Clerk API authentication
# Usage: bash test-api-auth.sh <project-path>

set -e

PROJECT_PATH=$1

if [ -z "$PROJECT_PATH" ]; then
    echo "Usage: bash test-api-auth.sh <project-path>"
    exit 1
fi

if [ ! -d "$PROJECT_PATH" ]; then
    echo "Error: Project path does not exist: $PROJECT_PATH"
    exit 1
fi

cd "$PROJECT_PATH"

echo "🧪 Testing Clerk API authentication..."
echo ""

# Check for required environment variables
echo "1️⃣ Checking environment variables..."
if [ ! -f ".env" ]; then
    echo "❌ .env file not found"
    echo "   Create .env from .env.example and add your Clerk keys"
    exit 1
fi

if ! grep -q "CLERK_SECRET_KEY" .env || grep -q "your_clerk_secret_key_here" .env; then
    echo "❌ CLERK_SECRET_KEY not configured in .env"
    echo "   Replace placeholder with your actual Clerk secret key"
    exit 1
fi

echo "✅ Environment variables configured"
echo ""

# Check for middleware files
echo "2️⃣ Checking middleware files..."
MIDDLEWARE_FOUND=false

if [ -f "middleware/clerk-auth.ts" ]; then
    echo "✅ Found Express/Fastify middleware: middleware/clerk-auth.ts"
    MIDDLEWARE_FOUND=true
elif [ -f "lib/clerk-middleware.ts" ]; then
    echo "✅ Found Next.js middleware: lib/clerk-middleware.ts"
    MIDDLEWARE_FOUND=true
elif [ -f "middleware/clerk_auth.py" ]; then
    echo "✅ Found FastAPI middleware: middleware/clerk_auth.py"
    MIDDLEWARE_FOUND=true
fi

if [ "$MIDDLEWARE_FOUND" = false ]; then
    echo "❌ No Clerk middleware found"
    echo "   Run: bash scripts/setup-api-auth.sh <framework> ."
    exit 1
fi

echo ""

# Check for backend SDK initialization
echo "3️⃣ Checking backend SDK setup..."
if [ -f "lib/clerk-backend.ts" ] || [ -f "lib/clerk.ts" ]; then
    echo "✅ Backend SDK initialized"
else
    echo "⚠️  Backend SDK setup file not found (optional)"
fi

echo ""

# Test unauthenticated request (should fail)
echo "4️⃣ Testing unauthenticated request..."
if command -v curl &> /dev/null; then
    # Try to find running server
    if curl -s http://localhost:3000/api/health &> /dev/null; then
        SERVER_URL="http://localhost:3000"
    elif curl -s http://localhost:8000/health &> /dev/null; then
        SERVER_URL="http://localhost:8000"
    else
        echo "⚠️  No running server found at localhost:3000 or localhost:8000"
        echo "   Start your server to run live API tests"
        SERVER_URL=""
    fi

    if [ -n "$SERVER_URL" ]; then
        echo "   Testing: $SERVER_URL/api/protected"
        RESPONSE=$(curl -s -w "\n%{http_code}" "$SERVER_URL/api/protected" || echo "000")
        HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

        if [ "$HTTP_CODE" = "401" ]; then
            echo "✅ Unauthenticated request correctly rejected (401)"
        elif [ "$HTTP_CODE" = "000" ]; then
            echo "⚠️  Could not connect to protected endpoint"
            echo "   Ensure /api/protected route exists and server is running"
        else
            echo "❌ Unexpected status code: $HTTP_CODE (expected 401)"
        fi
    fi
else
    echo "⚠️  curl not installed, skipping live tests"
fi

echo ""

# Check for test files
echo "5️⃣ Checking for authentication tests..."
TEST_FOUND=false

if [ -f "tests/auth.test.ts" ] || [ -f "test/auth.test.ts" ]; then
    echo "✅ Found authentication tests"
    TEST_FOUND=true

    if command -v npm &> /dev/null; then
        echo "   Run: npm test -- auth.test"
    fi
elif [ -f "tests/test_auth.py" ] || [ -f "test/test_auth.py" ]; then
    echo "✅ Found Python authentication tests"
    TEST_FOUND=true

    if command -v pytest &> /dev/null; then
        echo "   Run: pytest tests/test_auth.py"
    fi
fi

if [ "$TEST_FOUND" = false ]; then
    echo "⚠️  No authentication tests found"
    echo "   Consider adding tests for protected routes"
fi

echo ""

# Summary
echo "📊 Test Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

TOTAL=0
PASSED=0

# Environment check
TOTAL=$((TOTAL + 1))
if grep -q "CLERK_SECRET_KEY" .env 2>/dev/null && ! grep -q "your_clerk_secret_key_here" .env 2>/dev/null; then
    PASSED=$((PASSED + 1))
    echo "✅ Environment variables configured"
else
    echo "❌ Environment variables not configured"
fi

# Middleware check
TOTAL=$((TOTAL + 1))
if [ "$MIDDLEWARE_FOUND" = true ]; then
    PASSED=$((PASSED + 1))
    echo "✅ Middleware files present"
else
    echo "❌ Middleware files missing"
fi

# SDK check
TOTAL=$((TOTAL + 1))
if [ -f "lib/clerk-backend.ts" ] || [ -f "lib/clerk.ts" ]; then
    PASSED=$((PASSED + 1))
    echo "✅ Backend SDK initialized"
else
    echo "⚠️  Backend SDK setup (optional)"
fi

# Test files check
TOTAL=$((TOTAL + 1))
if [ "$TEST_FOUND" = true ]; then
    PASSED=$((PASSED + 1))
    echo "✅ Test files present"
else
    echo "⚠️  Test files missing (recommended)"
fi

echo ""
echo "Result: $PASSED/$TOTAL checks passed"

if [ $PASSED -ge 2 ]; then
    echo "✅ API authentication setup looks good!"
    echo ""
    echo "📝 Recommended next steps:"
    echo "1. Start your server"
    echo "2. Test protected endpoints with valid JWT tokens"
    echo "3. Add comprehensive authentication tests"
    echo "4. Implement role-based access control (RBAC)"
    echo "5. Set up webhook handlers for user events"
else
    echo "❌ API authentication setup incomplete"
    echo ""
    echo "📝 Required actions:"
    echo "1. Run: bash scripts/setup-api-auth.sh <framework> ."
    echo "2. Configure environment variables in .env"
    echo "3. Apply middleware to protected routes"
    exit 1
fi
