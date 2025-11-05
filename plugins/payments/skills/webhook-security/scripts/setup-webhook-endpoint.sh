#!/bin/bash

# Setup webhook endpoint with signature verification
# Usage: ./setup-webhook-endpoint.sh [provider]
# Provider: stripe, paypal, square

set -e

PROVIDER="${1:-stripe}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

echo "Setting up webhook endpoint for: $PROVIDER"
echo "============================================"

# Create project directory structure
mkdir -p app/webhooks
mkdir -p app/models
mkdir -p app/services
mkdir -p tests/webhooks

# Copy webhook handler template based on provider
echo "Creating webhook handler..."
cp "$SKILL_DIR/templates/webhook_handler.py" "app/webhooks/${PROVIDER}_webhook.py"

# Update provider-specific configuration
sed -i "s/PROVIDER_NAME/${PROVIDER^^}/g" "app/webhooks/${PROVIDER}_webhook.py"

# Copy event logger
echo "Creating event logger..."
cp "$SKILL_DIR/templates/event_logger.py" "app/services/event_logger.py"

# Copy retry handler
echo "Creating retry handler..."
cp "$SKILL_DIR/templates/retry_handler.py" "app/services/retry_handler.py"

# Copy webhook test
echo "Creating webhook tests..."
cp "$SKILL_DIR/templates/webhook_test.py" "tests/webhooks/test_${PROVIDER}_webhook.py"

# Create .env.example if it doesn't exist
if [ ! -f .env.example ]; then
    echo "Creating .env.example..."
    cat > .env.example <<EOF
# ${PROVIDER^^} Configuration
${PROVIDER^^}_API_KEY=${PROVIDER}_test_your_api_key_here
${PROVIDER^^}_WEBHOOK_SECRET=whsec_your_webhook_secret_here

# Database Configuration
DATABASE_URL=postgresql://user:password@localhost:5432/dbname

# Application Configuration
ENVIRONMENT=development
LOG_LEVEL=INFO
EOF
fi

# Add provider-specific configuration to .env.example
if ! grep -q "${PROVIDER^^}_WEBHOOK_SECRET" .env.example; then
    echo "" >> .env.example
    echo "# ${PROVIDER^^} Webhook Configuration" >> .env.example
    echo "${PROVIDER^^}_WEBHOOK_SECRET=whsec_your_webhook_secret_here" >> .env.example
fi

# Create .gitignore if it doesn't exist
if [ ! -f .gitignore ]; then
    echo "Creating .gitignore..."
    cat > .gitignore <<'EOF'
# Environment variables
.env
.env.local
.env.development
.env.staging
.env.production
!.env.example

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
venv/
ENV/
env/

# IDE
.vscode/
.idea/
*.swp
*.swo

# Testing
.pytest_cache/
.coverage
htmlcov/

# Logs
*.log
logs/
EOF
fi

# Create requirements.txt if it doesn't exist
if [ ! -f requirements.txt ]; then
    echo "Creating requirements.txt..."
    cat > requirements.txt <<EOF
# Web Framework
fastapi==0.104.1
uvicorn[standard]==0.24.0
pydantic==2.5.0
pydantic-settings==2.1.0

# Payment Providers
stripe==7.4.0
httpx==0.25.2

# Database
sqlalchemy==2.0.23
psycopg2-binary==2.9.9
alembic==1.13.0

# Utilities
python-dotenv==1.0.0
python-multipart==0.0.6

# Development
pytest==7.4.3
pytest-asyncio==0.21.1
requests==2.31.0
EOF
fi

echo ""
echo "Webhook endpoint setup complete!"
echo "================================"
echo ""
echo "Next steps:"
echo ""
echo "1. Install dependencies:"
echo "   pip install -r requirements.txt"
echo ""
echo "2. Create .env file from template:"
echo "   cp .env.example .env"
echo ""
echo "3. Configure webhook secret:"
case "$PROVIDER" in
    stripe)
        echo "   - Go to: https://dashboard.stripe.com/webhooks"
        echo "   - Create a new endpoint"
        echo "   - URL: https://yourdomain.com/webhooks/stripe"
        echo "   - Select events to listen to"
        echo "   - Copy webhook signing secret to .env"
        ;;
    paypal)
        echo "   - Go to: https://developer.paypal.com/dashboard/applications"
        echo "   - Select your app"
        echo "   - Add webhook URL: https://yourdomain.com/webhooks/paypal"
        echo "   - Select event types"
        echo "   - Copy webhook ID to .env"
        ;;
    square)
        echo "   - Go to: https://developer.squareup.com/apps"
        echo "   - Select your application"
        echo "   - Add webhook URL: https://yourdomain.com/webhooks/square"
        echo "   - Copy signature key to .env"
        ;;
esac
echo ""
echo "4. Set up database:"
echo "   - Create database and tables (see SKILL.md for schema)"
echo "   - Update DATABASE_URL in .env"
echo ""
echo "5. Test locally:"
echo "   ./scripts/test-webhook-locally.sh"
echo ""
echo "6. Run your application:"
echo "   uvicorn app.main:app --reload"
echo ""
echo "Files created:"
echo "  - app/webhooks/${PROVIDER}_webhook.py"
echo "  - app/services/event_logger.py"
echo "  - app/services/retry_handler.py"
echo "  - tests/webhooks/test_${PROVIDER}_webhook.py"
echo "  - .env.example"
echo "  - requirements.txt"
echo ""
