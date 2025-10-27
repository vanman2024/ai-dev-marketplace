#!/usr/bin/env bash
# Script: install-plugin-locally.sh
# Purpose: Install plugin to local Claude marketplace for testing
# Usage: ./install-plugin-locally.sh <plugin-directory>

set -euo pipefail

PLUGIN_DIR="${1:?Usage: $0 <plugin-directory>}"
MARKETPLACE_DIR="$HOME/.claude/plugins/marketplaces/ai-dev-marketplace"

echo "[INFO] Installing plugin to local marketplace"

# Check plugin directory exists
if [[ ! -d "$PLUGIN_DIR" ]]; then
    echo "❌ ERROR: Plugin directory not found: $PLUGIN_DIR"
    exit 1
fi

# Get plugin name
PLUGIN_NAME=$(basename "$PLUGIN_DIR")

# Check if marketplace exists
if [[ ! -d "$MARKETPLACE_DIR" ]]; then
    echo "❌ ERROR: Marketplace not found at $MARKETPLACE_DIR"
    echo "[INFO] Run: /plugin marketplace add ai-dev-marketplace"
    exit 1
fi

# Check if we're in the development directory
DEV_MARKETPLACE="/home/vanman2025/Projects/ai-dev-marketplace"
CURRENT_DIR=$(pwd)
if [[ "$CURRENT_DIR" == "$DEV_MARKETPLACE" ]]; then
    echo "[INFO] Running from development directory"
else
    echo "⚠️  WARNING: Not in development directory"
    echo "[INFO] Expected: $DEV_MARKETPLACE"
    echo "[INFO] Current:  $CURRENT_DIR"
fi

# Copy plugin to marketplace
echo "[INFO] Copying plugin to marketplace..."
cp -r "$PLUGIN_DIR" "$MARKETPLACE_DIR/plugins/"

# Update marketplace.json
echo "[INFO] Updating marketplace.json..."
cp .claude-plugin/marketplace.json "$MARKETPLACE_DIR/.claude-plugin/marketplace.json"

echo "✅ Plugin installed to local marketplace"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 NEXT STEP: Install Plugin"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  /plugin install $PLUGIN_NAME@ai-dev-marketplace"
echo ""
echo "  Verify: /$PLUGIN_NAME:init  (or any command from the plugin)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
exit 0
