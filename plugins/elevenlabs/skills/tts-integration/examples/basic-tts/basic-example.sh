#!/usr/bin/env bash
# Basic TTS generation example
# Demonstrates simple text-to-speech with customizable settings

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default values
API_KEY="${ELEVENLABS_API_KEY:-}"
VOICE_ID=""
MODEL="eleven_turbo_v2_5"
TEXT=""
OUTPUT="output.mp3"
OUTPUT_FORMAT="mp3_44100_128"
SETTINGS_FILE=""

# Voice settings
STABILITY="0.5"
SIMILARITY_BOOST="0.75"
STYLE="0.0"
USE_SPEAKER_BOOST="true"

print_color() {
    local color=$1
    shift
    echo -e "${color}$*${NC}"
}

load_settings() {
    local file="$1"
    if [[ -f "$file" ]]; then
        STABILITY=$(jq -r '.stability // .settings.stability // 0.5' "$file")
        SIMILARITY_BOOST=$(jq -r '.similarity_boost // .settings.similarity_boost // 0.75' "$file")
        STYLE=$(jq -r '.style // .settings.style // 0.0' "$file")
        USE_SPEAKER_BOOST=$(jq -r '.use_speaker_boost // .settings.use_speaker_boost // true' "$file")
        print_color "$GREEN" "✓ Loaded settings from $file"
    fi
}

generate_speech() {
    if [[ -z "$API_KEY" ]]; then
        print_color "$RED" "Error: ELEVENLABS_API_KEY not set"
        exit 1
    fi

    if [[ -z "$TEXT" ]]; then
        print_color "$RED" "Error: No text provided"
        exit 1
    fi

    if [[ -z "$VOICE_ID" ]]; then
        print_color "$RED" "Error: No voice ID provided"
        exit 1
    fi

    print_color "$BLUE" "Generating speech..."
    print_color "$YELLOW" "Text: ${TEXT:0:100}$([ ${#TEXT} -gt 100 ] && echo '...')"
    echo "Voice: $VOICE_ID"
    echo "Model: $MODEL"
    echo "Output: $OUTPUT"

    local json_payload=$(jq -n \
        --arg text "$TEXT" \
        --arg model "$MODEL" \
        --arg stability "$STABILITY" \
        --arg similarity "$SIMILARITY_BOOST" \
        --arg style "$STYLE" \
        --argjson speaker_boost "$USE_SPEAKER_BOOST" \
        '{
            text: $text,
            model_id: $model,
            voice_settings: {
                stability: ($stability | tonumber),
                similarity_boost: ($similarity | tonumber),
                style: ($style | tonumber),
                use_speaker_boost: $speaker_boost
            }
        }')

    local start=$(date +%s%N)

    local http_code=$(curl -s -w "%{http_code}" \
        -X POST \
        -H "xi-api-key: $API_KEY" \
        -H "Content-Type: application/json" \
        -d "$json_payload" \
        -o "$OUTPUT" \
        "https://api.elevenlabs.io/v1/text-to-speech/$VOICE_ID?output_format=$OUTPUT_FORMAT")

    local end=$(date +%s%N)
    local duration_ms=$(( (end - start) / 1000000 ))

    if [[ "$http_code" == "200" ]]; then
        print_color "$GREEN" "✓ Success!"
        echo "Generation time: ${duration_ms}ms"

        if [[ -f "$OUTPUT" ]]; then
            local size=$(du -h "$OUTPUT" | cut -f1)
            echo "File size: $size"

            if command -v ffprobe &> /dev/null; then
                local audio_duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$OUTPUT" 2>/dev/null || echo "unknown")
                if [[ "$audio_duration" != "unknown" ]]; then
                    echo "Audio duration: $(printf '%.2f' "$audio_duration")s"
                fi
            fi
        fi
    else
        print_color "$RED" "✗ Failed (HTTP $http_code)"
        if [[ -f "$OUTPUT" ]]; then
            cat "$OUTPUT" | jq -r '.detail.message // .detail // .' 2>/dev/null || cat "$OUTPUT"
            rm -f "$OUTPUT"
        fi
        exit 1
    fi
}

show_usage() {
    cat << EOF
Basic TTS Generation Example

Usage:
    $(basename "$0") --text "TEXT" --voice-id ID [OPTIONS]

Required:
    --text TEXT            Text to convert to speech
    --voice-id ID         Voice ID to use

Options:
    --model MODEL         Model (default: eleven_turbo_v2_5)
    --output FILE         Output file (default: output.mp3)
    --format FORMAT       Output format (default: mp3_44100_128)
    --settings-file FILE  Load settings from JSON file
    --stability VAL       Stability 0.0-1.0 (default: 0.5)
    --similarity-boost VAL Similarity boost 0.0-1.0 (default: 0.75)
    --style VAL           Style 0.0-1.0 (default: 0.0)
    --speaker-boost BOOL  Use speaker boost (default: true)
    --help                Show this help

Examples:
    # Basic usage
    $(basename "$0") --text "Hello world" --voice-id abc123 --output hello.mp3

    # With settings file
    $(basename "$0") --text "Story text" --voice-id abc123 --settings-file audiobook.json

    # Custom settings
    $(basename "$0") --text "Your text" --voice-id abc123 --stability 0.8 --style 0.2

EOF
}

main() {
    if ! command -v jq &> /dev/null; then
        print_color "$RED" "Error: jq is required"
        exit 1
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --text) TEXT="$2"; shift 2 ;;
            --voice-id) VOICE_ID="$2"; shift 2 ;;
            --model) MODEL="$2"; shift 2 ;;
            --output) OUTPUT="$2"; shift 2 ;;
            --format) OUTPUT_FORMAT="$2"; shift 2 ;;
            --settings-file) SETTINGS_FILE="$2"; shift 2 ;;
            --stability) STABILITY="$2"; shift 2 ;;
            --similarity-boost) SIMILARITY_BOOST="$2"; shift 2 ;;
            --style) STYLE="$2"; shift 2 ;;
            --speaker-boost) USE_SPEAKER_BOOST="$2"; shift 2 ;;
            --help) show_usage; exit 0 ;;
            *) print_color "$RED" "Unknown option: $1"; exit 1 ;;
        esac
    done

    if [[ -n "$SETTINGS_FILE" ]]; then
        load_settings "$SETTINGS_FILE"
    fi

    generate_speech
}

main "$@"
