#!/bin/bash

# Setup LlamaParse for AI-powered document parsing
# Usage: ./setup-llamaparse.sh [--api-key YOUR_KEY]

set -e

echo "Setting up LlamaParse..."

# Check Python version
python_version=$(python3 --version 2>&1 | awk '{print $2}' | cut -d. -f1,2)
if (( $(echo "$python_version < 3.8" | bc -l) )); then
    echo "Error: Python 3.8 or higher required"
    exit 1
fi

# Install llama-parse
echo "Installing llama-parse package..."
pip install llama-parse llama-index-core

# Parse command line arguments
API_KEY=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --api-key)
            API_KEY="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--api-key YOUR_KEY]"
            exit 1
            ;;
    esac
done

# Check for API key
if [ -z "$API_KEY" ]; then
    if [ -n "$LLAMA_CLOUD_API_KEY" ]; then
        echo "Using LLAMA_CLOUD_API_KEY from environment"
        API_KEY="$LLAMA_CLOUD_API_KEY"
    else
        echo ""
        echo "LlamaParse requires an API key from https://cloud.llamaindex.ai"
        echo ""
        echo "Please provide API key via:"
        echo "  1. Command line: ./setup-llamaparse.sh --api-key YOUR_KEY"
        echo "  2. Environment variable: export LLAMA_CLOUD_API_KEY=YOUR_KEY"
        echo "  3. .env file: Add LLAMA_CLOUD_API_KEY=YOUR_KEY"
        echo ""
        read -p "Enter API key (or press Enter to skip): " API_KEY
    fi
fi

# Create .env file if API key provided
if [ -n "$API_KEY" ]; then
    if [ ! -f .env ]; then
        touch .env
    fi

    # Check if key already exists in .env
    if grep -q "LLAMA_CLOUD_API_KEY" .env; then
        # Update existing key
        sed -i "s/LLAMA_CLOUD_API_KEY=.*/LLAMA_CLOUD_API_KEY=$API_KEY/" .env
        echo "Updated LLAMA_CLOUD_API_KEY in .env"
    else
        # Add new key
        echo "LLAMA_CLOUD_API_KEY=$API_KEY" >> .env
        echo "Added LLAMA_CLOUD_API_KEY to .env"
    fi
fi

# Create test script
cat > test_llamaparse.py <<'EOF'
#!/usr/bin/env python3
"""Test LlamaParse installation"""

import os
import sys

try:
    from llama_parse import LlamaParse
    print("✓ LlamaParse imported successfully")
except ImportError as e:
    print(f"✗ Failed to import LlamaParse: {e}")
    sys.exit(1)

# Check for API key
api_key = os.getenv("LLAMA_CLOUD_API_KEY")
if not api_key:
    print("✗ LLAMA_CLOUD_API_KEY not found in environment")
    print("  Set it with: export LLAMA_CLOUD_API_KEY=your_key")
    sys.exit(1)

print(f"✓ API key found: {api_key[:10]}...")

# Test parser initialization
try:
    parser = LlamaParse(
        api_key=api_key,
        result_type="text",
        verbose=False
    )
    print("✓ LlamaParse initialized successfully")
    print("\nLlamaParse is ready to use!")
    print("\nExample usage:")
    print("  from llama_parse import LlamaParse")
    print("  parser = LlamaParse(api_key=os.getenv('LLAMA_CLOUD_API_KEY'))")
    print("  documents = parser.load_data('document.pdf')")
except Exception as e:
    print(f"✗ Failed to initialize parser: {e}")
    sys.exit(1)
EOF

chmod +x test_llamaparse.py

# Run test
echo ""
echo "Testing installation..."
if [ -n "$API_KEY" ]; then
    export LLAMA_CLOUD_API_KEY="$API_KEY"
fi
python3 test_llamaparse.py

echo ""
echo "Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Use parse-pdf.py with --backend llamaparse"
echo "  2. See templates/multi-format-parser.py for integration"
echo "  3. Check examples/ for usage patterns"
