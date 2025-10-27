#!/bin/bash
# Start CATS MCP Server
# Usage: ./start.sh

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting CATS MCP Server...${NC}"

# Check if .env exists
if [ ! -f .env ]; then
    echo -e "${YELLOW}Warning: .env file not found!${NC}"
    echo "Please create .env from .env.example and configure your API keys"
    echo ""
    echo "  cp .env.example .env"
    echo "  nano .env  # Edit with your API keys"
    echo ""
    exit 1
fi

# Activate virtual environment
if [ ! -d .venv ]; then
    echo -e "${YELLOW}Virtual environment not found. Creating...${NC}"
    python -m venv .venv
    source .venv/bin/activate
    pip install -r requirements.txt
else
    source .venv/bin/activate
fi

# Start server
echo -e "${GREEN}Server starting on http://localhost:8000${NC}"
echo "Press Ctrl+C to stop"
echo ""

python server.py
