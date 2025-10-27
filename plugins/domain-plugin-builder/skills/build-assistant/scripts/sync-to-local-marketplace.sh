#!/usr/bin/env bash
# Script: sync-to-local-marketplace.sh
# Purpose: Automatically sync development directory to installed marketplace
# Usage: ./sync-to-local-marketplace.sh [plugin-name]
# Called by: git pre-commit hook (automatic) or manually

set -euo pipefail

DEV_DIR="/home/vanman2025/Projects/ai-dev-marketplace"
MARKETPLACE_DIR="$HOME/.claude/plugins/marketplaces/ai-dev-marketplace"

# Check if marketplace exists
if [[ ! -d "$MARKETPLACE_DIR" ]]; then
    echo "[INFO] Marketplace not installed at $MARKETPLACE_DIR"
    echo "[INFO] Run: /plugin marketplace add vanman2024/ai-dev-marketplace"
    exit 0  # Not an error - just not installed
fi

# Check if marketplace is a git repo
if [[ ! -d "$MARKETPLACE_DIR/.git" ]]; then
    echo "⚠️  WARNING: Marketplace is not a git repository"
    echo "[INFO] Expected git clone, found regular directory"
    exit 1
fi

cd "$DEV_DIR"

# If plugin name provided, sync only that plugin
if [[ -n "${1:-}" ]]; then
    PLUGIN_NAME="$1"
    echo "[INFO] Syncing plugin: $PLUGIN_NAME"

    if [[ ! -d "plugins/$PLUGIN_NAME" ]]; then
        echo "❌ ERROR: Plugin not found: plugins/$PLUGIN_NAME"
        exit 1
    fi

    # Copy plugin directory
    rsync -av --delete "plugins/$PLUGIN_NAME/" "$MARKETPLACE_DIR/plugins/$PLUGIN_NAME/"
    echo "✅ Synced plugin: $PLUGIN_NAME"
else
    # Sync entire repository
    echo "[INFO] Syncing entire marketplace..."

    # Sync all plugins
    rsync -av --delete plugins/ "$MARKETPLACE_DIR/plugins/"

    # Sync marketplace.json
    rsync -av .claude-plugin/marketplace.json "$MARKETPLACE_DIR/.claude-plugin/marketplace.json"

    # Sync other important files
    rsync -av README.md "$MARKETPLACE_DIR/README.md"

    echo "✅ Synced all plugins and marketplace metadata"
fi

# Show what was synced
cd "$MARKETPLACE_DIR"
git status --short || true

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 LOCAL MARKETPLACE SYNCED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Changes are immediately available to Claude Code!"
echo ""
echo "To sync these changes to GitHub:"
echo "  1. cd $DEV_DIR"
echo "  2. git add -A && git commit -m 'feat: ...'"
echo "  3. git push origin master"
echo ""
echo "To pull GitHub changes to local marketplace:"
echo "  /plugin marketplace update ai-dev-marketplace"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

exit 0
