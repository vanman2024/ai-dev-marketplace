#!/usr/bin/env bash
# Advanced voice search examples

set -euo pipefail

ELEVEN_API_KEY="${ELEVEN_API_KEY:-}"

if [[ -z "$ELEVEN_API_KEY" ]]; then
    echo "Error: ELEVEN_API_KEY not set"
    exit 1
fi

echo "Voice Library Search Examples"
echo "=============================="
echo ""

# Example 1: Find Australian narrators
echo "1. Australian narrators:"
bash ../../scripts/list-voices.sh \
    --category library \
    --search "Australian narration"
echo ""

# Example 2: Find professional female voices
echo "2. Professional female voices:"
bash ../../scripts/list-voices.sh \
    --category library \
    --search "female professional"
echo ""

# Example 3: Find British accent voices
echo "3. British accent voices:"
bash ../../scripts/list-voices.sh \
    --category library \
    --search "British"
echo ""

# Example 4: Your cloned voices
echo "4. Your cloned voices:"
bash ../../scripts/list-voices.sh --category cloned
echo ""

# Example 5: JSON output for processing
echo "5. JSON output (first 5 voices):"
bash ../../scripts/list-voices.sh \
    --category all \
    --format json \
    | jq '.[:5]'

exit 0
