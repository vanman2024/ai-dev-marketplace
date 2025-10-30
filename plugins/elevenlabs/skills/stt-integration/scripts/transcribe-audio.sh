#!/usr/bin/env bash
set -euo pipefail

#############################################################
# ElevenLabs STT Audio Transcription Script
#############################################################
# Usage: ./transcribe-audio.sh <audio_file> [language_code] [options]
# Example: ./transcribe-audio.sh interview.mp3 en --diarize --num-speakers=2
#
# Environment Variables:
#   ELEVENLABS_API_KEY - Required API key for authentication
#
# Options:
#   --diarize              Enable speaker diarization (default: true)
#   --num-speakers=N       Set max number of speakers (1-32)
#   --tag-events           Enable audio event tagging (default: true)
#   --no-timestamps        Disable word-level timestamps
#   --output=FILE          Save transcription to file
#   --json                 Output raw JSON response
#############################################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
DIARIZE="true"
TAG_EVENTS="true"
TIMESTAMPS="word"
NUM_SPEAKERS=""
OUTPUT_FILE=""
OUTPUT_JSON="false"
LANGUAGE_CODE="auto"

# Check for API key
if [[ -z "${ELEVENLABS_API_KEY:-}" ]]; then
    echo -e "${RED}Error: ELEVENLABS_API_KEY environment variable not set${NC}"
    echo "Set it with: export ELEVENLABS_API_KEY='your_api_key'"
    exit 1
fi

# Parse arguments
AUDIO_FILE=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --diarize)
            DIARIZE="true"
            shift
            ;;
        --no-diarize)
            DIARIZE="false"
            shift
            ;;
        --num-speakers=*)
            NUM_SPEAKERS="${1#*=}"
            shift
            ;;
        --tag-events)
            TAG_EVENTS="true"
            shift
            ;;
        --no-tag-events)
            TAG_EVENTS="false"
            shift
            ;;
        --no-timestamps)
            TIMESTAMPS="none"
            shift
            ;;
        --output=*)
            OUTPUT_FILE="${1#*=}"
            shift
            ;;
        --json)
            OUTPUT_JSON="true"
            shift
            ;;
        -*)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
        *)
            if [[ -z "$AUDIO_FILE" ]]; then
                AUDIO_FILE="$1"
            elif [[ "$LANGUAGE_CODE" == "auto" ]]; then
                LANGUAGE_CODE="$1"
            fi
            shift
            ;;
    esac
done

# Validate audio file
if [[ -z "$AUDIO_FILE" ]]; then
    echo -e "${RED}Error: Audio file path required${NC}"
    echo "Usage: $0 <audio_file> [language_code] [options]"
    exit 1
fi

if [[ ! -f "$AUDIO_FILE" ]]; then
    echo -e "${RED}Error: Audio file not found: $AUDIO_FILE${NC}"
    exit 1
fi

# Check file size (max 3 GB)
FILE_SIZE=$(stat -f%z "$AUDIO_FILE" 2>/dev/null || stat -c%s "$AUDIO_FILE" 2>/dev/null || echo 0)
MAX_SIZE=$((3 * 1024 * 1024 * 1024)) # 3 GB in bytes

if [[ $FILE_SIZE -gt $MAX_SIZE ]]; then
    echo -e "${RED}Error: File size exceeds 3 GB limit${NC}"
    echo "File size: $(numfmt --to=iec-i --suffix=B $FILE_SIZE)"
    exit 1
fi

# Validate supported format
EXTENSION="${AUDIO_FILE##*.}"
EXTENSION_LOWER=$(echo "$EXTENSION" | tr '[:upper:]' '[:lower:]')
SUPPORTED_AUDIO="aac aiff ogg mp3 opus wav webm flac m4a"
SUPPORTED_VIDEO="mp4 avi mkv mov wmv flv webm mpeg 3gp"

if [[ ! " $SUPPORTED_AUDIO $SUPPORTED_VIDEO " =~ " $EXTENSION_LOWER " ]]; then
    echo -e "${YELLOW}Warning: File extension .$EXTENSION may not be supported${NC}"
    echo "Supported formats: $SUPPORTED_AUDIO $SUPPORTED_VIDEO"
fi

# Build API request
API_URL="https://api.elevenlabs.io/v1/audio-to-text"
TEMP_RESPONSE=$(mktemp)

echo -e "${BLUE}Transcribing audio file: $AUDIO_FILE${NC}"
echo -e "${BLUE}Language: $LANGUAGE_CODE${NC}"
echo -e "${BLUE}Speaker diarization: $DIARIZE${NC}"
[[ -n "$NUM_SPEAKERS" ]] && echo -e "${BLUE}Number of speakers: $NUM_SPEAKERS${NC}"
echo -e "${BLUE}Audio event tagging: $TAG_EVENTS${NC}"
echo -e "${BLUE}Timestamps: $TIMESTAMPS${NC}"
echo ""

# Prepare form data arguments
CURL_ARGS=(
    -X POST "$API_URL"
    -H "xi-api-key: $ELEVENLABS_API_KEY"
    -F "audio=@$AUDIO_FILE"
    -F "model_id=scribe_v1"
    -F "diarize=$DIARIZE"
    -F "tag_audio_events=$TAG_EVENTS"
    -F "timestamps_granularity=$TIMESTAMPS"
)

# Add optional parameters
if [[ "$LANGUAGE_CODE" != "auto" ]]; then
    CURL_ARGS+=(-F "language_code=$LANGUAGE_CODE")
fi

if [[ -n "$NUM_SPEAKERS" ]]; then
    if [[ $NUM_SPEAKERS -lt 1 || $NUM_SPEAKERS -gt 32 ]]; then
        echo -e "${RED}Error: num_speakers must be between 1 and 32${NC}"
        exit 1
    fi
    CURL_ARGS+=(-F "num_speakers=$NUM_SPEAKERS")
fi

# Make API request
echo -e "${BLUE}Sending request to ElevenLabs API...${NC}"
HTTP_CODE=$(curl -w "%{http_code}" -o "$TEMP_RESPONSE" -s "${CURL_ARGS[@]}")

# Check response status
if [[ "$HTTP_CODE" -ne 200 ]]; then
    echo -e "${RED}Error: API request failed with status $HTTP_CODE${NC}"
    echo -e "${RED}Response:${NC}"
    cat "$TEMP_RESPONSE"
    rm -f "$TEMP_RESPONSE"
    exit 1
fi

# Parse and display response
if [[ "$OUTPUT_JSON" == "true" ]]; then
    # Output raw JSON
    cat "$TEMP_RESPONSE"
    if [[ -n "$OUTPUT_FILE" ]]; then
        cp "$TEMP_RESPONSE" "$OUTPUT_FILE"
        echo -e "${GREEN}JSON saved to: $OUTPUT_FILE${NC}"
    fi
else
    # Parse and format transcription
    echo -e "${GREEN}✓ Transcription completed successfully${NC}"
    echo ""

    # Extract text (handling both 'text' and 'transcript' fields)
    TRANSCRIPTION=$(jq -r '.text // .transcript // empty' "$TEMP_RESPONSE" 2>/dev/null || echo "")

    if [[ -z "$TRANSCRIPTION" ]]; then
        # Try to extract from segments
        TRANSCRIPTION=$(jq -r '.segments[]? | select(.type == "word") | .text' "$TEMP_RESPONSE" 2>/dev/null | tr '\n' ' ' || echo "")
    fi

    if [[ -n "$TRANSCRIPTION" ]]; then
        echo -e "${BLUE}Transcription:${NC}"
        echo "$TRANSCRIPTION"
        echo ""

        # Save to file if requested
        if [[ -n "$OUTPUT_FILE" ]]; then
            echo "$TRANSCRIPTION" > "$OUTPUT_FILE"
            echo -e "${GREEN}Transcription saved to: $OUTPUT_FILE${NC}"
        fi
    else
        echo -e "${YELLOW}Warning: Could not extract transcription text${NC}"
    fi

    # Show speaker information if diarization enabled
    if [[ "$DIARIZE" == "true" ]]; then
        SPEAKERS=$(jq -r '.segments[]? | select(.speaker != null) | .speaker' "$TEMP_RESPONSE" 2>/dev/null | sort -u || echo "")
        if [[ -n "$SPEAKERS" ]]; then
            SPEAKER_COUNT=$(echo "$SPEAKERS" | wc -l | tr -d ' ')
            echo -e "${BLUE}Speakers detected: $SPEAKER_COUNT${NC}"

            # Show sample speaker segments
            echo -e "${BLUE}Speaker segments (first 3):${NC}"
            jq -r '.segments[]? | select(.speaker != null) | "\(.speaker): \(.text)"' "$TEMP_RESPONSE" 2>/dev/null | head -3 || true
        fi
    fi

    # Show statistics
    WORD_COUNT=$(jq '[.segments[]? | select(.type == "word")] | length' "$TEMP_RESPONSE" 2>/dev/null || echo "0")
    echo ""
    echo -e "${BLUE}Statistics:${NC}"
    echo "  Words: $WORD_COUNT"
    echo "  File size: $(numfmt --to=iec-i --suffix=B $FILE_SIZE)"

    # Show audio events if tagged
    EVENTS=$(jq -r '[.segments[]? | select(.type == "audio_event")] | length' "$TEMP_RESPONSE" 2>/dev/null || echo "0")
    if [[ $EVENTS -gt 0 ]]; then
        echo "  Audio events: $EVENTS"
        echo -e "${BLUE}Events detected:${NC}"
        jq -r '.segments[]? | select(.type == "audio_event") | "  - \(.text)"' "$TEMP_RESPONSE" 2>/dev/null || true
    fi
fi

# Cleanup
rm -f "$TEMP_RESPONSE"

echo ""
echo -e "${GREEN}✓ Transcription complete${NC}"
