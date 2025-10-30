#!/usr/bin/env bash
# setup-auth.sh - Configure ELEVENLABS_API_KEY in .env file
set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(pwd)"

echo "ElevenLabs API Authentication Setup"
echo "===================================="
echo ""

# Check if API key provided as argument
API_KEY="${1:-}"

if [[ -z "$API_KEY" ]]; then
    echo "Enter your ElevenLabs API key:"
    echo "(Get it from: https://elevenlabs.io/app/settings/api-keys)"
    read -r API_KEY
fi

# Validate API key format (basic check)
if [[ ! "$API_KEY" =~ ^sk_ ]]; then
    echo -e "${YELLOW}Warning: API key doesn't start with 'sk_' - this may not be a valid ElevenLabs API key${NC}"
    echo "Continue anyway? (y/n)"
    read -r continue
    if [[ ! "$continue" =~ ^[Yy]$ ]]; then
        echo "Setup cancelled."
        exit 1
    fi
fi

# Check if .env file exists
ENV_FILE="$PROJECT_ROOT/.env"
if [[ -f "$ENV_FILE" ]]; then
    echo -e "${YELLOW}.env file already exists${NC}"

    # Check if ELEVENLABS_API_KEY already exists
    if grep -q "^ELEVENLABS_API_KEY=" "$ENV_FILE"; then
        echo "ELEVENLABS_API_KEY already configured."
        echo "Update it? (y/n)"
        read -r update
        if [[ "$update" =~ ^[Yy]$ ]]; then
            # Update existing key
            if [[ "$OSTYPE" == "darwin"* ]]; then
                # macOS
                sed -i '' "s|^ELEVENLABS_API_KEY=.*|ELEVENLABS_API_KEY=$API_KEY|" "$ENV_FILE"
            else
                # Linux
                sed -i "s|^ELEVENLABS_API_KEY=.*|ELEVENLABS_API_KEY=$API_KEY|" "$ENV_FILE"
            fi
            echo -e "${GREEN}API key updated in .env file${NC}"
        else
            echo "Keeping existing API key."
        fi
    else
        # Append new key
        echo "" >> "$ENV_FILE"
        echo "# ElevenLabs API Configuration" >> "$ENV_FILE"
        echo "ELEVENLABS_API_KEY=$API_KEY" >> "$ENV_FILE"
        echo -e "${GREEN}API key added to .env file${NC}"
    fi
else
    # Create new .env file
    cat > "$ENV_FILE" << EOF
# ElevenLabs API Configuration
# Get your API key from: https://elevenlabs.io/app/settings/api-keys
ELEVENLABS_API_KEY=$API_KEY

# Optional: Configure voice settings
# ELEVENLABS_DEFAULT_VOICE_ID=21m00Tcm4TlvDq8ikWAM
# ELEVENLABS_DEFAULT_MODEL_ID=eleven_monolingual_v1
EOF
    echo -e "${GREEN}Created .env file with API key${NC}"
fi

# Ensure .env is in .gitignore
GITIGNORE_FILE="$PROJECT_ROOT/.gitignore"
if [[ -f "$GITIGNORE_FILE" ]]; then
    if ! grep -q "^\.env$" "$GITIGNORE_FILE"; then
        echo "" >> "$GITIGNORE_FILE"
        echo "# Environment variables" >> "$GITIGNORE_FILE"
        echo ".env" >> "$GITIGNORE_FILE"
        echo ".env.local" >> "$GITIGNORE_FILE"
        echo ".env.*.local" >> "$GITIGNORE_FILE"
        echo -e "${GREEN}Added .env to .gitignore${NC}"
    fi
else
    cat > "$GITIGNORE_FILE" << EOF
# Environment variables
.env
.env.local
.env.*.local
EOF
    echo -e "${GREEN}Created .gitignore with .env${NC}"
fi

echo ""
echo "Setup complete!"
echo ""
echo "Next steps:"
echo "1. Test connection: bash scripts/test-connection.sh"
echo "2. Install SDK: bash scripts/install-sdk.sh [typescript|python]"
echo "3. Generate client: bash scripts/generate-client.sh [typescript|python] [output-path]"
echo ""
echo -e "${YELLOW}Security reminder: Never commit your .env file to version control!${NC}"
