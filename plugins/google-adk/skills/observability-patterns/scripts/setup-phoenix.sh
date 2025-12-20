#!/bin/bash

# Setup Phoenix (Arize) for Google ADK agents
# Usage: ./setup-phoenix.sh

set -e

if [ -z "$PHOENIX_API_KEY" ] || [ -z "$PHOENIX_COLLECTOR_ENDPOINT" ]; then
  echo "Error: Required environment variables not set"
  echo ""
  echo "Get your credentials from:"
  echo "  https://phoenix.arize.com/"
  echo ""
  echo "Then run:"
  echo "  export PHOENIX_API_KEY=your_api_key_here"
  echo "  export PHOENIX_COLLECTOR_ENDPOINT=https://app.phoenix.arize.com/s/your-space"
  echo "  $0"
  exit 1
fi

echo "Setting up Phoenix..."

# Install Phoenix packages
echo "Installing Phoenix packages..."
pip install openinference-instrumentation-google-adk google-adk arize-phoenix-otel

# Test connection
echo "Testing Phoenix connection..."
python3 -c "
import os
from phoenix.otel import register
import sys

try:
    tracer_provider = register(
        project_name='test-project',
        auto_instrument=True
    )
    print('✓ Phoenix tracer initialized successfully!')
except Exception as e:
    print(f'Error initializing Phoenix: {e}', file=sys.stderr)
    sys.exit(1)
"

echo ""
echo "✓ Phoenix setup complete!"
echo ""
echo "Add to your agent code:"
cat <<'EOF'
import os
from phoenix.otel import register

# Set Phoenix credentials
os.environ["PHOENIX_API_KEY"] = "your_api_key_here"
os.environ["PHOENIX_COLLECTOR_ENDPOINT"] = "https://app.phoenix.arize.com/s/your-space"

# Register Phoenix tracer
tracer_provider = register(
    project_name="my-adk-agent",
    auto_instrument=True
)

# Your ADK agent code
from google.adk.app import App
app = App(root_agent=my_agent)
EOF
echo ""
echo "View traces at:"
echo "  $PHOENIX_COLLECTOR_ENDPOINT"
