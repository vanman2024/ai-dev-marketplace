#!/usr/bin/env bash
# Share professional voice clone in library with rewards

set -euo pipefail

VOICE_ID="${1:-}"

if [[ -z "$VOICE_ID" ]]; then
    echo "Usage: $0 <voice_id>"
    exit 1
fi

echo "Sharing voice in library with rewards enabled..."

bash ../../scripts/manage-voice-library.sh \
    --action share \
    --voice-id "$VOICE_ID" \
    --enable-rewards \
    --description "Professional voice clone available for use" \
    --tags "professional,narration,production"

echo ""
echo "Voice shared in library!"
echo "You can now earn rewards when others use your voice."

exit 0
