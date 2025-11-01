#!/bin/bash
#
# Setup OpenAI Embeddings
#
# Configures OpenAI embedding client with API key management and retry logic.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"

echo "=================================================="
echo "OpenAI Embeddings Setup"
echo "=================================================="

# Check for Python
if ! command -v python3 &> /dev/null; then
    echo "Error: python3 is required but not installed."
    exit 1
fi

# Install OpenAI library
echo ""
echo "Installing OpenAI Python library..."
pip3 install --quiet openai tiktoken

# Check for API key
if [ -z "$OPENAI_API_KEY" ]; then
    echo ""
    echo "Warning: OPENAI_API_KEY environment variable not set."
    echo ""
    echo "Set it with:"
    echo "  export OPENAI_API_KEY='your-api-key'"
    echo ""
    echo "Or add to your .env file:"
    echo "  OPENAI_API_KEY=your-api-key"
    echo ""
    read -p "Enter your OpenAI API key (or press Enter to skip): " api_key
    if [ -n "$api_key" ]; then
        export OPENAI_API_KEY="$api_key"
        echo "API key set for this session."
    fi
fi

# Test connection
if [ -n "$OPENAI_API_KEY" ]; then
    echo ""
    echo "Testing OpenAI API connection..."
    python3 << 'EOF'
from openai import OpenAI
import sys

try:
    client = OpenAI()
    response = client.embeddings.create(
        model="text-embedding-3-small",
        input=["Hello, world!"]
    )
    print(f"✓ Successfully connected to OpenAI API")
    print(f"✓ Generated {len(response.data[0].embedding)} dimensional embedding")
except Exception as e:
    print(f"✗ Error connecting to OpenAI API: {e}", file=sys.stderr)
    sys.exit(1)
EOF
fi

echo ""
echo "=================================================="
echo "OpenAI Embeddings Setup Complete"
echo "=================================================="
echo ""
echo "Available models:"
echo "  - text-embedding-3-small (1536 dims, $0.02/1M tokens)"
echo "  - text-embedding-3-large (3072 dims, $0.13/1M tokens)"
echo "  - text-embedding-ada-002 (1536 dims, $0.10/1M tokens)"
echo ""
echo "Configuration template:"
echo "  templates/openai-embedding-config.py"
echo ""
echo "Cost calculator:"
echo "  python scripts/calculate-embedding-costs.py --model text-embedding-3-small --documents 10000 --avg-tokens 500"
echo ""
