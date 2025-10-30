#!/usr/bin/env bash
# Add voices to collections for organization

set -euo pipefail

VOICE_ID="${1:-}"
COLLECTION="${2:-My Collection}"

if [[ -z "$VOICE_ID" ]]; then
    echo "Usage: $0 <voice_id> [collection_name]"
    exit 1
fi

echo "Adding voice to collection..."
bash ../../scripts/manage-voice-library.sh \
    --action add \
    --voice-id "$VOICE_ID" \
    --collection "$COLLECTION"

echo ""
echo "Voice added to collection: $COLLECTION"

exit 0
