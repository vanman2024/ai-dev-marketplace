#!/usr/bin/env bash
# Test different stability values to find optimal setting

set -euo pipefail

VOICE_ID="${1:-}"
ELEVEN_API_KEY="${ELEVEN_API_KEY:-}"

if [[ -z "$VOICE_ID" ]] || [[ -z "$ELEVEN_API_KEY" ]]; then
    echo "Usage: ELEVEN_API_KEY=key $0 <voice_id>"
    exit 1
fi

TEST_TEXT="This is a test of voice stability settings. The quick brown fox jumps over the lazy dog."
STABILITY_VALUES=(0.3 0.5 0.7 0.9)

echo "Testing Stability Values"
echo "========================"
echo ""

for stability in "${STABILITY_VALUES[@]}"; do
    echo "Testing stability: $stability"

    # Update settings
    bash ../../scripts/configure-voice-settings.sh \
        --voice-id "$VOICE_ID" \
        --stability "$stability" \
        > /dev/null 2>&1

    # Generate test audio
    curl -s -X POST \
        "https://api.elevenlabs.io/v1/text-to-speech/${VOICE_ID}" \
        -H "xi-api-key: ${ELEVEN_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "{\"text\":\"$TEST_TEXT\"}" \
        --output "test_stability_${stability}.mp3"

    echo "  Generated: test_stability_${stability}.mp3"
done

echo ""
echo "Test complete! Listen to each file and choose the best stability value."
echo "Files: test_stability_*.mp3"
echo ""
echo "Recommendations:"
echo "  0.3 - Most expressive, variable"
echo "  0.5 - Balanced"
echo "  0.7 - Consistent"
echo "  0.9 - Very stable, narration"

exit 0
