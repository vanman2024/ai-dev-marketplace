#!/usr/bin/env bash
# check-security.sh - Perform security audit of Clerk integration
# Usage: bash check-security.sh [--detailed] [--fix]

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
DETAILED_MODE=false
FIX_MODE=false
CRITICAL=0
HIGH=0
MEDIUM=0
LOW=0

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --detailed)
      DETAILED_MODE=true
      shift
      ;;
    --fix)
      FIX_MODE=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--detailed] [--fix]"
      exit 1
      ;;
  esac
done

echo "🔒 Clerk Security Audit"
echo "======================="
echo ""

# Helper functions
critical() { echo -e "${RED}[CRITICAL]${NC} $1"; ((CRITICAL++)); }
high() { echo -e "${RED}[HIGH]${NC} $1"; ((HIGH++)); }
medium() { echo -e "${YELLOW}[MEDIUM]${NC} $1"; ((MEDIUM++)); }
low() { echo -e "${BLUE}[LOW]${NC} $1"; ((LOW++)); }
pass() { echo -e "${GREEN}[PASS]${NC} $1"; }

# 1. Check for exposed secret keys
echo "🔑 Checking for exposed API keys..."

# Check for secret keys in client code
if grep -r "sk_test_\|sk_live_" \
  --include="*.tsx" --include="*.jsx" --include="*.ts" --include="*.js" \
  app/ src/ pages/ public/ components/ 2>/dev/null | \
  grep -v "node_modules" | grep -v ".env" | grep -v "your_secret_key_here"; then
  critical "SECRET KEY exposed in client-side code (files listed above)"
  echo "  → This allows attackers to bypass authentication completely"
  echo "  → Move all secret key usage to server-side code or API routes"
else
  pass "No secret keys found in client code"
fi

# Check for hardcoded API keys (not in .env)
if grep -r "pk_test_[a-zA-Z0-9]\{20,\}\|pk_live_[a-zA-Z0-9]\{20,\}" \
  --include="*.tsx" --include="*.jsx" --include="*.ts" --include="*.js" \
  . 2>/dev/null | \
  grep -v "node_modules" | grep -v ".env" | grep -v "your_publishable_key_here" | grep -v ".git"; then
  high "Hardcoded publishable key found (should use environment variables)"
  echo "  → Use process.env.NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY instead"
else
  pass "No hardcoded publishable keys found"
fi

# 2. Environment variable security
echo ""
echo "📝 Checking environment variable configuration..."

# Check if .env is in .gitignore
if [[ -f ".gitignore" ]]; then
  if grep -q "^\.env$\|^\.env\.local$\|^\.env\.\*$" ".gitignore"; then
    pass ".env files properly excluded from version control"
  else
    critical ".env not in .gitignore - API keys may be committed to git!"
    if [[ "$FIX_MODE" == true ]]; then
      echo ".env" >> .gitignore
      echo ".env.local" >> .gitignore
      echo ".env*.local" >> .gitignore
      pass "Added .env to .gitignore"
    fi
  fi
else
  medium ".gitignore not found"
fi

# Check for .env.example
if [[ -f ".env.example" ]] || [[ -f ".env.template" ]]; then
  # Verify .env.example doesn't contain real keys
  if grep -E "pk_test_[a-zA-Z0-9]{20,}|sk_test_[a-zA-Z0-9]{20,}|pk_live_|sk_live_" .env.example .env.template 2>/dev/null | grep -v "your_.*_key_here"; then
    critical "Real API keys found in .env.example/.env.template"
  else
    pass ".env.example contains only placeholders"
  fi
else
  low ".env.example not found (recommended for documentation)"
fi

# 3. Check middleware configuration
echo ""
echo "🛡️  Checking middleware and route protection..."

if [[ -f "middleware.ts" ]] || [[ -f "middleware.js" ]]; then
  MIDDLEWARE_FILE=$([ -f "middleware.ts" ] && echo "middleware.ts" || echo "middleware.js")

  # Check if Clerk middleware is used
  if grep -q "authMiddleware\|clerkMiddleware" "$MIDDLEWARE_FILE"; then
    pass "Clerk middleware configured"

    # Check for publicRoutes configuration
    if grep -q "publicRoutes" "$MIDDLEWARE_FILE"; then
      pass "Public routes explicitly defined"

      # Check if root path is public (common security issue)
      if grep "publicRoutes" "$MIDDLEWARE_FILE" | grep -q '"/"\|"/"'; then
        medium "Root path (/) is public - ensure this is intentional"
      fi
    else
      medium "No publicRoutes defined - all routes may be protected or all public"
    fi

    # Check for ignoredRoutes
    if grep -q "ignoredRoutes" "$MIDDLEWARE_FILE"; then
      if [[ "$DETAILED_MODE" == true ]]; then
        echo "  Ignored routes configured - verify these should bypass auth:"
        grep "ignoredRoutes" "$MIDDLEWARE_FILE"
      fi
    fi
  else
    high "Clerk middleware not configured in $MIDDLEWARE_FILE"
    echo "  → Protected routes may not be secured"
  fi
else
  medium "No middleware.ts found - route protection may not be implemented"
fi

# 4. Check for HTTPS enforcement
echo ""
echo "🔐 Checking HTTPS and secure connection configuration..."

# Check for HTTPS enforcement in production
if [[ -f "next.config.js" ]] || [[ -f "next.config.mjs" ]]; then
  CONFIG_FILE=$([ -f "next.config.js" ] && echo "next.config.js" || echo "next.config.mjs")

  if grep -q "headers()" "$CONFIG_FILE"; then
    if grep -A 10 "headers()" "$CONFIG_FILE" | grep -q "Strict-Transport-Security"; then
      pass "HSTS header configured"
    else
      medium "HSTS header not found - consider adding for production"
    fi
  fi
fi

# Check for secure cookie settings
if grep -r "secure.*cookie\|cookie.*secure" --include="*.ts" --include="*.js" . 2>/dev/null | grep -v node_modules | grep -v ".git"; then
  if [[ "$DETAILED_MODE" == true ]]; then
    echo "  Cookie security settings found - verify they use secure and httpOnly flags"
  fi
fi

# 5. Session security
echo ""
echo "🎫 Checking session security..."

# Check for session timeout configuration
if grep -r "maxAge\|sessionTimeout" --include="*.ts" --include="*.js" . 2>/dev/null | grep -v node_modules | grep -v ".git" | head -3; then
  if [[ "$DETAILED_MODE" == true ]]; then
    pass "Session timeout configuration found"
  fi
else
  low "No explicit session timeout configuration found (using Clerk defaults)"
fi

# 6. CORS and CSP configuration
echo ""
echo "🌐 Checking CORS and Content Security Policy..."

# Check for CORS configuration
if grep -r "cors\|Access-Control-Allow-Origin" --include="*.ts" --include="*.js" . 2>/dev/null | grep -v node_modules | grep -v ".git"; then
  if grep -r "Access-Control-Allow-Origin.*\*" --include="*.ts" --include="*.js" . 2>/dev/null | grep -v node_modules | grep -v ".git"; then
    high "Wildcard CORS policy detected - this is insecure for production"
    echo "  → Restrict to specific domains only"
  elif [[ "$DETAILED_MODE" == true ]]; then
    pass "CORS configuration found - verify it's properly restricted"
  fi
fi

# Check for CSP headers
if [[ -f "next.config.js" ]] || [[ -f "next.config.mjs" ]]; then
  if grep -A 20 "headers()" "$CONFIG_FILE" 2>/dev/null | grep -q "Content-Security-Policy"; then
    pass "Content Security Policy configured"
  else
    medium "CSP not configured - consider adding for enhanced security"
  fi
fi

# 7. Input validation and sanitization
echo ""
echo "🧹 Checking input validation patterns..."

# Check for user input handling
if grep -r "dangerouslySetInnerHTML" --include="*.tsx" --include="*.jsx" . 2>/dev/null | grep -v node_modules | grep -v ".git"; then
  high "dangerouslySetInnerHTML usage found - XSS risk if not properly sanitized"
  echo "  → Ensure all user input is sanitized before rendering"
fi

# 8. Webhook security
echo ""
echo "🪝 Checking webhook security..."

if find . -name "*webhook*" -type f 2>/dev/null | grep -v node_modules | head -1; then
  # Check for signature verification
  if grep -r "svix\|verifyWebhook" --include="*webhook*.ts" --include="*webhook*.js" . 2>/dev/null | grep -v node_modules; then
    pass "Webhook signature verification found"
  else
    critical "Webhook handlers found but no signature verification detected"
    echo "  → Webhooks without verification can be spoofed by attackers"
    echo "  → Use Clerk's webhook signature verification"
  fi
fi

# 9. Rate limiting
echo ""
echo "⏱️  Checking rate limiting..."

if grep -r "rateLimit\|rate-limit" --include="*.ts" --include="*.js" . 2>/dev/null | grep -v node_modules | grep -v ".git" | head -3; then
  pass "Rate limiting implementation found"
else
  medium "No rate limiting detected - consider adding to prevent abuse"
  echo "  → Especially important for auth endpoints and API routes"
fi

# 10. Dependency security
echo ""
echo "📦 Checking dependencies for known vulnerabilities..."

if command -v npm &> /dev/null; then
  if npm audit --omit=dev 2>&1 | grep -q "found 0 vulnerabilities"; then
    pass "No known vulnerabilities in production dependencies"
  else
    echo "Running npm audit..."
    npm audit --omit=dev | head -20
    high "Vulnerabilities found in dependencies - run 'npm audit fix'"
  fi
fi

# Summary
echo ""
echo "======================="
echo "📊 Security Audit Summary"
echo "======================="
echo -e "${RED}Critical: $CRITICAL${NC}"
echo -e "${RED}High: $HIGH${NC}"
echo -e "${YELLOW}Medium: $MEDIUM${NC}"
echo -e "${BLUE}Low: $LOW${NC}"
echo ""

if [[ $CRITICAL -gt 0 ]]; then
  echo -e "${RED}❌ CRITICAL ISSUES FOUND - Fix immediately before deploying!${NC}"
  exit 2
elif [[ $HIGH -gt 0 ]]; then
  echo -e "${RED}⚠️  HIGH PRIORITY ISSUES - Address before production deployment${NC}"
  exit 1
elif [[ $MEDIUM -gt 0 ]]; then
  echo -e "${YELLOW}⚠️  Medium priority issues found - consider addressing${NC}"
  exit 0
else
  echo -e "${GREEN}✓ Security audit passed with only low-priority items${NC}"
  exit 0
fi
