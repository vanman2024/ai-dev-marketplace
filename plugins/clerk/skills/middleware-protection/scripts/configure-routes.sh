#!/bin/bash
# Configure route protection patterns for Clerk middleware

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
    echo "Configure route protection patterns for Clerk middleware"
    echo ""
    echo "Options:"
    echo "  --analyze          Analyze existing project routes"
    echo "  --interactive      Interactive route configuration"
    echo "  --preset <type>    Use preset configuration (landing, dashboard, saas, admin)"
    echo "  --help, -h         Show this help message"
    echo ""
    echo "Presets:"
    echo "  landing   - Public landing page with protected dashboard"
    echo "  dashboard - Full dashboard with organization support"
    echo "  saas      - Multi-tenant SaaS application"
    echo "  admin     - Admin panel with role-based access"
    exit 0
}

# Analyze project structure
analyze_routes() {
    echo -e "${BLUE}Analyzing project routes...${NC}"
    echo ""

    # Check for Next.js router type
    if [ -d "app" ]; then
        echo "✓ Detected: Next.js App Router"
        ROUTER_TYPE="app"
    elif [ -d "pages" ]; then
        echo "✓ Detected: Next.js Pages Router"
        ROUTER_TYPE="pages"
    else
        echo -e "${RED}Error: Could not detect Next.js project${NC}"
        exit 1
    fi

    echo ""
    echo -e "${GREEN}Route Discovery:${NC}"

    # Find routes based on router type
    if [ "$ROUTER_TYPE" = "app" ]; then
        echo "App Router routes:"
        find app -name "page.tsx" -o -name "page.ts" -o -name "page.jsx" -o -name "page.js" 2>/dev/null | while read -r file; do
            route=$(dirname "$file" | sed 's|app||' | sed 's|/page||' | sed 's|/route||')
            [ -z "$route" ] && route="/"
            echo "  - $route"
        done
    else
        echo "Pages Router routes:"
        find pages -name "*.tsx" -o -name "*.ts" -o -name "*.jsx" -o -name "*.js" 2>/dev/null | while read -r file; do
            route=$(echo "$file" | sed 's|pages||' | sed 's|\.tsx$||' | sed 's|\.ts$||' | sed 's|\.jsx$||' | sed 's|\.js$||' | sed 's|/index$||')
            [ -z "$route" ] && route="/"
            echo "  - $route"
        done
    fi

    echo ""
    echo -e "${GREEN}API Routes:${NC}"
    if [ -d "app/api" ]; then
        find app/api -name "route.tsx" -o -name "route.ts" 2>/dev/null | while read -r file; do
            route=$(dirname "$file" | sed 's|app||')
            echo "  - $route"
        done
    elif [ -d "pages/api" ]; then
        find pages/api -name "*.tsx" -o -name "*.ts" -o -name "*.jsx" -o -name "*.js" 2>/dev/null | while read -r file; do
            route=$(echo "$file" | sed 's|pages||' | sed 's|\.tsx$||' | sed 's|\.ts$||' | sed 's|\.jsx$||' | sed 's|\.js$||')
            echo "  - $route"
        done
    fi

    echo ""
}

# Interactive configuration
interactive_config() {
    echo -e "${BLUE}Interactive Route Configuration${NC}"
    echo ""

    # Public routes
    echo "Enter public routes (comma-separated, e.g., /,/about,/pricing):"
    read -r PUBLIC_ROUTES
    [ -z "$PUBLIC_ROUTES" ] && PUBLIC_ROUTES="/"

    # Protected routes
    echo "Enter protected routes (comma-separated, e.g., /dashboard,/profile):"
    read -r PROTECTED_ROUTES

    # Organization routes
    echo "Do you need organization routes? (y/N):"
    read -r -n 1 NEED_ORG
    echo
    if [[ $NEED_ORG =~ ^[Yy]$ ]]; then
        echo "Enter organization routes (comma-separated, e.g., /org,/teams):"
        read -r ORG_ROUTES
    else
        ORG_ROUTES=""
    fi

    # Generate middleware
    echo ""
    echo -e "${GREEN}Generating middleware with configuration...${NC}"

    local cmd="bash $(dirname "$0")/generate-middleware.sh"
    cmd="$cmd --public-routes='$PUBLIC_ROUTES'"
    [ -n "$PROTECTED_ROUTES" ] && cmd="$cmd --protected-routes='$PROTECTED_ROUTES'"
    [ -n "$ORG_ROUTES" ] && cmd="$cmd --org-routes='$ORG_ROUTES'"

    eval "$cmd"
}

# Preset configurations
apply_preset() {
    local preset="$1"
    echo -e "${BLUE}Applying '$preset' preset configuration${NC}"
    echo ""

    case "$preset" in
        landing)
            PUBLIC_ROUTES="/,/about,/pricing,/contact"
            PROTECTED_ROUTES="/dashboard,/profile,/settings"
            ORG_ROUTES=""
            ;;
        dashboard)
            PUBLIC_ROUTES="/,/sign-in,/sign-up"
            PROTECTED_ROUTES="/dashboard,/profile,/settings"
            ORG_ROUTES="/org,/teams"
            ;;
        saas)
            PUBLIC_ROUTES="/,/features,/pricing,/docs"
            PROTECTED_ROUTES="/app,/dashboard,/projects,/settings"
            ORG_ROUTES="/org,/workspaces,/teams"
            ;;
        admin)
            PUBLIC_ROUTES="/,/sign-in"
            PROTECTED_ROUTES="/admin,/dashboard,/users,/settings,/analytics"
            ORG_ROUTES=""
            ;;
        *)
            echo -e "${RED}Error: Unknown preset '$preset'${NC}"
            echo "Available presets: landing, dashboard, saas, admin"
            exit 1
            ;;
    esac

    echo "Configuration:"
    echo "  Public Routes: $PUBLIC_ROUTES"
    echo "  Protected Routes: $PROTECTED_ROUTES"
    [ -n "$ORG_ROUTES" ] && echo "  Organization Routes: $ORG_ROUTES"
    echo ""

    # Generate middleware
    local cmd="bash $(dirname "$0")/generate-middleware.sh"
    cmd="$cmd --public-routes='$PUBLIC_ROUTES'"
    [ -n "$PROTECTED_ROUTES" ] && cmd="$cmd --protected-routes='$PROTECTED_ROUTES'"
    [ -n "$ORG_ROUTES" ] && cmd="$cmd --org-routes='$ORG_ROUTES'"

    eval "$cmd"

    echo ""
    echo -e "${GREEN}✓ Preset applied successfully${NC}"
}

# Main logic
MODE=""
PRESET=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --analyze)
            MODE="analyze"
            shift
            ;;
        --interactive)
            MODE="interactive"
            shift
            ;;
        --preset)
            MODE="preset"
            PRESET="$2"
            shift 2
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

# Execute based on mode
case "$MODE" in
    analyze)
        analyze_routes
        ;;
    interactive)
        interactive_config
        ;;
    preset)
        if [ -z "$PRESET" ]; then
            echo -e "${RED}Error: --preset requires a preset name${NC}"
            usage
        fi
        apply_preset "$PRESET"
        ;;
    *)
        echo -e "${YELLOW}No mode specified. Use --analyze, --interactive, or --preset${NC}"
        usage
        ;;
esac
