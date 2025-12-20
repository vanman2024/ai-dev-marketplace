#!/bin/bash

# Setup AgentOps for Google ADK agents
# Usage: ./setup-agentops.sh

set -e

if [ -z "$AGENTOPS_API_KEY" ]; then
  echo "Error: AGENTOPS_API_KEY environment variable not set"
  echo ""
  echo "Get your API key from:"
  echo "  https://app.agentops.ai/settings/projects"
  echo ""
  echo "Then run:"
  echo "  export AGENTOPS_API_KEY=your_api_key_here"
  echo "  $0"
  exit 1
fi

echo "Setting up AgentOps..."

# Install AgentOps
echo "Installing AgentOps package..."
pip install -U agentops

# Test initialization
echo "Testing AgentOps initialization..."
python3 -c "
import agentops
import sys

try:
    agentops.init()
    print('✓ AgentOps initialized successfully!')
except Exception as e:
    print(f'Error initializing AgentOps: {e}', file=sys.stderr)
    sys.exit(1)
"

echo ""
echo "✓ AgentOps setup complete!"
echo ""
echo "Add to your agent code:"
cat <<'EOF'
import agentops

# Initialize AgentOps (before ADK imports)
agentops.init()

# Your ADK agent code
from google.adk.app import App
app = App(root_agent=my_agent)
EOF
echo ""
echo "View sessions at:"
echo "  https://app.agentops.ai/"
