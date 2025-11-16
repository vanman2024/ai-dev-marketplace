#!/bin/bash
# Generate Clerk middleware.ts with route protection configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Usage information
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Generate Clerk middleware.ts with route protection"
    echo ""
    echo "Options:"
    echo "  --app-router       Generate for Next.js App Router (default)"
    echo "  --pages-router     Generate for Next.js Pages Router"
    echo "  --public-routes    Comma-separated list of public routes (e.g., '/,/about,/pricing')"
    echo "  --protected-routes Comma-separated list of protected routes (e.g., '/dashboard,/profile')"
    echo "  --org-routes       Comma-separated list of organization routes (e.g., '/org')"
    echo "  --output           Output file path (default: ./middleware.ts)"
    echo "  --help, -h         Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --app-router --public-routes='/,/about' --protected-routes='/dashboard'"
    echo "  $0 --pages-router --output=./src/middleware.ts"
    exit 0
}

# Default values
ROUTER_TYPE="app"
PUBLIC_ROUTES="/"
PROTECTED_ROUTES=""
ORG_ROUTES=""
OUTPUT_FILE="./middleware.ts"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --app-router)
            ROUTER_TYPE="app"
            shift
            ;;
        --pages-router)
            ROUTER_TYPE="pages"
            shift
            ;;
        --public-routes)
            PUBLIC_ROUTES="$2"
            shift 2
            ;;
        --protected-routes)
            PROTECTED_ROUTES="$2"
            shift 2
            ;;
        --org-routes)
            ORG_ROUTES="$2"
            shift 2
            ;;
        --output)
            OUTPUT_FILE="$2"
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

# Validation
echo -e "${GREEN}Generating Clerk middleware...${NC}"
echo "Router Type: $ROUTER_TYPE"
echo "Public Routes: $PUBLIC_ROUTES"
echo "Protected Routes: $PROTECTED_ROUTES"
echo "Organization Routes: $ORG_ROUTES"
echo "Output: $OUTPUT_FILE"
echo ""

# Check if output file exists
if [ -f "$OUTPUT_FILE" ]; then
    echo -e "${YELLOW}Warning: $OUTPUT_FILE already exists${NC}"
    read -p "Overwrite? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

# Convert comma-separated routes to array format
convert_routes() {
    local routes="$1"
    if [ -z "$routes" ]; then
        echo "[]"
        return
    fi

    # Split by comma and format as TypeScript array
    IFS=',' read -ra ROUTE_ARRAY <<< "$routes"
    local result="["
    for i in "${!ROUTE_ARRAY[@]}"; do
        if [ $i -gt 0 ]; then
            result+=", "
        fi
        result+="'${ROUTE_ARRAY[$i]}'"
    done
    result+="]"
    echo "$result"
}

PUBLIC_ARRAY=$(convert_routes "$PUBLIC_ROUTES")
PROTECTED_ARRAY=$(convert_routes "$PROTECTED_ROUTES")
ORG_ARRAY=$(convert_routes "$ORG_ROUTES")

# Generate middleware content
cat > "$OUTPUT_FILE" << EOF
import { clerkMiddleware, createRouteMatcher } from '@clerk/nextjs/server';
import { NextResponse } from 'next/server';

// Define public routes (accessible without authentication)
const isPublicRoute = createRouteMatcher($PUBLIC_ARRAY);

EOF

# Add protected routes if specified
if [ -n "$PROTECTED_ROUTES" ]; then
cat >> "$OUTPUT_FILE" << EOF
// Define protected routes (require authentication)
const isProtectedRoute = createRouteMatcher($PROTECTED_ARRAY);

EOF
fi

# Add organization routes if specified
if [ -n "$ORG_ROUTES" ]; then
cat >> "$OUTPUT_FILE" << EOF
// Define organization routes (require organization membership)
const isOrgRoute = createRouteMatcher($ORG_ARRAY);

EOF
fi

# Add middleware function
cat >> "$OUTPUT_FILE" << 'EOF'
export default clerkMiddleware((auth, req) => {
  // Get authentication state
  const { userId, orgId } = auth();

EOF

# Add organization check if org routes specified
if [ -n "$ORG_ROUTES" ]; then
cat >> "$OUTPUT_FILE" << 'EOF'
  // Require organization for organization routes
  if (isOrgRoute(req) && !orgId) {
    const selectOrgUrl = new URL('/select-org', req.url);
    return NextResponse.redirect(selectOrgUrl);
  }

EOF
fi

# Add protection logic
cat >> "$OUTPUT_FILE" << 'EOF'
  // Allow public routes
  if (isPublicRoute(req)) {
    return NextResponse.next();
  }

  // Require authentication for all other routes
  if (!userId) {
    const signInUrl = new URL('/sign-in', req.url);
    signInUrl.searchParams.set('redirect_url', req.url);
    return NextResponse.redirect(signInUrl);
  }

  return NextResponse.next();
});

export const config = {
  matcher: [
    // Skip Next.js internals and all static files
    '/((?!_next|[^?]*\\.(?:html?|css|js(?!on)|jpe?g|webp|png|gif|svg|ttf|woff2?|ico|csv|docx?|xlsx?|zip|webmanifest)).*)',
    // Always run for API routes
    '/(api|trpc)(.*)',
  ],
};
EOF

echo -e "${GREEN}✓ Middleware generated successfully at $OUTPUT_FILE${NC}"
echo ""
echo "Next steps:"
echo "1. Ensure environment variables are set in .env.local:"
echo "   NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=your_clerk_publishable_key_here"
echo "   CLERK_SECRET_KEY=your_clerk_secret_key_here"
echo "2. Create sign-in and sign-up pages at /sign-in and /sign-up"
if [ -n "$ORG_ROUTES" ]; then
    echo "3. Create organization selection page at /select-org"
fi
echo ""
echo -e "${YELLOW}⚠ Remember: Never commit real API keys to version control${NC}"
