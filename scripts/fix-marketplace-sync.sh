#!/bin/bash

# Auto-fix Marketplace Sync Script
# Calls the SINGLE marketplace-validator.py script
# No more confusion about which tools to use!

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
VALIDATOR="$SCRIPT_DIR/marketplace-validator.py"

echo "================================================================================"
echo "🔧 Auto-Fix AI Dev Marketplace Sync"
echo "================================================================================"
echo "Using marketplace-validator.py (single source of truth)"
echo ""

if [ ! -f "$VALIDATOR" ]; then
    echo "❌ ERROR: marketplace-validator.py not found at $VALIDATOR"
    exit 1
fi

# Just call the Python validator with --fix
python "$VALIDATOR" --fix

echo ""
echo "✅ Done! Run 'bash scripts/validate-marketplace-sync.sh' to verify"
echo ""
