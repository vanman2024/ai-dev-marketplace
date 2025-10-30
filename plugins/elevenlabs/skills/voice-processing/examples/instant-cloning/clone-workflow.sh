#!/usr/bin/env bash
#
# Complete instant voice cloning workflow
#

set -euo pipefail

# Configuration
VOICE_NAME="${1:-Demo Voice}"
RAW_AUDIO="${2:-raw_audio.mp3}"
ELEVEN_API_KEY="${ELEVEN_API_KEY:-}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Instant Voice Cloning Workflow${NC}"
echo "================================"
echo ""

# Step 1: Validate input
if [[ ! -f "$RAW_AUDIO" ]]; then
    echo -e "${YELLOW}Error: Audio file not found: $RAW_AUDIO${NC}"
    echo "Usage: $0 [voice_name] [audio_file.mp3]"
    exit 1
fi

if [[ -z "$ELEVEN_API_KEY" ]]; then
    echo -e "${YELLOW}Error: ELEVEN_API_KEY not set${NC}"
    exit 1
fi

echo -e "${GREEN}Step 1: Validating audio file${NC}"
python ../../scripts/process-audio.py \
    --input "$RAW_AUDIO" \
    --info-only \
    --validate || true

echo ""
read -p "Continue with audio processing? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Workflow cancelled"
    exit 0
fi

# Step 2: Process audio
echo ""
echo -e "${GREEN}Step 2: Processing audio${NC}"
PROCESSED_AUDIO="processed_$(basename "$RAW_AUDIO")"

python ../../scripts/process-audio.py \
    --input "$RAW_AUDIO" \
    --output "$PROCESSED_AUDIO" \
    --sample-rate 22050 \
    --remove-noise \
    --normalize \
    --trim-silence \
    --validate

# Step 3: Clone voice
echo ""
echo -e "${GREEN}Step 3: Cloning voice${NC}"
bash ../../scripts/clone-voice.sh \
    --name "$VOICE_NAME" \
    --method instant \
    --files "$PROCESSED_AUDIO" \
    --description "Voice cloned via instant cloning workflow"

# Extract voice ID from last output
VOICE_ID=$(ls -t voice_*.json | head -1 | sed 's/voice_//' | sed 's/.json//')

echo ""
echo -e "${GREEN}Step 4: Voice cloned successfully!${NC}"
echo "Voice ID: $VOICE_ID"

# Step 4: Test voice
echo ""
read -p "Generate test audio? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}Generating test audio${NC}"
    curl -s -X POST "https://api.elevenlabs.io/v1/text-to-speech/${VOICE_ID}" \
        -H "xi-api-key: ${ELEVEN_API_KEY}" \
        -H "Content-Type: application/json" \
        -d '{"text":"Hello! This is my cloned voice using instant voice cloning. How does it sound?"}' \
        --output "test_${VOICE_ID}.mp3"

    echo -e "${GREEN}✓ Test audio saved to: test_${VOICE_ID}.mp3${NC}"
fi

# Step 5: Configure settings
echo ""
read -p "Configure voice settings? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Voice Settings Presets:"
    echo "  1. Narration (stable, consistent)"
    echo "  2. Dialogue (balanced, conversational)"
    echo "  3. Character (expressive, variable)"
    read -p "Select preset (1-3) or skip (s): " -n 1 -r PRESET
    echo

    case $PRESET in
        1)
            bash ../../scripts/configure-voice-settings.sh \
                --voice-id "$VOICE_ID" \
                --stability 0.8 \
                --similarity 0.75 \
                --style 0.0
            ;;
        2)
            bash ../../scripts/configure-voice-settings.sh \
                --voice-id "$VOICE_ID" \
                --stability 0.5 \
                --similarity 0.8 \
                --style 0.2
            ;;
        3)
            bash ../../scripts/configure-voice-settings.sh \
                --voice-id "$VOICE_ID" \
                --stability 0.3 \
                --similarity 0.7 \
                --style 0.6
            ;;
        *)
            echo "Skipping settings configuration"
            ;;
    esac
fi

echo ""
echo -e "${GREEN}Workflow Complete!${NC}"
echo "==================="
echo "Voice ID: $VOICE_ID"
echo "Voice Name: $VOICE_NAME"
echo "Processed Audio: $PROCESSED_AUDIO"
echo ""
echo "Next steps:"
echo "  • List all voices: bash ../../scripts/list-voices.sh"
echo "  • Test TTS: curl -X POST 'https://api.elevenlabs.io/v1/text-to-speech/${VOICE_ID}' -H 'xi-api-key: \$ELEVEN_API_KEY' -H 'Content-Type: application/json' -d '{\"text\":\"Test\"}' --output test.mp3"
echo "  • Adjust settings: bash ../../scripts/configure-voice-settings.sh --voice-id '$VOICE_ID' --stability 0.75"

exit 0
