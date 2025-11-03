#!/usr/bin/env bash

# Register plugin skills in ~/.claude/settings.json
# Usage: ./register-skills-in-settings.sh <plugin-name>

set -e

PLUGIN_NAME=$1
SETTINGS_FILE="$HOME/.claude/settings.json"

if [ -z "$PLUGIN_NAME" ]; then
    echo "Usage: $0 <plugin-name>"
    echo "Example: $0 domain-plugin-builder"
    exit 1
fi

if [ ! -d "plugins/$PLUGIN_NAME" ]; then
    echo "ERROR: Plugin directory plugins/$PLUGIN_NAME does not exist"
    exit 1
fi

if [ ! -f "$SETTINGS_FILE" ]; then
    echo "ERROR: Settings file $SETTINGS_FILE does not exist"
    exit 1
fi

echo "[INFO] Registering skills for plugin: $PLUGIN_NAME"

# Get list of skills (directories in skills/)
SKILL_DIRS=$(find plugins/$PLUGIN_NAME/skills -maxdepth 1 -mindepth 1 -type d 2>/dev/null || true)

if [ -z "$SKILL_DIRS" ]; then
    echo "[WARN] No skills found for plugin $PLUGIN_NAME"
    exit 0
fi

echo "[INFO] Found skills:"
for SKILL_DIR in $SKILL_DIRS; do
    SKILL_NAME=$(basename "$SKILL_DIR")
    echo "  - $SKILL_NAME"
done

# Check each skill and add if not already registered
for SKILL_DIR in $SKILL_DIRS; do
    SKILL_NAME=$(basename "$SKILL_DIR")
    SKILL_ENTRY="Skill($PLUGIN_NAME:$SKILL_NAME)"

    # Check if this skill is already registered
    if grep -q "\"$SKILL_ENTRY\"" "$SETTINGS_FILE"; then
        echo "[INFO] Skill already registered: $SKILL_NAME"
        continue
    fi

    echo "[INFO] Adding skill to settings.json: $SKILL_NAME"

    # Find the last Skill() entry and add after it
    # Use Python for JSON manipulation to ensure valid JSON
    python3 << EOF
import json

with open('$SETTINGS_FILE', 'r') as f:
    settings = json.load(f)

# Add skill to permissions.allow
if 'permissions' not in settings:
    settings['permissions'] = {}
if 'allow' not in settings['permissions']:
    settings['permissions']['allow'] = []

skill_entry = '$SKILL_ENTRY'
if skill_entry not in settings['permissions']['allow']:
    # Find position after last Skill() entry
    last_skill_index = -1
    for i, entry in enumerate(settings['permissions']['allow']):
        if isinstance(entry, str) and entry.startswith('Skill('):
            last_skill_index = i

    if last_skill_index >= 0:
        # Insert after last skill
        settings['permissions']['allow'].insert(last_skill_index + 1, skill_entry)
    else:
        # No skills yet, add at end
        settings['permissions']['allow'].append(skill_entry)

    with open('$SETTINGS_FILE', 'w') as f:
        json.dump(settings, f, indent=2)

    print(f"[SUCCESS] Added {skill_entry} to settings.json")
else:
    print(f"[INFO] Skill already registered: {skill_entry}")
EOF

done

echo "[SUCCESS] Skill registration complete for plugin: $PLUGIN_NAME"
