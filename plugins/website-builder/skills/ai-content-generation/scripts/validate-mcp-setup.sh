#!/bin/bash
# validate-mcp-setup.sh
# Verify MCP server connection and available tools

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

echo "=== AI Content Generation - MCP Validation ==="
echo

# Check for .mcp.json
MCP_CONFIG="$PROJECT_ROOT/.mcp.json"

if [ ! -f "$MCP_CONFIG" ]; then
    echo "✗ .mcp.json not found at $PROJECT_ROOT"
    echo
    echo "Setup required:"
    echo "  Run: /website-builder:integrate-content-generation"
    exit 1
fi

echo "✓ Found .mcp.json"
echo

# Validate JSON syntax
if command -v jq &> /dev/null; then
    if jq empty "$MCP_CONFIG" 2>/dev/null; then
        echo "✓ .mcp.json has valid JSON syntax"
    else
        echo "✗ .mcp.json has invalid JSON syntax"
        exit 1
    fi
else
    echo "○ jq not installed, skipping JSON validation"
    echo "  Install jq for better validation: apt install jq"
fi

echo

# Check for content-image-generation server configuration
if grep -q "content-image-generation" "$MCP_CONFIG"; then
    echo "✓ content-image-generation MCP server found"
    echo
    echo "Expected MCP tools:"
    echo "  • generate_image_imagen3 - Image generation with Imagen 3/4"
    echo "  • batch_generate_images - Batch image generation"
    echo "  • generate_video_veo3 - Video generation with Veo 2/3"
    echo "  • generate_marketing_content - Content generation with Claude/Gemini"
    echo "  • calculate_cost_estimate - Cost estimation utility"
    echo "  • image_prompt_enhancer - Prompt enhancement utility"
else
    echo "✗ content-image-generation MCP server not configured"
    echo
    echo "Setup required:"
    echo "  Run: /website-builder:integrate-content-generation"
    exit 1
fi

echo
echo "=== Environment Variables Check ==="
echo

# Check environment variables
check_env() {
    local var_name="$1"
    if [ -n "${!var_name}" ]; then
        echo "✓ $var_name is set"
        return 0
    else
        echo "✗ $var_name is not set"
        return 1
    fi
}

ENV_OK=true
check_env "GOOGLE_CLOUD_PROJECT" || ENV_OK=false
check_env "ANTHROPIC_API_KEY" || ENV_OK=false

if [ -n "$GOOGLE_AI_API_KEY" ]; then
    echo "✓ GOOGLE_AI_API_KEY is set (optional, enables Gemini)"
else
    echo "○ GOOGLE_AI_API_KEY not set (optional)"
fi

echo
echo "=== Google Cloud Vertex AI Check ==="
echo

# Check Google Cloud authentication
if command -v gcloud &> /dev/null; then
    if gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | grep -q "@"; then
        echo "✓ Google Cloud authenticated"

        # Check if Vertex AI API is enabled
        ACTIVE_PROJECT=$(gcloud config get-value project 2>/dev/null)
        if [ -n "$ACTIVE_PROJECT" ]; then
            echo "  Project: $ACTIVE_PROJECT"

            # Try to check if Vertex AI API is enabled (requires gcloud services)
            if gcloud services list --enabled --filter="name:aiplatform.googleapis.com" --format="value(name)" 2>/dev/null | grep -q "aiplatform"; then
                echo "✓ Vertex AI API is enabled"
            else
                echo "⚠ Could not verify Vertex AI API status"
                echo "  Enable with: gcloud services enable aiplatform.googleapis.com"
            fi
        fi
    else
        echo "✗ Not authenticated with Google Cloud"
        echo "  Run: gcloud auth application-default login"
        ENV_OK=false
    fi
else
    echo "✗ gcloud CLI not found"
    echo "  Install from: https://cloud.google.com/sdk/docs/install"
    ENV_OK=false
fi

echo
echo "=== Summary ==="
echo

if [ "$ENV_OK" = true ]; then
    echo "✓ MCP setup is valid and ready to use"
    echo
    echo "Available operations:"
    echo "  • Image generation (Imagen 3/4)"
    echo "  • Video generation (Veo 2/3)"
    echo "  • Content generation (Claude Sonnet 4, Gemini 2.0)"
    echo "  • Batch operations"
    echo "  • Cost estimation"
    echo
    echo "Next steps:"
    echo "  1. Test generation: bash scripts/test-generation.sh"
    echo "  2. Generate content: /website-builder:generate-content"
    echo "  3. Generate images: /website-builder:generate-images"
    exit 0
else
    echo "✗ MCP setup has issues"
    echo
    echo "Required actions:"
    echo "  1. Set missing environment variables"
    echo "  2. Authenticate with Google Cloud"
    echo "  3. Enable required APIs"
    echo
    echo "For help, run: bash scripts/setup-environment.sh"
    exit 1
fi
