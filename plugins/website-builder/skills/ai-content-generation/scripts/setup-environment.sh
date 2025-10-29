#!/bin/bash
# setup-environment.sh
# Configure environment variables and credentials for AI content generation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

echo "=== AI Content Generation - Environment Setup ==="
echo

# Check if .env file exists
ENV_FILE="$PROJECT_ROOT/.env"
ENV_EXAMPLE="$PROJECT_ROOT/.env.example"

if [ ! -f "$ENV_FILE" ]; then
    echo "Creating .env file..."
    if [ -f "$ENV_EXAMPLE" ]; then
        cp "$ENV_EXAMPLE" "$ENV_FILE"
        echo "✓ Copied .env.example to .env"
    else
        touch "$ENV_FILE"
        echo "✓ Created empty .env file"
    fi
fi

# Check for required environment variables
check_env_var() {
    local var_name="$1"
    local description="$2"
    local required="$3"

    if grep -q "^${var_name}=" "$ENV_FILE"; then
        local value=$(grep "^${var_name}=" "$ENV_FILE" | cut -d= -f2)
        if [ -n "$value" ] && [ "$value" != "your-key-here" ] && [ "$value" != "placeholder" ]; then
            echo "✓ $var_name is configured"
            return 0
        fi
    fi

    if [ "$required" = "true" ]; then
        echo "✗ $var_name is missing or not configured"
        echo "  Description: $description"
        echo "  Add to $ENV_FILE: ${var_name}=your-actual-value"
        return 1
    else
        echo "○ $var_name is optional (not configured)"
        return 0
    fi
}

echo "Checking required environment variables..."
echo

# Required variables
REQUIRED_VARS_OK=true
check_env_var "GOOGLE_CLOUD_PROJECT" "Google Cloud project ID for Vertex AI" "true" || REQUIRED_VARS_OK=false
check_env_var "ANTHROPIC_API_KEY" "Anthropic API key for Claude Sonnet content generation" "true" || REQUIRED_VARS_OK=false

echo
echo "Checking optional environment variables..."
echo

# Optional variables
check_env_var "GOOGLE_AI_API_KEY" "Google AI API key for Gemini content generation (alternative to Vertex AI)" "false"

echo
echo "=== Google Cloud Setup ==="
echo

# Check if gcloud is installed
if command -v gcloud &> /dev/null; then
    echo "✓ Google Cloud SDK is installed"

    # Check if authenticated
    if gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | grep -q "@"; then
        echo "✓ Google Cloud authenticated"
        ACTIVE_PROJECT=$(gcloud config get-value project 2>/dev/null)
        if [ -n "$ACTIVE_PROJECT" ]; then
            echo "  Active project: $ACTIVE_PROJECT"
        fi
    else
        echo "✗ Not authenticated with Google Cloud"
        echo "  Run: gcloud auth login"
        echo "  Run: gcloud auth application-default login"
        REQUIRED_VARS_OK=false
    fi
else
    echo "✗ Google Cloud SDK not installed"
    echo "  Install from: https://cloud.google.com/sdk/docs/install"
    echo "  Or use GOOGLE_AI_API_KEY instead for Gemini"
    REQUIRED_VARS_OK=false
fi

echo
echo "=== MCP Configuration ==="
echo

# Check for .mcp.json
MCP_CONFIG="$PROJECT_ROOT/.mcp.json"
if [ -f "$MCP_CONFIG" ]; then
    echo "✓ .mcp.json found"

    # Check if content-image-generation is configured
    if grep -q "content-image-generation" "$MCP_CONFIG"; then
        echo "✓ content-image-generation MCP server is configured"
    else
        echo "✗ content-image-generation MCP server not found in .mcp.json"
        echo "  Run: /website-builder:integrate-content-generation"
        REQUIRED_VARS_OK=false
    fi
else
    echo "✗ .mcp.json not found"
    echo "  Run: /website-builder:integrate-content-generation"
    REQUIRED_VARS_OK=false
fi

echo
echo "=== Summary ==="
echo

if [ "$REQUIRED_VARS_OK" = true ]; then
    echo "✓ Environment setup complete!"
    echo "  Ready to generate AI content and images"
    echo
    echo "Next steps:"
    echo "  1. Test setup: bash scripts/test-generation.sh"
    echo "  2. Generate content: /website-builder:generate-content"
    echo "  3. Generate images: /website-builder:generate-images"
    exit 0
else
    echo "✗ Environment setup incomplete"
    echo "  Please configure missing variables and dependencies"
    echo
    echo "Required actions:"
    echo "  1. Configure environment variables in $ENV_FILE"
    echo "  2. Authenticate with Google Cloud or set GOOGLE_AI_API_KEY"
    echo "  3. Setup MCP server: /website-builder:integrate-content-generation"
    exit 1
fi
