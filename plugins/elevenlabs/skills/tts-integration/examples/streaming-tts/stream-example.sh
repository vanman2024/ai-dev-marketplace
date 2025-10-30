#!/usr/bin/env bash
# Streaming TTS example using WebSocket
# Simple bash wrapper for streaming demonstration

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_color() {
    echo -e "${1}${2}${NC}"
}

# Check if Node.js client exists
if [[ ! -f "client-example.js" ]]; then
    print_color "$RED" "Error: client-example.js not found"
    echo "Make sure you're in the streaming-tts example directory"
    exit 1
fi

# Check Node.js
if ! command -v node &> /dev/null; then
    print_color "$RED" "Error: Node.js is required for streaming"
    echo "Install Node.js from: https://nodejs.org/"
    exit 1
fi

# Check ws module
if ! node -e "require('ws')" 2>/dev/null; then
    print_color "$YELLOW" "Installing WebSocket module..."
    npm install ws
fi

# Run the client
print_color "$BLUE" "Starting streaming TTS..."
node client-example.js "$@"
