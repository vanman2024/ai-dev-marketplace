#!/bin/bash
#
# Setup Cohere Embeddings
#
# Sets up Cohere embedding client with API credentials.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"

echo "=================================================="
echo "Cohere Embeddings Setup"
echo "=================================================="

# Check for Python
if ! command -v python3 &> /dev/null; then
    echo "Error: python3 is required but not installed."
    exit 1
fi

# Install Cohere library
echo ""
echo "Installing Cohere Python library..."
pip3 install --quiet cohere

# Check for API key
if [ -z "$COHERE_API_KEY" ]; then
    echo ""
    echo "Warning: COHERE_API_KEY environment variable not set."
    echo ""
    echo "Get your API key from: https://dashboard.cohere.com/api-keys"
    echo ""
    echo "Set it with:"
    echo "  export COHERE_API_KEY='your-api-key'"
    echo ""
    echo "Or add to your .env file:"
    echo "  COHERE_API_KEY=your-api-key"
    echo ""
    read -p "Enter your Cohere API key (or press Enter to skip): " api_key
    if [ -n "$api_key" ]; then
        export COHERE_API_KEY="$api_key"
        echo "API key set for this session."
    fi
fi

# Test connection
if [ -n "$COHERE_API_KEY" ]; then
    echo ""
    echo "Testing Cohere API connection..."
    python3 << 'EOF'
import cohere
import sys
import os

try:
    client = cohere.Client(os.environ.get('COHERE_API_KEY'))
    response = client.embed(
        texts=["Hello, world!"],
        model="embed-english-v3.0",
        input_type="search_document"
    )
    print(f"✓ Successfully connected to Cohere API")
    print(f"✓ Generated {len(response.embeddings[0])} dimensional embedding")
except Exception as e:
    print(f"✗ Error connecting to Cohere API: {e}", file=sys.stderr)
    sys.exit(1)
EOF
fi

echo ""
echo "=================================================="
echo "Cohere Embeddings Setup Complete"
echo "=================================================="
echo ""
echo "Available models:"
echo "  - embed-english-v3.0 (1024 dims, English)"
echo "  - embed-english-light-v3.0 (384 dims, lightweight)"
echo "  - embed-multilingual-v3.0 (1024 dims, 100+ languages)"
echo ""
echo "Input types:"
echo "  - search_document: For embedding documents"
echo "  - search_query: For embedding search queries"
echo "  - classification: For classification tasks"
echo "  - clustering: For clustering tasks"
echo ""
echo "Cost calculator:"
echo "  python scripts/calculate-embedding-costs.py --model embed-english-v3.0 --documents 10000 --avg-tokens 500"
echo ""
