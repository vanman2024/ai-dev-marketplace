#!/usr/bin/env bash
#
# Verify voice clone quality and characteristics
#

set -euo pipefail

VOICE_ID="${1:-}"
ELEVEN_API_KEY="${ELEVEN_API_KEY:-}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

if [[ -z "$VOICE_ID" ]]; then
    echo -e "${RED}Usage: $0 <voice_id>${NC}"
    exit 1
fi

if [[ -z "$ELEVEN_API_KEY" ]]; then
    echo -e "${RED}Error: ELEVEN_API_KEY not set${NC}"
    exit 1
fi

echo -e "${BLUE}Voice Clone Verification${NC}"
echo "========================="
echo "Voice ID: $VOICE_ID"
echo ""

# Get voice details
echo -e "${GREEN}Fetching voice details...${NC}"
curl -s -X GET \
    "https://api.elevenlabs.io/v1/voices/${VOICE_ID}" \
    -H "xi-api-key: ${ELEVEN_API_KEY}" \
    | jq '.'

# Get voice settings
echo ""
echo -e "${GREEN}Fetching voice settings...${NC}"
curl -s -X GET \
    "https://api.elevenlabs.io/v1/voices/${VOICE_ID}/settings" \
    -H "xi-api-key: ${ELEVEN_API_KEY}" \
    | jq '.'

# Generate test phrases
echo ""
echo -e "${GREEN}Generating test audio samples...${NC}"

TEST_PHRASES=(
    "This is a test of the voice cloning quality."
    "The quick brown fox jumps over the lazy dog."
    "Hello, how are you doing today? I hope you're having a wonderful day!"
    "One, two, three, four, five. Testing numbers and counting."
)

for i in "${!TEST_PHRASES[@]}"; do
    phrase="${TEST_PHRASES[$i]}"
    output_file="test_${VOICE_ID}_sample_$((i+1)).mp3"

    echo "Generating sample $((i+1)): ${phrase:0:50}..."

    curl -s -X POST \
        "https://api.elevenlabs.io/v1/text-to-speech/${VOICE_ID}" \
        -H "xi-api-key: ${ELEVEN_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "{\"text\":\"$phrase\"}" \
        --output "$output_file"

    echo -e "${GREEN}✓${NC} Saved to: $output_file"
done

echo ""
echo -e "${GREEN}Verification Complete!${NC}"
echo ""
echo "Test audio files generated:"
ls -1 test_${VOICE_ID}_sample_*.mp3 2>/dev/null || echo "No files found"
echo ""
echo "Listen to the samples and evaluate:"
echo "  • Clarity and intelligibility"
echo "  • Similarity to original voice"
echo "  • Naturalness and expressiveness"
echo "  • Consistency across samples"
echo ""
echo "If quality needs improvement:"
echo "  • Adjust stability: bash ../../scripts/configure-voice-settings.sh --voice-id '$VOICE_ID' --stability 0.5"
echo "  • Adjust similarity: bash ../../scripts/configure-voice-settings.sh --voice-id '$VOICE_ID' --similarity 0.85"
echo "  • Add more training samples or upgrade to Professional Voice Cloning"

exit 0
