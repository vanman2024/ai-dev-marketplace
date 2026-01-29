#!/bin/bash
# Initialize DeepEval project
# Usage: ./init-deepeval.sh

echo "📦 Initializing DeepEval..."

# Install deepeval
pip install deepeval pytest

# Create directory structure
mkdir -p evals/deepeval

# Copy templates
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "$SCRIPT_DIR/../templates/conftest.py" evals/deepeval/
cp "$SCRIPT_DIR/../templates/test_basic.py" evals/deepeval/

echo "✅ DeepEval initialized"
echo "Next: pytest evals/deepeval/ -v"
