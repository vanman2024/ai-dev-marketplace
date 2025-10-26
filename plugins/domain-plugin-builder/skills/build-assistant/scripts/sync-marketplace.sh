#!/usr/bin/env bash
# Script: sync-marketplace.sh
# Purpose: Sync all plugins to marketplace.json registry
# Usage: ./sync-marketplace.sh
# This ensures marketplace.json is up-to-date with all plugins

set -euo pipefail

MARKETPLACE_FILE=".claude-plugin/marketplace.json"
BACKUP_FILE=".claude-plugin/marketplace.json.backup"

echo "[INFO] Syncing plugins to marketplace.json"

# Find all plugins with plugin.json
PLUGINS=()
PLUGIN_JSON_FILES=$(find plugins -path "*/.claude-plugin/plugin.json" -type f | sort)

for plugin_json in $PLUGIN_JSON_FILES; do
    PLUGIN_DIR=$(dirname "$(dirname "$plugin_json")")
    PLUGIN_NAME=$(basename "$PLUGIN_DIR")

    # Read plugin.json data
    DESCRIPTION=$(python3 -c "import json; print(json.load(open('$plugin_json'))['description'])" 2>/dev/null || echo "No description")
    VERSION=$(python3 -c "import json; print(json.load(open('$plugin_json'))['version'])" 2>/dev/null || echo "1.0.0")

    # Extract author if exists
    AUTHOR_NAME=$(python3 -c "import json; d=json.load(open('$plugin_json')); print(d.get('author', {}).get('name', 'vanman2024'))" 2>/dev/null || echo "vanman2024")
    AUTHOR_EMAIL=$(python3 -c "import json; d=json.load(open('$plugin_json')); print(d.get('author', {}).get('email', 'noreply@ai-dev-marketplace.dev'))" 2>/dev/null || echo "noreply@ai-dev-marketplace.dev")

    # Extract keywords if exists
    KEYWORDS=$(python3 -c "import json; d=json.load(open('$plugin_json')); print(','.join(['\"' + k + '\"' for k in d.get('keywords', [])]))" 2>/dev/null || echo "")

    # Build plugin entry
    PLUGIN_ENTRY=$(cat <<EOF
    {
      "name": "$PLUGIN_NAME",
      "description": "$DESCRIPTION",
      "version": "$VERSION",
      "author": {
        "name": "$AUTHOR_NAME",
        "email": "$AUTHOR_EMAIL"
      },
      "source": "./plugins/$PLUGIN_NAME",
      "category": "development",
      "keywords": [$KEYWORDS]
    }
EOF
)

    PLUGINS+=("$PLUGIN_ENTRY")
done

# Build marketplace.json
PLUGIN_COUNT=${#PLUGINS[@]}
PLUGINS_JSON=""

for i in "${!PLUGINS[@]}"; do
    PLUGINS_JSON+="${PLUGINS[$i]}"
    if [[ $i -lt $((PLUGIN_COUNT - 1)) ]]; then
        PLUGINS_JSON+=","
    fi
done

# Write marketplace.json
cat > "$MARKETPLACE_FILE" <<EOF
{
  "name": "ai-dev-marketplace",
  "version": "1.0.0",
  "description": "AI Development Marketplace - Master repository for tech-specific plugins (SDKs, frameworks, platforms)",
  "owner": {
    "name": "AI Development Team",
    "email": "noreply@ai-dev-marketplace.dev"
  },
  "plugins": [
$PLUGINS_JSON
  ]
}
EOF

# Format JSON
python3 -m json.tool "$MARKETPLACE_FILE" > "${MARKETPLACE_FILE}.tmp" && mv "${MARKETPLACE_FILE}.tmp" "$MARKETPLACE_FILE"

echo "✅ Updated marketplace.json with $PLUGIN_COUNT plugins"

# Show summary
echo ""
echo "Registered plugins in marketplace:"
for plugin_json in $PLUGIN_JSON_FILES; do
    PLUGIN_DIR=$(dirname "$(dirname "$plugin_json")")
    PLUGIN_NAME=$(basename "$PLUGIN_DIR")
    VERSION=$(python3 -c "import json; print(json.load(open('$plugin_json'))['version'])" 2>/dev/null || echo "1.0.0")
    echo "  - $PLUGIN_NAME (v$VERSION)"
done
