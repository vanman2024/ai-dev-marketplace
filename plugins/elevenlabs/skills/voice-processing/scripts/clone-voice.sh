#!/usr/bin/env bash
#
# clone-voice.sh - Voice cloning script for ElevenLabs
#
# Usage:
#   bash clone-voice.sh --name "Voice Name" --method instant --files "audio1.mp3,audio2.mp3"
#   bash clone-voice.sh --name "Voice Name" --method professional --files "audio1.mp3,audio2.mp3" --description "Description"
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
VOICE_NAME=""
CLONING_METHOD="instant"
AUDIO_FILES=""
DESCRIPTION=""
LABELS=""
API_KEY="${ELEVEN_API_KEY:-}"
API_BASE_URL="${ELEVEN_API_BASE_URL:-https://api.elevenlabs.io/v1}"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --name)
            VOICE_NAME="$2"
            shift 2
            ;;
        --method)
            CLONING_METHOD="$2"
            shift 2
            ;;
        --files)
            AUDIO_FILES="$2"
            shift 2
            ;;
        --description)
            DESCRIPTION="$2"
            shift 2
            ;;
        --labels)
            LABELS="$2"
            shift 2
            ;;
        --api-key)
            API_KEY="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 --name \"Voice Name\" --method instant|professional --files \"file1.mp3,file2.mp3\""
            echo ""
            echo "Options:"
            echo "  --name         Voice name (required)"
            echo "  --method       Cloning method: instant or professional (default: instant)"
            echo "  --files        Comma-separated list of audio files (required)"
            echo "  --description  Voice description (optional)"
            echo "  --labels       Comma-separated labels/tags (optional)"
            echo "  --api-key      ElevenLabs API key (or set ELEVEN_API_KEY env var)"
            echo "  --help         Show this help message"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Validate required parameters
if [[ -z "$VOICE_NAME" ]]; then
    echo -e "${RED}Error: --name is required${NC}"
    exit 1
fi

if [[ -z "$AUDIO_FILES" ]]; then
    echo -e "${RED}Error: --files is required${NC}"
    exit 1
fi

if [[ -z "$API_KEY" ]]; then
    echo -e "${RED}Error: API key not found. Set ELEVEN_API_KEY environment variable or use --api-key${NC}"
    exit 1
fi

# Validate cloning method
if [[ "$CLONING_METHOD" != "instant" && "$CLONING_METHOD" != "professional" ]]; then
    echo -e "${RED}Error: Method must be 'instant' or 'professional'${NC}"
    exit 1
fi

echo -e "${GREEN}ElevenLabs Voice Cloning${NC}"
echo "========================="
echo "Voice Name: $VOICE_NAME"
echo "Method: $CLONING_METHOD"
echo "Audio Files: $AUDIO_FILES"
echo ""

# Convert comma-separated files to array
IFS=',' read -ra FILE_ARRAY <<< "$AUDIO_FILES"

# Validate audio files exist
echo "Validating audio files..."
for file in "${FILE_ARRAY[@]}"; do
    file=$(echo "$file" | xargs) # trim whitespace
    if [[ ! -f "$file" ]]; then
        echo -e "${RED}Error: Audio file not found: $file${NC}"
        exit 1
    fi

    # Check file size
    file_size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
    if [[ "$file_size" -lt 1000 ]]; then
        echo -e "${YELLOW}Warning: File appears very small: $file (${file_size} bytes)${NC}"
    fi

    echo -e "${GREEN}✓${NC} $file ($(numfmt --to=iec-i --suffix=B "$file_size" 2>/dev/null || echo "${file_size} bytes"))"
done

# Determine API endpoint based on method
if [[ "$CLONING_METHOD" == "instant" ]]; then
    ENDPOINT="${API_BASE_URL}/voices/add"
else
    ENDPOINT="${API_BASE_URL}/voices/add"
fi

# Build curl command with multipart form data
CURL_CMD="curl -s -X POST \"$ENDPOINT\" \
  -H \"xi-api-key: $API_KEY\" \
  -F \"name=$VOICE_NAME\""

# Add description if provided
if [[ -n "$DESCRIPTION" ]]; then
    CURL_CMD="$CURL_CMD -F \"description=$DESCRIPTION\""
fi

# Add labels if provided
if [[ -n "$LABELS" ]]; then
    # Convert comma-separated labels to JSON array format
    IFS=',' read -ra LABEL_ARRAY <<< "$LABELS"
    LABELS_JSON="{"
    for i in "${!LABEL_ARRAY[@]}"; do
        label=$(echo "${LABEL_ARRAY[$i]}" | xargs)
        LABELS_JSON="$LABELS_JSON\"$label\":\"$label\""
        if [[ $i -lt $((${#LABEL_ARRAY[@]} - 1)) ]]; then
            LABELS_JSON="$LABELS_JSON,"
        fi
    done
    LABELS_JSON="$LABELS_JSON}"
    CURL_CMD="$CURL_CMD -F \"labels=$LABELS_JSON\""
fi

# Add audio files
for file in "${FILE_ARRAY[@]}"; do
    file=$(echo "$file" | xargs)
    CURL_CMD="$CURL_CMD -F \"files=@$file\""
done

# Execute cloning request
echo ""
echo "Cloning voice..."
RESPONSE=$(eval "$CURL_CMD")

# Check for errors in response
if echo "$RESPONSE" | jq -e '.detail' >/dev/null 2>&1; then
    ERROR_MSG=$(echo "$RESPONSE" | jq -r '.detail')
    echo -e "${RED}Error: $ERROR_MSG${NC}"
    exit 1
fi

# Extract voice ID from response
VOICE_ID=$(echo "$RESPONSE" | jq -r '.voice_id')

if [[ -z "$VOICE_ID" || "$VOICE_ID" == "null" ]]; then
    echo -e "${RED}Error: Failed to extract voice ID from response${NC}"
    echo "Response: $RESPONSE"
    exit 1
fi

echo -e "${GREEN}✓ Voice cloned successfully!${NC}"
echo ""
echo "Voice ID: $VOICE_ID"
echo "Voice Name: $VOICE_NAME"
echo "Method: $CLONING_METHOD"
echo ""

# Get voice details to confirm
echo "Fetching voice details..."
VOICE_DETAILS=$(curl -s -X GET \
  "${API_BASE_URL}/voices/${VOICE_ID}" \
  -H "xi-api-key: $API_KEY")

if echo "$VOICE_DETAILS" | jq -e '.name' >/dev/null 2>&1; then
    echo -e "${GREEN}Voice Details:${NC}"
    echo "$VOICE_DETAILS" | jq '{
        voice_id: .voice_id,
        name: .name,
        category: .category,
        description: .description,
        samples: (.samples | length),
        labels: .labels
    }'
else
    echo -e "${YELLOW}Warning: Could not fetch voice details${NC}"
fi

# Professional cloning requires additional training
if [[ "$CLONING_METHOD" == "professional" ]]; then
    echo ""
    echo -e "${YELLOW}Note: Professional voice cloning requires training.${NC}"
    echo "The voice will be processed and refined over the next few hours."
    echo "You can check the status with: curl -H \"xi-api-key: $API_KEY\" ${API_BASE_URL}/voices/${VOICE_ID}"
fi

# Save voice ID to file for easy reference
OUTPUT_FILE="voice_${VOICE_ID}.json"
echo "$RESPONSE" | jq '.' > "$OUTPUT_FILE"
echo ""
echo -e "${GREEN}Voice details saved to: $OUTPUT_FILE${NC}"

# Usage instructions
echo ""
echo "Next steps:"
echo "1. Test the voice with text-to-speech:"
echo "   curl -X POST \"${API_BASE_URL}/text-to-speech/${VOICE_ID}\" \\"
echo "     -H \"xi-api-key: $API_KEY\" \\"
echo "     -H \"Content-Type: application/json\" \\"
echo "     -d '{\"text\":\"Hello, this is my cloned voice!\"}' \\"
echo "     --output test_output.mp3"
echo ""
echo "2. Adjust voice settings if needed:"
echo "   bash scripts/configure-voice-settings.sh --voice-id \"$VOICE_ID\" --stability 0.75 --similarity 0.85"
echo ""

if [[ "$CLONING_METHOD" == "professional" ]]; then
    echo "3. Share voice in library (Professional clones only):"
    echo "   bash scripts/manage-voice-library.sh --action share --voice-id \"$VOICE_ID\""
    echo ""
fi

exit 0
