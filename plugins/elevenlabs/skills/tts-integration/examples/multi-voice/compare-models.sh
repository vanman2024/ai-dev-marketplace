#!/usr/bin/env bash
# Compare all ElevenLabs voice models with same text

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

API_KEY="${ELEVENLABS_API_KEY:-}"
VOICE_ID=""
TEXT=""
OUTPUT_DIR="./model-comparison"
MEASURE_PERFORMANCE=false

MODELS=("eleven_v3" "eleven_multilingual_v2" "eleven_flash_v2_5" "eleven_turbo_v2_5")

print_color() {
    echo -e "${1}${2}${NC}"
}

compare_models() {
    mkdir -p "$OUTPUT_DIR"

    print_color "$BLUE" "═══════════════════════════════════════════════════════════════"
    print_color "$GREEN" "Comparing Voice Models"
    print_color "$BLUE" "═══════════════════════════════════════════════════════════════"
    echo "Text: ${TEXT:0:80}$([ ${#TEXT} -gt 80 ] && echo '...')"
    echo "Voice ID: $VOICE_ID"
    echo "Output dir: $OUTPUT_DIR"
    print_color "$BLUE" "═══════════════════════════════════════════════════════════════"
    echo ""

    declare -A timings

    for model in "${MODELS[@]}"; do
        print_color "$YELLOW" "Testing: $model"

        local output="$OUTPUT_DIR/${model}.mp3"
        local start=$(date +%s%N)

        local json_payload=$(jq -n \
            --arg text "$TEXT" \
            --arg model "$model" \
            '{
                text: $text,
                model_id: $model,
                voice_settings: {
                    stability: 0.5,
                    similarity_boost: 0.75,
                    style: 0.0,
                    use_speaker_boost: true
                }
            }')

        local http_code=$(curl -s -w "%{http_code}" \
            -X POST \
            -H "xi-api-key: $API_KEY" \
            -H "Content-Type: application/json" \
            -d "$json_payload" \
            -o "$output" \
            "https://api.elevenlabs.io/v1/text-to-speech/$VOICE_ID?output_format=mp3_44100_128")

        local end=$(date +%s%N)
        local duration_ms=$(( (end - start) / 1000000 ))
        timings[$model]=$duration_ms

        if [[ "$http_code" == "200" ]]; then
            local size=$(du -h "$output" | cut -f1)
            print_color "$GREEN" "  ✓ Success (${duration_ms}ms, ${size})"
        else
            print_color "$RED" "  ✗ Failed (HTTP $http_code)"
        fi

        echo ""
        sleep 0.5
    done

    print_color "$BLUE" "═══════════════════════════════════════════════════════════════"
    print_color "$GREEN" "Comparison Complete"
    print_color "$BLUE" "═══════════════════════════════════════════════════════════════"

    if [[ "$MEASURE_PERFORMANCE" == true ]]; then
        echo ""
        print_color "$YELLOW" "Performance Results:"
        for model in "${MODELS[@]}"; do
            printf "  %-25s %6dms\n" "$model" "${timings[$model]}"
        done
    fi

    echo ""
    echo "Output files:"
    ls -lh "$OUTPUT_DIR"/*.mp3 2>/dev/null || echo "  No files generated"
}

show_usage() {
    cat << EOF
Compare ElevenLabs Voice Models

Usage:
    $(basename "$0") --text "TEXT" --voice-id ID [OPTIONS]

Required:
    --text TEXT            Text to generate with all models
    --voice-id ID         Voice ID to use

Options:
    --output-dir DIR      Output directory (default: ./model-comparison)
    --measure-performance Show generation timing
    --help                Show this help

Example:
    $(basename "$0") \\
      --text "Compare voice model quality" \\
      --voice-id YOUR_VOICE_ID \\
      --measure-performance

EOF
}

main() {
    if [[ $# -eq 0 ]]; then
        show_usage
        exit 0
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --text) TEXT="$2"; shift 2 ;;
            --voice-id) VOICE_ID="$2"; shift 2 ;;
            --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
            --measure-performance) MEASURE_PERFORMANCE=true; shift ;;
            --help) show_usage; exit 0 ;;
            *) print_color "$RED" "Unknown option: $1"; exit 1 ;;
        esac
    done

    if [[ -z "$API_KEY" ]]; then
        print_color "$RED" "Error: ELEVENLABS_API_KEY not set"
        exit 1
    fi

    if [[ -z "$TEXT" || -z "$VOICE_ID" ]]; then
        print_color "$RED" "Error: --text and --voice-id required"
        show_usage
        exit 1
    fi

    compare_models
}

main "$@"
