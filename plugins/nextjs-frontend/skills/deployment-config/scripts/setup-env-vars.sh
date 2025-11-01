#!/bin/bash
# Interactive environment variable setup for Vercel deployment
# Usage: ./setup-env-vars.sh [project-directory]

set -e

PROJECT_DIR="${1:-.}"
cd "$PROJECT_DIR"

echo "🔐 Environment Variable Setup for Vercel"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Detect environment variables used in code
echo -e "${BLUE}🔍 Scanning codebase for environment variables...${NC}"
echo ""

ENV_VARS=()

# Search for process.env usage
if [ -d "app" ] || [ -d "pages" ] || [ -d "src" ]; then
    SEARCH_DIRS="."

    # Find all process.env references
    ENV_REFS=$(grep -rho "process\.env\.[A-Z_][A-Z0-9_]*" \
        --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
        $SEARCH_DIRS 2>/dev/null | \
        sed 's/process\.env\.//' | \
        sort -u)

    if [ -n "$ENV_REFS" ]; then
        echo "Found environment variables:"
        echo "$ENV_REFS" | while read -r var; do
            echo "  - $var"
            ENV_VARS+=("$var")
        done
        echo ""
    else
        echo "No environment variables found in code"
        echo ""
    fi
fi

# Check existing .env files
echo -e "${BLUE}📋 Checking existing environment files...${NC}"
echo ""

if [ -f ".env.local" ]; then
    echo -e "${GREEN}✓${NC} .env.local exists"
    LOCAL_VARS=$(grep -c "^[A-Z_]*=" .env.local || echo "0")
    echo "  Contains $LOCAL_VARS variables"
else
    echo -e "${YELLOW}⚠${NC} .env.local not found"
fi

if [ -f ".env.example" ]; then
    echo -e "${GREEN}✓${NC} .env.example exists"
    EXAMPLE_VARS=$(grep -c "^[A-Z_]*=" .env.example || echo "0")
    echo "  Contains $EXAMPLE_VARS variables"
else
    echo -e "${YELLOW}⚠${NC} .env.example not found"
fi

echo ""

# Interactive mode
echo -e "${BLUE}🛠️  Environment Variable Configuration${NC}"
echo ""
echo "What would you like to do?"
echo ""
echo "  1) Create .env.example (documentation)"
echo "  2) Create .env.local (local development)"
echo "  3) Generate Vercel CLI commands"
echo "  4) View environment variable guide"
echo "  5) Exit"
echo ""
read -p "Select option (1-5): " OPTION

case $OPTION in
    1)
        echo ""
        echo "Creating .env.example..."

        if [ -f ".env.example" ]; then
            read -p ".env.example exists. Overwrite? (y/N): " OVERWRITE
            if [ "$OVERWRITE" != "y" ]; then
                echo "Cancelled."
                exit 0
            fi
        fi

        # Create template
        cat > .env.example << 'EOF'
# Next.js Environment Variables
# Copy this file to .env.local and fill in your values
# NEVER commit .env.local to Git!

# Public variables (exposed to browser, must start with NEXT_PUBLIC_)
NEXT_PUBLIC_API_URL=https://api.example.com
NEXT_PUBLIC_SITE_URL=https://example.com

# Private variables (server-side only, DO NOT use NEXT_PUBLIC_ prefix)
DATABASE_URL=
API_SECRET_KEY=
AUTH_SECRET=

# Third-party service keys (examples)
# STRIPE_SECRET_KEY=
# SENDGRID_API_KEY=
# GOOGLE_ANALYTICS_ID=

# Optional: Feature flags
# NEXT_PUBLIC_FEATURE_FLAG_NEW_UI=false
EOF

        echo -e "${GREEN}✓${NC} Created .env.example"
        echo ""
        echo "Next steps:"
        echo "  1. Edit .env.example with your actual variable names"
        echo "  2. Copy to .env.local and add real values"
        echo "  3. Commit .env.example to Git (without values)"
        ;;

    2)
        echo ""
        echo "Creating .env.local..."

        if [ -f ".env.local" ]; then
            read -p ".env.local exists. Overwrite? (y/N): " OVERWRITE
            if [ "$OVERWRITE" != "y" ]; then
                echo "Cancelled."
                exit 0
            fi
        fi

        if [ -f ".env.example" ]; then
            cp .env.example .env.local
            echo -e "${GREEN}✓${NC} Created .env.local from .env.example"
            echo ""
            echo "Please edit .env.local and fill in actual values"
        else
            cat > .env.local << 'EOF'
# Local Development Environment Variables
# DO NOT COMMIT THIS FILE!

NEXT_PUBLIC_API_URL=http://localhost:3000/api
NEXT_PUBLIC_SITE_URL=http://localhost:3000

# Add your development secrets below
EOF
            echo -e "${GREEN}✓${NC} Created .env.local template"
        fi

        # Ensure .gitignore excludes it
        if ! grep -q "^\.env\.local$" .gitignore 2>/dev/null; then
            echo ".env.local" >> .gitignore
            echo -e "${GREEN}✓${NC} Added .env.local to .gitignore"
        fi
        ;;

    3)
        echo ""
        echo "Generating Vercel CLI commands..."
        echo ""

        if [ ! -f ".env.example" ] && [ ! -f ".env.local" ]; then
            echo -e "${RED}✗${NC} No environment files found"
            echo "Create .env.example first (option 1)"
            exit 1
        fi

        ENV_FILE=".env.example"
        [ -f ".env.local" ] && ENV_FILE=".env.local"

        echo "To add environment variables to Vercel, run these commands:"
        echo ""
        echo -e "${BLUE}# Production environment${NC}"

        grep "^[A-Z_]*=" "$ENV_FILE" | while IFS='=' read -r key value; do
            echo "vercel env add $key production"
        done

        echo ""
        echo -e "${BLUE}# Preview environment${NC}"

        grep "^[A-Z_]*=" "$ENV_FILE" | while IFS='=' read -r key value; do
            echo "vercel env add $key preview"
        done

        echo ""
        echo "Or use the Vercel Dashboard:"
        echo "  https://vercel.com/[team]/[project]/settings/environment-variables"
        echo ""
        echo "To pull environment variables to local:"
        echo "  vercel env pull .env.local"
        ;;

    4)
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Environment Variable Guide"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Public vs Private Variables:"
        echo "----------------------------"
        echo ""
        echo "PUBLIC (browser-accessible):"
        echo "  - MUST start with NEXT_PUBLIC_"
        echo "  - Embedded in JavaScript bundle"
        echo "  - Examples: NEXT_PUBLIC_API_URL, NEXT_PUBLIC_ANALYTICS_ID"
        echo ""
        echo "PRIVATE (server-side only):"
        echo "  - NO NEXT_PUBLIC_ prefix"
        echo "  - Only available in API routes, getServerSideProps, etc."
        echo "  - Examples: DATABASE_URL, API_SECRET_KEY"
        echo ""
        echo "Environment Files:"
        echo "------------------"
        echo ""
        echo ".env.local           - Local development (NEVER commit)"
        echo ".env.development     - Development environment"
        echo ".env.production      - Production environment"
        echo ".env.example         - Documentation (COMMIT THIS)"
        echo ""
        echo "Priority order:"
        echo "  .env.local > .env.[environment] > .env"
        echo ""
        echo "Vercel Environments:"
        echo "-------------------"
        echo ""
        echo "Development  - Local dev (vercel dev)"
        echo "Preview      - Branch deployments"
        echo "Production   - Main branch deployment"
        echo ""
        echo "Best Practices:"
        echo "--------------"
        echo ""
        echo "✓ Use different values per environment"
        echo "✓ Document all variables in .env.example"
        echo "✓ Add .env.local to .gitignore"
        echo "✓ Use NEXT_PUBLIC_ only when necessary"
        echo "✓ Rotate secrets regularly"
        echo "✓ Never hardcode secrets in code"
        echo ""
        ;;

    5)
        echo "Exiting..."
        exit 0
        ;;

    *)
        echo "Invalid option"
        exit 1
        ;;
esac

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Setup complete!"
echo ""
echo "Security checklist:"
echo "  □ .env.local in .gitignore"
echo "  □ .env.example committed (no values)"
echo "  □ Secrets uploaded to Vercel"
echo "  □ Different values per environment"
