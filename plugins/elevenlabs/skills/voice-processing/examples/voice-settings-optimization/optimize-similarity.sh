#!/usr/bin/env bash
# Test different similarity boost values

set -euo pipefail

VOICE_ID="${1:-}"
ELEVEN_API_KEY="${ELEVEN_API_KEY:-}"

if [[ -z "$VOICE_ID" ]] || [[ -z "$ELEVEN_API_KEY" ]]; then
    echo "Usage: ELEVEN_API_KEY=key $0 <voice_id>"
    exit 1
fi

TEST_TEXT="Testing similarity boost settings for voice clone accuracy and naturalness."
SIMILARITY_VALUES=(0.5 0.7 0.85 0.95)

echo "Testing Similarity Boost Values"
echo "================================"
echo ""

for similarity in "${SIMILARITY_VALUES[@]}"; do
    echo "Testing similarity: $similarity"

    bash ../../scripts/configure-voice-settings.sh \
        --voice-id "$VOICE_ID" \
        --similarity "$similarity" \
        > /dev/null 2>&1

    curl -s -X POST \
        "https://api.elevenlabs.io/v1/text-to-speech/${VOICE_ID}" \
        -H "xi-api-key: ${ELEVEN_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "{\"text\":\"$TEST_TEXT\"}" \
        --output "test_similarity_${similarity}.mp3"

    echo "  Generated: test_similarity_${similarity}.mp3"
done

echo ""
echo "Listen to compare similarity to original voice."
echo ""
echo "Recommendations:"
echo "  0.5 - More creative, varied"
echo "  0.7 - Balanced"
echo "  0.85 - High fidelity"
echo "  0.95 - Maximum similarity"

exit 0
