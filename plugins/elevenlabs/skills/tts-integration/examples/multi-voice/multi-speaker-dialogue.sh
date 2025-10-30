#!/usr/bin/env bash
# Multi-speaker dialogue generator

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

API_KEY="${ELEVENLABS_API_KEY:-}"
SCRIPT_FILE=""
VOICE_A=""
VOICE_B=""
OUTPUT_DIR="./dialogue-output"
MODEL="eleven_turbo_v2_5"

print_color() {
    echo -e "${1}${2}${NC}"
}

generate_line() {
    local text="$1"
    local voice_id="$2"
    local output="$3"

    local json_payload=$(jq -n \
        --arg text "$text" \
        --arg model "$MODEL" \
        '{
            text: $text,
            model_id: $model,
            voice_settings: {
                stability: 0.5,
                similarity_boost: 0.75,
                style: 0.1,
                use_speaker_boost: true
            }
        }')

    curl -s -X POST \
        -H "xi-api-key: $API_KEY" \
        -H "Content-Type: application/json" \
        -d "$json_payload" \
        -o "$output" \
        "https://api.elevenlabs.io/v1/text-to-speech/$voice_id?output_format=mp3_44100_128"
}

process_dialogue() {
    mkdir -p "$OUTPUT_DIR"

    print_color "$BLUE" "Processing dialogue script: $SCRIPT_FILE"
    echo ""

    local line_num=1
    while IFS= read -r line; do
        [[ -z "$line" || "$line" =~ ^# ]] && continue

        if [[ "$line" =~ ^A:\ (.+)$ ]]; then
            local text="${BASH_REMATCH[1]}"
            local output="$OUTPUT_DIR/$(printf '%03d' $line_num)_speaker_a.mp3"
            print_color "$YELLOW" "[$line_num] Speaker A: ${text:0:60}..."
            generate_line "$text" "$VOICE_A" "$output"
            print_color "$GREEN" "  ✓ Generated"
        elif [[ "$line" =~ ^B:\ (.+)$ ]]; then
            local text="${BASH_REMATCH[1]}"
            local output="$OUTPUT_DIR/$(printf '%03d' $line_num)_speaker_b.mp3"
            print_color "$YELLOW" "[$line_num] Speaker B: ${text:0:60}..."
            generate_line "$text" "$VOICE_B" "$output"
            print_color "$GREEN" "  ✓ Generated"
        fi

        line_num=$((line_num + 1))
        sleep 0.5
    done < "$SCRIPT_FILE"

    print_color "$GREEN" "\n✓ Dialogue generation complete"
    echo "Files saved to: $OUTPUT_DIR"
}

show_usage() {
    cat << EOF
Multi-Speaker Dialogue Generator

Usage:
    $(basename "$0") --script FILE --voice-a ID --voice-b ID [OPTIONS]

Required:
    --script FILE         Dialogue script file
    --voice-a ID         Voice ID for speaker A
    --voice-b ID         Voice ID for speaker B

Options:
    --output-dir DIR     Output directory (default: ./dialogue-output)
    --model MODEL        Model to use (default: eleven_turbo_v2_5)
    --help               Show this help

Script Format:
    A: Speaker A's dialogue line
    B: Speaker B's dialogue line
    # Comments are ignored
    Empty lines are ignored

Example Script:
    A: Hello! How are you doing today?
    B: I'm doing great, thanks for asking!
    A: That's wonderful to hear.

Example:
    $(basename "$0") \\
      --script dialogue.txt \\
      --voice-a voice_id_1 \\
      --voice-b voice_id_2

EOF
}

main() {
    if ! command -v jq &> /dev/null; then
        print_color "$RED" "Error: jq required"
        exit 1
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --script) SCRIPT_FILE="$2"; shift 2 ;;
            --voice-a) VOICE_A="$2"; shift 2 ;;
            --voice-b) VOICE_B="$2"; shift 2 ;;
            --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
            --model) MODEL="$2"; shift 2 ;;
            --help) show_usage; exit 0 ;;
            *) print_color "$RED" "Unknown option: $1"; exit 1 ;;
        esac
    done

    if [[ -z "$API_KEY" ]]; then
        print_color "$RED" "Error: ELEVENLABS_API_KEY not set"
        exit 1
    fi

    if [[ -z "$SCRIPT_FILE" || -z "$VOICE_A" || -z "$VOICE_B" ]]; then
        print_color "$RED" "Error: --script, --voice-a, and --voice-b required"
        show_usage
        exit 1
    fi

    if [[ ! -f "$SCRIPT_FILE" ]]; then
        print_color "$RED" "Error: Script file not found: $SCRIPT_FILE"
        exit 1
    fi

    process_dialogue
}

main "$@"
