#!/usr/bin/env bash
#
# configure-voice-settings.sh - Configure and update ElevenLabs voice settings
#
# Usage:
#   bash configure-voice-settings.sh --voice-id "abc123" --stability 0.75 --similarity 0.85
#   bash configure-voice-settings.sh --voice-id "abc123" --get-defaults
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
VOICE_ID=""
STABILITY=""
SIMILARITY_BOOST=""
STYLE=""
USE_SPEAKER_BOOST=""
GET_DEFAULTS="false"
GET_CURRENT="false"
API_KEY="${ELEVEN_API_KEY:-}"
API_BASE_URL="${ELEVEN_API_BASE_URL:-https://api.elevenlabs.io/v1}"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --voice-id)
            VOICE_ID="$2"
            shift 2
            ;;
        --stability)
            STABILITY="$2"
            shift 2
            ;;
        --similarity)
            SIMILARITY_BOOST="$2"
            shift 2
            ;;
        --style)
            STYLE="$2"
            shift 2
            ;;
        --speaker-boost)
            USE_SPEAKER_BOOST="$2"
            shift 2
            ;;
        --get-defaults)
            GET_DEFAULTS="true"
            shift
            ;;
        --get-current)
            GET_CURRENT="true"
            shift
            ;;
        --api-key)
            API_KEY="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 --voice-id <id> [options]"
            echo ""
            echo "Options:"
            echo "  --voice-id         Voice ID (required)"
            echo "  --stability        Stability (0.0-1.0, default: 0.75)"
            echo "  --similarity       Similarity boost (0.0-1.0, default: 0.75)"
            echo "  --style            Style (0.0-1.0, default: 0.0)"
            echo "  --speaker-boost    Enable speaker boost (true/false)"
            echo "  --get-defaults     Get default voice settings"
            echo "  --get-current      Get current voice settings"
            echo "  --api-key          ElevenLabs API key (or set ELEVEN_API_KEY env var)"
            echo "  --help             Show this help message"
            echo ""
            echo "Parameter Explanations:"
            echo "  Stability:"
            echo "    - Lower (0.0-0.3): More expressive, variable"
            echo "    - Medium (0.4-0.6): Balanced expression and consistency"
            echo "    - Higher (0.7-1.0): More consistent, stable"
            echo ""
            echo "  Similarity Boost:"
            echo "    - Lower (0.0-0.3): More creative, varied output"
            echo "    - Medium (0.4-0.6): Balanced clone fidelity and versatility"
            echo "    - Higher (0.7-1.0): Closer to original voice"
            echo ""
            echo "  Style:"
            echo "    - Lower (0.0-0.2): More neutral delivery"
            echo "    - Medium (0.3-0.6): Moderate expressiveness"
            echo "    - Higher (0.7-1.0): More expressive, character-like"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Validate required parameters
if [[ -z "$VOICE_ID" ]]; then
    echo -e "${RED}Error: --voice-id is required${NC}"
    exit 1
fi

if [[ -z "$API_KEY" ]]; then
    echo -e "${RED}Error: API key not found. Set ELEVEN_API_KEY environment variable or use --api-key${NC}"
    exit 1
fi

echo -e "${GREEN}ElevenLabs Voice Settings Configuration${NC}"
echo "========================================"
echo "Voice ID: $VOICE_ID"
echo ""

# Validate numeric ranges
validate_range() {
    local value=$1
    local name=$2

    if [[ -n "$value" ]]; then
        # Check if numeric
        if ! [[ "$value" =~ ^[0-9]*\.?[0-9]+$ ]]; then
            echo -e "${RED}Error: $name must be a number${NC}"
            return 1
        fi

        # Check range
        if (( $(echo "$value < 0.0" | bc -l) )) || (( $(echo "$value > 1.0" | bc -l) )); then
            echo -e "${RED}Error: $name must be between 0.0 and 1.0${NC}"
            return 1
        fi
    fi

    return 0
}

# Validate boolean
validate_boolean() {
    local value=$1
    local name=$2

    if [[ -n "$value" ]]; then
        if [[ "$value" != "true" && "$value" != "false" ]]; then
            echo -e "${RED}Error: $name must be 'true' or 'false'${NC}"
            return 1
        fi
    fi

    return 0
}

# Get default settings
if [[ "$GET_DEFAULTS" == "true" ]]; then
    echo "Fetching default voice settings..."
    RESPONSE=$(curl -s -X GET \
        "${API_BASE_URL}/voices/settings/default" \
        -H "xi-api-key: $API_KEY")

    if echo "$RESPONSE" | jq -e '.detail' >/dev/null 2>&1; then
        ERROR_MSG=$(echo "$RESPONSE" | jq -r '.detail')
        echo -e "${RED}Error: $ERROR_MSG${NC}"
        exit 1
    fi

    echo -e "${BLUE}Default Voice Settings:${NC}"
    echo "$RESPONSE" | jq '.'

    exit 0
fi

# Get current voice settings
if [[ "$GET_CURRENT" == "true" || -z "$STABILITY$SIMILARITY_BOOST$STYLE$USE_SPEAKER_BOOST" ]]; then
    echo "Fetching current voice settings..."
    RESPONSE=$(curl -s -X GET \
        "${API_BASE_URL}/voices/${VOICE_ID}/settings" \
        -H "xi-api-key: $API_KEY")

    if echo "$RESPONSE" | jq -e '.detail' >/dev/null 2>&1; then
        ERROR_MSG=$(echo "$RESPONSE" | jq -r '.detail')
        echo -e "${RED}Error: $ERROR_MSG${NC}"
        exit 1
    fi

    echo -e "${BLUE}Current Voice Settings:${NC}"
    echo "$RESPONSE" | jq '.'

    # If only getting current settings, exit here
    if [[ "$GET_CURRENT" == "true" ]]; then
        # Display parameter explanations
        echo ""
        echo -e "${GREEN}Parameter Recommendations:${NC}"
        CURRENT_STABILITY=$(echo "$RESPONSE" | jq -r '.stability')
        CURRENT_SIMILARITY=$(echo "$RESPONSE" | jq -r '.similarity_boost')
        CURRENT_STYLE=$(echo "$RESPONSE" | jq -r '.style // 0.0')

        echo ""
        echo "Stability: $CURRENT_STABILITY"
        if (( $(echo "$CURRENT_STABILITY < 0.4" | bc -l) )); then
            echo "  → More expressive and variable output"
        elif (( $(echo "$CURRENT_STABILITY < 0.7" | bc -l) )); then
            echo "  → Balanced expression and consistency"
        else
            echo "  → More consistent and stable output"
        fi

        echo ""
        echo "Similarity Boost: $CURRENT_SIMILARITY"
        if (( $(echo "$CURRENT_SIMILARITY < 0.4" | bc -l) )); then
            echo "  → More creative and varied"
        elif (( $(echo "$CURRENT_SIMILARITY < 0.7" | bc -l) )); then
            echo "  → Balanced clone fidelity"
        else
            echo "  → Closer to original voice"
        fi

        echo ""
        echo "Style: $CURRENT_STYLE"
        if (( $(echo "$CURRENT_STYLE < 0.3" | bc -l) )); then
            echo "  → More neutral delivery"
        elif (( $(echo "$CURRENT_STYLE < 0.7" | bc -l) )); then
            echo "  → Moderate expressiveness"
        else
            echo "  → More expressive, character-like"
        fi

        exit 0
    fi

    echo ""
fi

# Validate parameters
validate_range "$STABILITY" "Stability" || exit 1
validate_range "$SIMILARITY_BOOST" "Similarity boost" || exit 1
validate_range "$STYLE" "Style" || exit 1
validate_boolean "$USE_SPEAKER_BOOST" "Speaker boost" || exit 1

# Build settings JSON
SETTINGS_JSON="{}"

if [[ -n "$STABILITY" ]]; then
    SETTINGS_JSON=$(echo "$SETTINGS_JSON" | jq --argjson stability "$STABILITY" '. + {stability: $stability}')
    echo "Setting stability: $STABILITY"
fi

if [[ -n "$SIMILARITY_BOOST" ]]; then
    SETTINGS_JSON=$(echo "$SETTINGS_JSON" | jq --argjson similarity "$SIMILARITY_BOOST" '. + {similarity_boost: $similarity}')
    echo "Setting similarity boost: $SIMILARITY_BOOST"
fi

if [[ -n "$STYLE" ]]; then
    SETTINGS_JSON=$(echo "$SETTINGS_JSON" | jq --argjson style "$STYLE" '. + {style: $style}')
    echo "Setting style: $STYLE"
fi

if [[ -n "$USE_SPEAKER_BOOST" ]]; then
    SETTINGS_JSON=$(echo "$SETTINGS_JSON" | jq --argjson boost "$(echo "$USE_SPEAKER_BOOST" | jq -R 'fromjson')" '. + {use_speaker_boost: $boost}')
    echo "Setting speaker boost: $USE_SPEAKER_BOOST"
fi

# Check if any settings to update
if [[ "$SETTINGS_JSON" == "{}" ]]; then
    echo -e "${YELLOW}No settings to update${NC}"
    exit 0
fi

# Update voice settings
echo ""
echo "Updating voice settings..."
RESPONSE=$(curl -s -X POST \
    "${API_BASE_URL}/voices/${VOICE_ID}/settings/edit" \
    -H "xi-api-key: $API_KEY" \
    -H "Content-Type: application/json" \
    -d "$SETTINGS_JSON")

# Check for errors
if echo "$RESPONSE" | jq -e '.detail' >/dev/null 2>&1; then
    ERROR_MSG=$(echo "$RESPONSE" | jq -r '.detail')
    echo -e "${RED}Error: $ERROR_MSG${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Voice settings updated successfully${NC}"

# Get updated settings
echo ""
echo "Fetching updated settings..."
UPDATED_RESPONSE=$(curl -s -X GET \
    "${API_BASE_URL}/voices/${VOICE_ID}/settings" \
    -H "xi-api-key: $API_KEY")

if echo "$UPDATED_RESPONSE" | jq -e '.stability' >/dev/null 2>&1; then
    echo -e "${GREEN}Updated Voice Settings:${NC}"
    echo "$UPDATED_RESPONSE" | jq '.'
fi

# Save settings to file
OUTPUT_FILE="voice_settings_${VOICE_ID}.json"
echo "$UPDATED_RESPONSE" | jq '.' > "$OUTPUT_FILE"
echo ""
echo -e "${GREEN}Settings saved to: $OUTPUT_FILE${NC}"

# Usage recommendations
echo ""
echo -e "${BLUE}Usage Recommendations:${NC}"
echo ""
echo "Narration (Audiobooks, Podcasts):"
echo "  --stability 0.8 --similarity 0.75 --style 0.0"
echo ""
echo "Dialogue (Conversational):"
echo "  --stability 0.5 --similarity 0.8 --style 0.2"
echo ""
echo "Character Voices (Expressive):"
echo "  --stability 0.3 --similarity 0.7 --style 0.6"
echo ""
echo "Clone Fidelity (Match Original):"
echo "  --stability 0.7 --similarity 0.9 --style 0.0"

echo ""
echo "Next steps:"
echo "  • Test voice with new settings:"
echo "    curl -X POST \"${API_BASE_URL}/text-to-speech/${VOICE_ID}\" \\"
echo "      -H \"xi-api-key: $API_KEY\" \\"
echo "      -H \"Content-Type: application/json\" \\"
echo "      -d '{\"text\":\"Test with new settings\"}' \\"
echo "      --output test_output.mp3"

exit 0
