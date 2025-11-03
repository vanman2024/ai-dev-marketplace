#!/usr/bin/env bash
# Script: validate-agent.sh
# Purpose: Validate agent file compliance with framework standards
# Subsystem: build-system
# Called by: /build:agent command after generation
# Outputs: Validation report to stdout

set -euo pipefail

AGENT_FILE="${1:?Usage: $0 <agent-file>}"

echo "[INFO] Validating agent file: $AGENT_FILE"

# Check file exists
if [[ ! -f "$AGENT_FILE" ]]; then
    echo "❌ ERROR: File not found: $AGENT_FILE"
    exit 1
fi

# Check frontmatter exists
if ! grep -q "^---$" "$AGENT_FILE"; then
    echo "❌ ERROR: Missing frontmatter"
    exit 1
fi

# Check required frontmatter fields
REQUIRED_FIELDS=("name:" "description:" "tools:" "model:")
for field in "${REQUIRED_FIELDS[@]}"; do
    if ! grep -q "^$field" "$AGENT_FILE"; then
        echo "❌ ERROR: Missing required field: $field"
        exit 1
    fi
done

# Check Step 0 exists (optional - only for validator agents)
if ! grep -q "### Step 0: Load Required Context" "$AGENT_FILE"; then
    echo "⚠️  WARNING: Missing Step 0: Load Required Context section (only required for validator agents)"
fi

# Check for @ symbol references
if ! grep -q 'Read("' "$AGENT_FILE"; then
    echo "⚠️  WARNING: No Read() calls found - agent may not load context"
fi

# Check Success Criteria exists (optional - only for validator agents)
if ! grep -q "## Success Criteria" "$AGENT_FILE"; then
    echo "⚠️  WARNING: Missing Success Criteria section (only required for validator agents)"
fi

echo "✅ Agent validation passed"
exit 0
