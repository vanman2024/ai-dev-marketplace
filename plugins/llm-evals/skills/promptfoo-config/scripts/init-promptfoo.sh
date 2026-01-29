#!/bin/bash
# Initialize promptfoo project
# Usage: ./init-promptfoo.sh

echo "📦 Initializing promptfoo..."

# Install promptfoo
npm install -g promptfoo

# Create directory structure
mkdir -p evals/promptfoo/prompts
mkdir -p evals/promptfoo/outputs

# Copy config template
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "$SCRIPT_DIR/../templates/promptfooconfig.yaml" evals/promptfoo/

echo "✅ promptfoo initialized"
echo "Next: cd evals/promptfoo && npx promptfoo eval"
