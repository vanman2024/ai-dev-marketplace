#!/usr/bin/env bash
# validate-collection.sh - Validate Postman collection structure
# Usage: validate-collection.sh <collection.json>

set -euo pipefail

COLLECTION="${1:?Collection file required}"

if [ ! -f "$COLLECTION" ]; then
    echo "❌ Collection file not found: $COLLECTION"
    exit 1
fi

echo "Validating Postman collection: $COLLECTION"

# Check if it's valid JSON
if ! jq empty "$COLLECTION" 2>/dev/null; then
    echo "❌ Invalid JSON format"
    exit 1
fi

# Check required fields
if ! jq -e '.info.name' "$COLLECTION" >/dev/null; then
    echo "❌ Missing collection name"
    exit 1
fi

# Count items
ITEM_COUNT=$(jq '[.item[]?] | length' "$COLLECTION")
echo "✅ Collection is valid"
echo "  Name: $(jq -r '.info.name' "$COLLECTION")"
echo "  Items: $ITEM_COUNT"

exit 0
