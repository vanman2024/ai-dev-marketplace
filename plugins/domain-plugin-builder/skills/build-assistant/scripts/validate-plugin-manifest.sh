#!/usr/bin/env bash

# Validate and fix plugin.json manifest
# Usage: ./validate-plugin-manifest.sh <plugin-name> [--fix]

set -e

PLUGIN_NAME=$1
FIX_MODE=false

if [ "$2" = "--fix" ]; then
    FIX_MODE=true
fi

if [ -z "$PLUGIN_NAME" ]; then
    echo "Usage: $0 <plugin-name> [--fix]"
    echo "Example: $0 elevenlabs --fix"
    exit 1
fi

MANIFEST_FILE="plugins/$PLUGIN_NAME/.claude-plugin/plugin.json"

if [ ! -f "$MANIFEST_FILE" ]; then
    echo "ERROR: Manifest file not found: $MANIFEST_FILE"
    exit 1
fi

echo "[INFO] Validating plugin manifest: $MANIFEST_FILE"

# Test 1: Valid JSON syntax
if ! python3 -m json.tool "$MANIFEST_FILE" > /dev/null 2>&1; then
    echo "❌ FAIL: Invalid JSON syntax"
    exit 1
fi
echo "✅ PASS: Valid JSON syntax"

# Test 2: Required fields
REQUIRED_FIELDS=("name" "version" "description" "author")
MISSING_FIELDS=()

for field in "${REQUIRED_FIELDS[@]}"; do
    if ! grep -q "\"$field\"" "$MANIFEST_FILE"; then
        MISSING_FIELDS+=("$field")
    fi
done

if [ ${#MISSING_FIELDS[@]} -gt 0 ]; then
    echo "❌ FAIL: Missing required fields: ${MISSING_FIELDS[*]}"
    exit 1
fi
echo "✅ PASS: All required fields present"

# Test 3: Repository field format (should be string, not object)
if grep -q '"repository".*{' "$MANIFEST_FILE"; then
    echo "❌ FAIL: repository field is an object (should be string)"

    if [ "$FIX_MODE" = true ]; then
        echo "[INFO] Fixing repository field..."

        # Extract URL from repository object
        REPO_URL=$(grep -A2 '"repository"' "$MANIFEST_FILE" | grep '"url"' | sed 's/.*"url": "\(.*\)".*/\1/')

        if [ -n "$REPO_URL" ]; then
            # Create temp file with fixed repository
            python3 << EOF
import json
with open("$MANIFEST_FILE", "r") as f:
    data = json.load(f)
if isinstance(data.get("repository"), dict):
    data["repository"] = data["repository"].get("url", "")
with open("$MANIFEST_FILE", "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
EOF
            echo "✅ FIXED: repository changed to string: $REPO_URL"
        else
            echo "❌ Could not extract repository URL"
            exit 1
        fi
    else
        echo "[HINT] Run with --fix to automatically correct this"
        exit 1
    fi
else
    echo "✅ PASS: repository field is correct format"
fi

# Test 4: Category field (should NOT exist)
if grep -q '"category"' "$MANIFEST_FILE"; then
    echo "❌ FAIL: 'category' field found (not a valid field)"

    if [ "$FIX_MODE" = true ]; then
        echo "[INFO] Removing category field..."
        python3 << EOF
import json
with open("$MANIFEST_FILE", "r") as f:
    data = json.load(f)
if "category" in data:
    del data["category"]
with open("$MANIFEST_FILE", "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
EOF
        echo "✅ FIXED: category field removed"
    else
        echo "[HINT] Run with --fix to automatically correct this"
        exit 1
    fi
else
    echo "✅ PASS: No invalid 'category' field"
fi

# Test 5: Author field structure
if ! grep -A1 '"author"' "$MANIFEST_FILE" | grep -q '"name"'; then
    echo "❌ FAIL: author.name field missing"
    exit 1
fi
echo "✅ PASS: author field properly structured"

# Final validation
if python3 -m json.tool "$MANIFEST_FILE" > /dev/null 2>&1; then
    echo ""
    echo "=========================================="
    echo "✅ MANIFEST VALIDATION PASSED"
    echo "=========================================="
    echo "Plugin: $PLUGIN_NAME"
    echo "File: $MANIFEST_FILE"
    echo ""
    exit 0
else
    echo ""
    echo "=========================================="
    echo "❌ MANIFEST VALIDATION FAILED"
    echo "=========================================="
    exit 1
fi
