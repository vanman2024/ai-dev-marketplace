#!/bin/bash

# setup-api-auth.sh - Configure Clerk API authentication for backend
# Usage: bash setup-api-auth.sh <framework> <project-path>

set -e

FRAMEWORK=$1
PROJECT_PATH=$2

if [ -z "$FRAMEWORK" ] || [ -z "$PROJECT_PATH" ]; then
    echo "Usage: bash setup-api-auth.sh <framework> <project-path>"
    echo "Frameworks: express, fastify, nextjs, fastapi"
    exit 1
fi

if [ ! -d "$PROJECT_PATH" ]; then
    echo "Error: Project path does not exist: $PROJECT_PATH"
    exit 1
fi

echo "🔧 Setting up Clerk API authentication for $FRAMEWORK..."

# Navigate to project
cd "$PROJECT_PATH"

# Install dependencies based on framework
case $FRAMEWORK in
    express)
        echo "📦 Installing Express Clerk SDK..."
        npm install @clerk/clerk-sdk-node @clerk/express
        MIDDLEWARE_FILE="middleware/clerk-auth.ts"
        ;;
    fastify)
        echo "📦 Installing Fastify Clerk SDK..."
        npm install @clerk/clerk-sdk-node @clerk/fastify
        MIDDLEWARE_FILE="middleware/clerk-auth.ts"
        ;;
    nextjs)
        echo "📦 Installing Next.js Clerk SDK..."
        npm install @clerk/nextjs
        MIDDLEWARE_FILE="lib/clerk-middleware.ts"
        ;;
    fastapi)
        echo "📦 Installing Python Clerk SDK..."
        pip install clerk-backend-api
        MIDDLEWARE_FILE="middleware/clerk_auth.py"
        ;;
    *)
        echo "Error: Unsupported framework: $FRAMEWORK"
        echo "Supported: express, fastify, nextjs, fastapi"
        exit 1
        ;;
esac

# Create middleware directory
mkdir -p "$(dirname "$MIDDLEWARE_FILE")"

# Copy middleware template based on framework
SKILL_DIR="$(dirname "$(dirname "$0")")"
TEMPLATE_DIR="$SKILL_DIR/templates"

case $FRAMEWORK in
    express|fastify)
        cp "$TEMPLATE_DIR/api-middleware.ts" "$MIDDLEWARE_FILE"
        echo "✅ Created middleware: $MIDDLEWARE_FILE"
        ;;
    nextjs)
        cp "$TEMPLATE_DIR/api-routes.ts" "$MIDDLEWARE_FILE"
        echo "✅ Created Next.js API helpers: $MIDDLEWARE_FILE"
        ;;
    fastapi)
        cat > "$MIDDLEWARE_FILE" << 'EOF'
from fastapi import Depends, HTTPException, Request
from clerk_backend_api import Clerk
import os

clerk = Clerk(bearer_auth=os.getenv("CLERK_SECRET_KEY"))

async def require_auth(request: Request):
    """Require authentication for FastAPI routes"""
    auth_header = request.headers.get("Authorization")

    if not auth_header or not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Unauthorized")

    token = auth_header.replace("Bearer ", "")

    try:
        # Verify JWT token with Clerk
        session = await clerk.verify_session_token(token)
        return session.user_id
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Invalid token: {str(e)}")

# Usage in routes:
# @app.get("/protected")
# async def protected_route(user_id: str = Depends(require_auth)):
#     return {"message": "Protected data", "user_id": user_id}
EOF
        echo "✅ Created FastAPI middleware: $MIDDLEWARE_FILE"
        ;;
esac

# Create or update .env.example
if [ ! -f ".env.example" ]; then
    cat > .env.example << 'EOF'
# Clerk API Keys (replace with your actual keys)
CLERK_PUBLISHABLE_KEY=your_clerk_publishable_key_here
CLERK_SECRET_KEY=your_clerk_secret_key_here

# Optional: Webhook verification
CLERK_WEBHOOK_SECRET=your_webhook_secret_here

# Optional: Custom JWT configuration
CLERK_JWT_KEY=your_jwt_key_here
EOF
    echo "✅ Created .env.example"
else
    echo "ℹ️  .env.example already exists, skipping..."
fi

# Update .gitignore
if [ -f ".gitignore" ]; then
    if ! grep -q "^\.env$" .gitignore; then
        echo "" >> .gitignore
        echo "# Environment variables" >> .gitignore
        echo ".env" >> .gitignore
        echo ".env.local" >> .gitignore
        echo ".env.*.local" >> .gitignore
        echo "✅ Updated .gitignore"
    fi
else
    cat > .gitignore << 'EOF'
# Environment variables
.env
.env.local
.env.*.local

# Dependencies
node_modules/
__pycache__/

# Build outputs
dist/
build/
.next/
EOF
    echo "✅ Created .gitignore"
fi

# Create backend SDK setup file
cp "$TEMPLATE_DIR/backend-sdk-setup.ts" "lib/clerk-backend.ts" 2>/dev/null || true

echo ""
echo "✅ Clerk API authentication setup complete!"
echo ""
echo "📝 Next steps:"
echo "1. Copy .env.example to .env"
echo "2. Add your Clerk API keys to .env"
echo "3. Import and use middleware in your routes:"
echo ""

case $FRAMEWORK in
    express)
        echo "   import { requireAuth } from './middleware/clerk-auth'"
        echo "   app.get('/api/protected', requireAuth, handler)"
        ;;
    fastify)
        echo "   import { requireAuth } from './middleware/clerk-auth'"
        echo "   fastify.get('/api/protected', { preHandler: requireAuth }, handler)"
        ;;
    nextjs)
        echo "   import { withAuth } from '@/lib/clerk-middleware'"
        echo "   export default withAuth(handler)"
        ;;
    fastapi)
        echo "   from middleware.clerk_auth import require_auth"
        echo "   @app.get('/protected')"
        echo "   async def protected_route(user_id: str = Depends(require_auth)):"
        ;;
esac

echo ""
echo "4. Test your protected endpoints"
echo "5. Run: bash scripts/test-api-auth.sh $PROJECT_PATH"
