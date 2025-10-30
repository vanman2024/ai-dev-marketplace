#!/usr/bin/env bash
# Test voice with current settings

set -euo pipefail

VOICE_ID="${1:-}"
ELEVEN_API_KEY="${ELEVEN_API_KEY:-}"

if [[ -z "$VOICE_ID" ]] || [[ -z "$ELEVEN_API_KEY" ]]; then
    echo "Usage: ELEVEN_API_KEY=key $0 <voice_id>"
    exit 1
fi

echo "Voice Settings Test"
echo "==================="
echo ""

# Get current settings
bash ../../scripts/configure-voice-settings.sh \
    --voice-id "$VOICE_ID" \
    --get-current

# Test phrases
TEST_PHRASES=(
    "Neutral statement in conversational tone."
    "Exciting news! This is amazing!"
    "I'm sorry to hear that."
    "Technical specifications indicate optimal performance."
)

echo ""
echo "Generating test audio with current settings..."
echo ""

for i in "${!TEST_PHRASES[@]}"; do
    phrase="${TEST_PHRASES[$i]}"
    output="test_phrase_$((i+1)).mp3"

    curl -s -X POST \
        "https://api.elevenlabs.io/v1/text-to-speech/${VOICE_ID}" \
        -H "xi-api-key: ${ELEVEN_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "{\"text\":\"$phrase\"}" \
        --output "$output"

    echo "Generated: $output - \"${phrase:0:40}...\""
done

echo ""
echo "Test complete! Listen to all samples to evaluate settings."

exit 0
