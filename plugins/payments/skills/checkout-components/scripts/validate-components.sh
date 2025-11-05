#!/bin/bash

# Validate Stripe checkout components setup and configuration
# Usage: bash validate-components.sh [component-name]

set -e

COMPONENT_NAME=$1
ERRORS=0
WARNINGS=0

echo "Validating Stripe checkout components setup..."
echo ""

# Check environment variables
echo "Checking environment variables..."
if [ -f ".env.local" ]; then
  if grep -q "NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_" .env.local 2>/dev/null; then
    echo "✅ NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY configured"
  elif grep -q "NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=.*your.*key.*here" .env.local 2>/dev/null; then
    echo "⚠️  WARNING: NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY is still a placeholder"
    ((WARNINGS++))
  else
    echo "❌ ERROR: NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY not configured"
    ((ERRORS++))
  fi
else
  echo "❌ ERROR: .env.local not found"
  echo "   Run: cp .env.example .env.local"
  ((ERRORS++))
fi

# Check .gitignore
echo ""
echo "Checking .gitignore..."
if [ -f ".gitignore" ]; then
  if grep -q ".env.local" .gitignore; then
    echo "✅ .env.local protected in .gitignore"
  else
    echo "❌ ERROR: .env.local not in .gitignore (security risk!)"
    ((ERRORS++))
  fi
else
  echo "⚠️  WARNING: No .gitignore file found"
  ((WARNINGS++))
fi

# Check dependencies
echo ""
echo "Checking dependencies..."
if [ -f "package.json" ]; then
  if grep -q "@stripe/stripe-js" package.json; then
    echo "✅ @stripe/stripe-js installed"
  else
    echo "❌ ERROR: @stripe/stripe-js not installed"
    echo "   Run: bash scripts/install-stripe-react.sh"
    ((ERRORS++))
  fi

  if grep -q "@stripe/react-stripe-js" package.json; then
    echo "✅ @stripe/react-stripe-js installed"
  else
    echo "❌ ERROR: @stripe/react-stripe-js not installed"
    echo "   Run: bash scripts/install-stripe-react.sh"
    ((ERRORS++))
  fi
else
  echo "❌ ERROR: package.json not found"
  ((ERRORS++))
fi

# Check provider setup
echo ""
echo "Checking provider setup..."
if [ -f "lib/stripe-client.ts" ]; then
  echo "✅ lib/stripe-client.ts exists"

  # Check for hardcoded keys
  if grep -E "pk_(test|live)_[a-zA-Z0-9]{24,}" lib/stripe-client.ts; then
    echo "❌ ERROR: Hardcoded Stripe key found in lib/stripe-client.ts (SECURITY RISK!)"
    ((ERRORS++))
  fi
else
  echo "⚠️  WARNING: lib/stripe-client.ts not found"
  echo "   Run: bash scripts/setup-stripe-provider.sh"
  ((WARNINGS++))
fi

if [ -f "components/providers/stripe-provider.tsx" ]; then
  echo "✅ components/providers/stripe-provider.tsx exists"
else
  echo "⚠️  WARNING: components/providers/stripe-provider.tsx not found"
  echo "   Run: bash scripts/setup-stripe-provider.sh"
  ((WARNINGS++))
fi

# Check specific component if provided
if [ -n "$COMPONENT_NAME" ]; then
  echo ""
  echo "Checking component: $COMPONENT_NAME..."

  COMPONENT_FILE="components/payments/$(echo $COMPONENT_NAME | sed 's/-//')".tsx

  if [ -f "$COMPONENT_FILE" ]; then
    echo "✅ Component exists: $COMPONENT_FILE"

    # Check TypeScript syntax (basic)
    if grep -q "export.*function\|export.*const" "$COMPONENT_FILE"; then
      echo "✅ Component exports found"
    else
      echo "⚠️  WARNING: No component export found"
      ((WARNINGS++))
    fi

    # Check for hardcoded API keys
    if grep -E "(sk|pk)_(test|live)_[a-zA-Z0-9]{24,}" "$COMPONENT_FILE"; then
      echo "❌ ERROR: Hardcoded API key found in component (SECURITY RISK!)"
      ((ERRORS++))
    fi

    # Check for accessibility
    if grep -q "aria-label\|aria-labelledby" "$COMPONENT_FILE"; then
      echo "✅ ARIA labels found (accessibility)"
    else
      echo "⚠️  WARNING: No ARIA labels found (consider adding for accessibility)"
      ((WARNINGS++))
    fi
  else
    echo "❌ ERROR: Component not found: $COMPONENT_FILE"
    echo "   Run: bash scripts/generate-component.sh $COMPONENT_NAME"
    ((ERRORS++))
  fi
fi

# Check all payment components
echo ""
echo "Checking payment components directory..."
if [ -d "components/payments" ]; then
  COMPONENT_COUNT=$(find components/payments -name "*.tsx" -o -name "*.ts" | wc -l)
  echo "✅ components/payments directory exists ($COMPONENT_COUNT files)"

  # List components
  if [ $COMPONENT_COUNT -gt 0 ]; then
    echo "   Components found:"
    find components/payments -name "*.tsx" -o -name "*.ts" | while read file; do
      echo "   - $(basename $file)"
    done
  fi
else
  echo "⚠️  WARNING: components/payments directory not found"
  ((WARNINGS++))
fi

# Security check summary
echo ""
echo "Security checks..."

# Check for any hardcoded keys in entire codebase
if find . -name "*.ts" -o -name "*.tsx" | xargs grep -l "sk_live_" 2>/dev/null; then
  echo "❌ CRITICAL: Live secret key (sk_live_) found in codebase!"
  echo "   NEVER commit secret keys to git!"
  ((ERRORS++))
else
  echo "✅ No live secret keys found in codebase"
fi

if find . -name "*.ts" -o -name "*.tsx" | xargs grep -l "sk_test_" 2>/dev/null; then
  echo "⚠️  WARNING: Test secret key (sk_test_) found in codebase"
  echo "   Secret keys should only be in .env files (server-side)"
  ((WARNINGS++))
else
  echo "✅ No test secret keys found in codebase"
fi

# Final summary
echo ""
echo "=================================================="
echo "Validation Summary"
echo "=================================================="
echo "Errors: $ERRORS"
echo "Warnings: $WARNINGS"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
  echo "✅ All checks passed! Components are ready to use."
  exit 0
elif [ $ERRORS -eq 0 ]; then
  echo "✅ No errors, but $WARNINGS warning(s) found."
  echo "   Review warnings above and fix if needed."
  exit 0
else
  echo "❌ $ERRORS error(s) found. Please fix before proceeding."
  exit 1
fi
