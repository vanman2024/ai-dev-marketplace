#!/bin/bash
# Validate Stripe configuration
# Checks API keys, environment setup, security best practices

set -e

echo "Validating Stripe configuration..."
echo ""

ERRORS=0
WARNINGS=0

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "❌ ERROR: .env file not found"
    echo "   Create .env from .env.example template"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ .env file exists"
fi

# Check if .env.example exists
if [ ! -f ".env.example" ]; then
    echo "⚠️  WARNING: .env.example template not found"
    echo "   Create template with placeholders for team members"
    WARNINGS=$((WARNINGS + 1))
else
    echo "✅ .env.example template exists"

    # Check .env.example doesn't contain real keys
    if grep -qE "sk-test_|sk-live_|rk_test_|rk_live_|whsec_" .env.example 2>/dev/null; then
        echo "❌ ERROR: .env.example contains real API keys!"
        echo "   Replace with placeholders: your_stripe_key_here"
        ERRORS=$((ERRORS + 1))
    else
        echo "✅ .env.example uses placeholders only"
    fi
fi

# Check .gitignore exists and protects .env
if [ ! -f ".gitignore" ]; then
    echo "❌ ERROR: .gitignore not found"
    echo "   Create .gitignore to protect secret files"
    ERRORS=$((ERRORS + 1))
else
    if grep -q "^\.env$" .gitignore; then
        echo "✅ .gitignore protects .env file"
    else
        echo "❌ ERROR: .gitignore doesn't protect .env"
        echo "   Add '.env' to .gitignore"
        ERRORS=$((ERRORS + 1))
    fi
fi

# Check if .env has required Stripe keys
if [ -f ".env" ]; then
    source .env 2>/dev/null || true

    if [ -z "$STRIPE_SECRET_KEY" ]; then
        echo "❌ ERROR: STRIPE_SECRET_KEY not set in .env"
        ERRORS=$((ERRORS + 1))
    else
        # Check key format
        if [[ $STRIPE_SECRET_KEY == sk_test_* ]]; then
            echo "✅ STRIPE_SECRET_KEY set (test mode)"
        elif [[ $STRIPE_SECRET_KEY == sk_live_* ]]; then
            echo "✅ STRIPE_SECRET_KEY set (live mode)"
            echo "⚠️  WARNING: Using live Stripe keys - ensure proper security!"
            WARNINGS=$((WARNINGS + 1))
        elif [[ $STRIPE_SECRET_KEY == *your_stripe*key* ]] || [[ $STRIPE_SECRET_KEY == your_* ]]; then
            echo "❌ ERROR: STRIPE_SECRET_KEY is still placeholder"
            echo "   Replace with real key from Stripe Dashboard"
            ERRORS=$((ERRORS + 1))
        else
            echo "⚠️  WARNING: STRIPE_SECRET_KEY format unrecognized"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi

    if [ -z "$STRIPE_PUBLISHABLE_KEY" ]; then
        echo "⚠️  WARNING: STRIPE_PUBLISHABLE_KEY not set"
        echo "   Required for frontend payment forms"
        WARNINGS=$((WARNINGS + 1))
    else
        if [[ $STRIPE_PUBLISHABLE_KEY == pk_test_* ]]; then
            echo "✅ STRIPE_PUBLISHABLE_KEY set (test mode)"
        elif [[ $STRIPE_PUBLISHABLE_KEY == pk_live_* ]]; then
            echo "✅ STRIPE_PUBLISHABLE_KEY set (live mode)"
        elif [[ $STRIPE_PUBLISHABLE_KEY == *your_stripe*key* ]] || [[ $STRIPE_PUBLISHABLE_KEY == your_* ]]; then
            echo "❌ ERROR: STRIPE_PUBLISHABLE_KEY is still placeholder"
            ERRORS=$((ERRORS + 1))
        fi
    fi

    if [ -z "$STRIPE_WEBHOOK_SECRET" ]; then
        echo "⚠️  WARNING: STRIPE_WEBHOOK_SECRET not set"
        echo "   Required for webhook signature verification"
        echo "   Get from Stripe CLI or Dashboard webhook settings"
        WARNINGS=$((WARNINGS + 1))
    else
        if [[ $STRIPE_WEBHOOK_SECRET == whsec_* ]]; then
            echo "✅ STRIPE_WEBHOOK_SECRET set"
        elif [[ $STRIPE_WEBHOOK_SECRET == *your_webhook*secret* ]] || [[ $STRIPE_WEBHOOK_SECRET == your_* ]]; then
            echo "❌ ERROR: STRIPE_WEBHOOK_SECRET is still placeholder"
            ERRORS=$((ERRORS + 1))
        fi
    fi
fi

# Check for accidentally committed secrets in git
if [ -d ".git" ]; then
    if git ls-files --error-unmatch .env >/dev/null 2>&1; then
        echo "❌ ERROR: .env is tracked by git!"
        echo "   Remove with: git rm --cached .env"
        echo "   Add to .gitignore and commit"
        ERRORS=$((ERRORS + 1))
    else
        echo "✅ .env not tracked by git"
    fi
fi

# Check Python dependencies
if [ -f "requirements.txt" ]; then
    if grep -q "^stripe" requirements.txt; then
        echo "✅ stripe package in requirements.txt"
    else
        echo "⚠️  WARNING: stripe package not in requirements.txt"
        echo "   Add: stripe>=5.0.0"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

# Check if stripe module is importable
if command -v python3 >/dev/null 2>&1; then
    if python3 -c "import stripe" 2>/dev/null; then
        echo "✅ stripe Python package installed"

        # Get version
        VERSION=$(python3 -c "import stripe; print(stripe.__version__)" 2>/dev/null)
        echo "   Version: $VERSION"
    else
        echo "⚠️  WARNING: stripe Python package not installed"
        echo "   Install with: pip install stripe"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

# Check Node.js Stripe packages
if [ -f "package.json" ]; then
    if grep -q "@stripe/stripe-js" package.json; then
        echo "✅ @stripe/stripe-js in package.json"
    else
        echo "⚠️  WARNING: @stripe/stripe-js not in package.json"
        echo "   Install with: npm install @stripe/stripe-js"
        WARNINGS=$((WARNINGS + 1))
    fi

    if grep -q "@stripe/react-stripe-js" package.json; then
        echo "✅ @stripe/react-stripe-js in package.json"
    else
        echo "⚠️  WARNING: @stripe/react-stripe-js not in package.json"
        echo "   Install with: npm install @stripe/react-stripe-js"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

# Security checks - scan for hardcoded keys in code
echo ""
echo "Scanning for hardcoded API keys in code..."

# Scan Python files
if compgen -G "**/*.py" > /dev/null; then
    if grep -r "sk_test_\|sk_live_" --include="*.py" . 2>/dev/null | grep -v ".env"; then
        echo "❌ ERROR: Found hardcoded Stripe secret keys in Python files!"
        echo "   Use environment variables: os.getenv('STRIPE_SECRET_KEY')"
        ERRORS=$((ERRORS + 1))
    else
        echo "✅ No hardcoded secret keys in Python files"
    fi
fi

# Scan JavaScript/TypeScript files
if compgen -G "**/*.{js,ts,jsx,tsx}" > /dev/null; then
    if grep -r "sk_test_\|sk_live_" --include="*.js" --include="*.ts" --include="*.jsx" --include="*.tsx" . 2>/dev/null | grep -v node_modules; then
        echo "❌ ERROR: Found hardcoded Stripe secret keys in JS/TS files!"
        echo "   NEVER expose secret keys in frontend code!"
        ERRORS=$((ERRORS + 1))
    else
        echo "✅ No hardcoded secret keys in JS/TS files"
    fi
fi

# Summary
echo ""
echo "============================================"
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "✅ Validation passed! Stripe configuration is secure."
elif [ $ERRORS -eq 0 ]; then
    echo "⚠️  Validation passed with $WARNINGS warning(s)"
    echo "   Review warnings above"
else
    echo "❌ Validation failed with $ERRORS error(s) and $WARNINGS warning(s)"
    echo "   Fix errors before deploying"
    exit 1
fi
echo "============================================"
