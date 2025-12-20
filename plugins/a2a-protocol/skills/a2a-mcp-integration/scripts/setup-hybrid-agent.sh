#!/bin/bash
# Setup a hybrid agent environment with A2A and MCP

set -e

echo "=== Setting Up Hybrid Agent Environment ==="

# Get agent configuration
read -p "Agent ID (default: hybrid-agent-001): " AGENT_ID
AGENT_ID=${AGENT_ID:-hybrid-agent-001}

read -p "Agent Name (default: Hybrid Agent): " AGENT_NAME
AGENT_NAME=${AGENT_NAME:-"Hybrid Agent"}

read -p "Enable A2A? (yes/no, default: yes): " ENABLE_A2A
ENABLE_A2A=${ENABLE_A2A:-yes}

read -p "Enable MCP? (yes/no, default: yes): " ENABLE_MCP
ENABLE_MCP=${ENABLE_MCP:-yes}

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    echo "Creating .env file..."

    cat > .env << EOF
# Hybrid Agent Configuration
HYBRID_AGENT_ID=$AGENT_ID
HYBRID_AGENT_NAME=$AGENT_NAME
ENABLE_A2A=$ENABLE_A2A
ENABLE_MCP=$ENABLE_MCP

# A2A Protocol Configuration
A2A_API_KEY=your_a2a_key_here
A2A_BASE_URL=https://a2a.example.com
A2A_TIMEOUT=30
A2A_RETRY_ATTEMPTS=3

# MCP Configuration
MCP_SERVER_URL=http://localhost:3000
MCP_TRANSPORT=stdio
MCP_TIMEOUT=15

# Logging
LOG_LEVEL=info
LOG_FORMAT=json
EOF

    echo "✓ Created .env file"
else
    echo "⚠ .env file already exists, skipping creation"
fi

# Create .env.example
cat > .env.example << EOF
# Hybrid Agent Configuration
HYBRID_AGENT_ID=agent-001
HYBRID_AGENT_NAME=Hybrid Agent
ENABLE_A2A=true
ENABLE_MCP=true

# A2A Protocol Configuration
A2A_API_KEY=your_a2a_key_here
A2A_BASE_URL=https://a2a.example.com
A2A_TIMEOUT=30
A2A_RETRY_ATTEMPTS=3

# MCP Configuration
MCP_SERVER_URL=http://localhost:3000
MCP_TRANSPORT=stdio
MCP_TIMEOUT=15

# Logging
LOG_LEVEL=info
LOG_FORMAT=json
EOF

echo "✓ Created .env.example"

# Create agent configuration directory
mkdir -p config

# Create agent card (A2A discovery)
cat > config/agent-card.json << EOF
{
  "id": "$AGENT_ID",
  "name": "$AGENT_NAME",
  "version": "1.0.0",
  "description": "Hybrid agent with A2A and MCP capabilities",
  "capabilities": {
    "a2a": {
      "enabled": $ENABLE_A2A,
      "version": "1.0.0",
      "protocols": ["task_delegation", "coordination"]
    },
    "mcp": {
      "enabled": $ENABLE_MCP,
      "version": "1.0.0",
      "tools": []
    }
  },
  "contact": {
    "endpoint": "http://localhost:8000"
  }
}
EOF

echo "✓ Created agent-card.json"

# Create MCP server configuration
cat > config/mcp-server-config.json << EOF
{
  "server": {
    "name": "hybrid-agent-tools",
    "version": "1.0.0"
  },
  "tools": [],
  "resources": [],
  "prompts": []
}
EOF

echo "✓ Created mcp-server-config.json"

echo ""
echo "=== Setup Complete ==="
echo "Agent ID: $AGENT_ID"
echo "Agent Name: $AGENT_NAME"
echo "A2A Enabled: $ENABLE_A2A"
echo "MCP Enabled: $ENABLE_MCP"
echo ""
echo "Next steps:"
echo "  1. Edit .env and configure your API keys"
echo "  2. Review config/agent-card.json"
echo "  3. Review config/mcp-server-config.json"
echo "  4. Run: ./scripts/validate-python-integration.sh"
echo "  5. Start your hybrid agent"
