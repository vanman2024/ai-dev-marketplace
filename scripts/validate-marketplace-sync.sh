#!/bin/bash

# Validate Marketplace Sync Script
# Calls the SINGLE marketplace-validator.py script
# No more confusion about which tools to use!

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
VALIDATOR="$SCRIPT_DIR/marketplace-validator.py"

echo "================================================================================"
echo "🔍 Validate AI Dev Marketplace Sync"
echo "================================================================================"
echo "Using marketplace-validator.py (single source of truth)"
echo ""

if [ ! -f "$VALIDATOR" ]; then
    echo "❌ ERROR: marketplace-validator.py not found at $VALIDATOR"
    exit 1
fi

# Just call the Python validator with --validate
python "$VALIDATOR" --validate
EXIT_CODE=$?

echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ All validations passed!"
else
    echo "❌ Validation failures detected. Run 'bash scripts/fix-marketplace-sync.sh' to fix"
fi
echo ""

exit $EXIT_CODE
