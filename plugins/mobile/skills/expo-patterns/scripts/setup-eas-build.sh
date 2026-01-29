#!/bin/bash
# Configure EAS Build profiles for development, preview, and production
# Usage: ./setup-eas-build.sh

echo "🔧 Setting up EAS Build..."

# Check if eas.json exists
if [ -f "eas.json" ]; then
    echo "⚠️  eas.json already exists, backing up..."
    cp eas.json eas.json.backup
fi

# Copy template
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "$SCRIPT_DIR/../templates/eas.json" ./eas.json

echo "✅ EAS Build configured"
echo "Next steps:"
echo "  eas build --platform ios --profile development"
echo "  eas build --platform android --profile preview"
