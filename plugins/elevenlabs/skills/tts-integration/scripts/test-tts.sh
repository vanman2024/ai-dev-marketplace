#!/usr/bin/env bash
# Test TTS with ElevenLabs API
# Validates API connectivity, voice models, and settings

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
API_KEY="${ELEVENLABS_API_KEY:-}"
VOICE_ID=""
MODEL="eleven_turbo_v2_5"
TEXT=""
OUTPUT="test-output.mp3"
STABILITY="0.5"
SIMILARITY_BOOST="0.75"
STYLE="0.0"
USE_SPEAKER_BOOST="true"
OUTPUT_FORMAT="mp3_44100_128"
COMPARE_MODELS=false

# Print colored output
print_color() {
    local color=$1
    shift
    echo -e "${color}$*${NC}"
}

# Check dependencies
check_dependencies() {
    if ! command -v curl &> /dev/null; then
        print_color "$RED" "Error: curl is required but not installed."
        exit 1
    fi

    if ! command -v jq &> /dev/null; then
        print_color "$RED" "Error: jq is required but not installed."
        echo "Install with: sudo apt-get install jq (Linux) or brew install jq (Mac)"
        exit 1
    fi
}

# Validate API key
validate_api_key() {
    if [[ -z "$API_KEY" ]]; then
        print_color "$RED" "Error: ELEVENLABS_API_KEY not set"
        echo "Set it with: export ELEVENLABS_API_KEY='your-api-key'"
        exit 1
    fi
}

# Test API connectivity
test_connectivity() {
    print_color "$YELLOW" "Testing API connectivity..."

    local response=$(curl -s -w "\n%{http_code}" \
        -H "xi-api-key: $API_KEY" \
        "https://api.elevenlabs.io/v1/user")

    local http_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | head -n-1)

    if [[ "$http_code" == "200" ]]; then
        print_color "$GREEN" "✓ API connection successful"
        local subscription=$(echo "$body" | jq -r '.subscription.tier // "unknown"')
        local character_count=$(echo "$body" | jq -r '.subscription.character_count // 0')
        local character_limit=$(echo "$body" | jq -r '.subscription.character_limit // 0')
        echo "  Subscription: $subscription"
        echo "  Characters used: $character_count / $character_limit"
        return 0
    else
        print_color "$RED" "✗ API connection failed (HTTP $http_code)"
        echo "$body" | jq -r '.detail.message // .detail // .' 2>/dev/null || echo "$body"
        return 1
    fi
}

# Get available voices
list_voices() {
    print_color "$YELLOW" "Fetching available voices..."

    local response=$(curl -s -w "\n%{http_code}" \
        -H "xi-api-key: $API_KEY" \
        "https://api.elevenlabs.io/v1/voices")

    local http_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | head -n-1)

    if [[ "$http_code" == "200" ]]; then
        print_color "$GREEN" "✓ Available voices:"
        echo "$body" | jq -r '.voices[] | "  - \(.voice_id): \(.name) (\(.category // "unknown"))"' | head -n 10
        echo ""
        local total=$(echo "$body" | jq -r '.voices | length')
        echo "  Total voices: $total (showing first 10)"
        return 0
    else
        print_color "$RED" "✗ Failed to fetch voices (HTTP $http_code)"
        return 1
    fi
}

# Generate speech
generate_speech() {
    local text="$1"
    local voice_id="$2"
    local model="$3"
    local output_file="$4"

    print_color "$YELLOW" "Generating speech..."
    print_color "$BLUE" "  Text: $text"
    print_color "$BLUE" "  Voice: $voice_id"
    print_color "$BLUE" "  Model: $model"

    local json_payload=$(jq -n \
        --arg text "$text" \
        --arg model "$model" \
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

    local start_time=$(date +%s%N)

    local response=$(curl -s -w "\n%{http_code}" \
        -X POST \
        -H "xi-api-key: $API_KEY" \
        -H "Content-Type: application/json" \
        -d "$json_payload" \
        --output "$output_file" \
        "https://api.elevenlabs.io/v1/text-to-speech/$voice_id?output_format=$OUTPUT_FORMAT")

    local end_time=$(date +%s%N)
    local duration_ms=$(( (end_time - start_time) / 1000000 ))

    local http_code=$(echo "$response" | tail -n1)

    if [[ "$http_code" == "200" ]]; then
        print_color "$GREEN" "✓ Speech generated successfully"
        echo "  Output file: $output_file"
        echo "  Generation time: ${duration_ms}ms"

        if [[ -f "$output_file" ]]; then
            local file_size=$(du -h "$output_file" | cut -f1)
            echo "  File size: $file_size"

            # Try to get audio duration
            if command -v ffprobe &> /dev/null; then
                local audio_duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$output_file" 2>/dev/null || echo "unknown")
                if [[ "$audio_duration" != "unknown" ]]; then
                    local duration_secs=$(printf "%.2f" "$audio_duration")
                    echo "  Audio duration: ${duration_secs}s"
                fi
            fi
        fi
        return 0
    else
        print_color "$RED" "✗ Speech generation failed (HTTP $http_code)"

        # Try to parse error from file
        if [[ -f "$output_file" ]]; then
            local error=$(cat "$output_file" | jq -r '.detail.message // .detail // .' 2>/dev/null || cat "$output_file")
            echo "  Error: $error"
            rm -f "$output_file"
        fi
        return 1
    fi
}

# Compare all models
compare_all_models() {
    local text="$1"
    local voice_id="$2"

    print_color "$BLUE" "═══════════════════════════════════════════════════════════════"
    print_color "$GREEN" "Comparing All Voice Models"
    print_color "$BLUE" "═══════════════════════════════════════════════════════════════"
    echo ""

    local models=("eleven_v3" "eleven_multilingual_v2" "eleven_flash_v2_5" "eleven_turbo_v2_5")
    local success_count=0
    local total=${#models[@]}

    for model in "${models[@]}"; do
        echo ""
        print_color "$YELLOW" "Testing model: $model"
        echo "───────────────────────────────────────────────────────────────"

        local output="compare-${model}.mp3"

        if generate_speech "$text" "$voice_id" "$model" "$output"; then
            success_count=$((success_count + 1))
        fi
    done

    echo ""
    print_color "$BLUE" "═══════════════════════════════════════════════════════════════"
    print_color "$GREEN" "Comparison Complete"
    print_color "$BLUE" "═══════════════════════════════════════════════════════════════"
    echo "Successful: $success_count / $total"
    echo ""
    echo "Output files:"
    for model in "${models[@]}"; do
        local output="compare-${model}.mp3"
        if [[ -f "$output" ]]; then
            echo "  - $output"
        fi
    done
    echo ""
}

# Show usage
show_usage() {
    cat << EOF
ElevenLabs TTS Testing Tool

Usage:
    $(basename "$0") "TEXT" --voice-id VOICE_ID [OPTIONS]

Required:
    TEXT                    Text to convert to speech
    --voice-id ID          Voice ID to use

Options:
    --model MODEL          Model to use (default: eleven_turbo_v2_5)
    --output FILE          Output file path (default: test-output.mp3)
    --stability VALUE      Stability (0.0-1.0, default: 0.5)
    --similarity-boost VAL Similarity boost (0.0-1.0, default: 0.75)
    --style VALUE          Style (0.0-1.0, default: 0.0)
    --speaker-boost BOOL   Use speaker boost (true/false, default: true)
    --format FORMAT        Output format (default: mp3_44100_128)
    --compare-models       Generate with all models for comparison
    --list-voices         List available voices
    --test-connection     Test API connectivity only
    --help                Show this help message

Available Models:
    eleven_v3               - Most emotionally expressive (Alpha)
    eleven_multilingual_v2  - Quality & consistency
    eleven_flash_v2_5       - Ultra-low latency
    eleven_turbo_v2_5       - Balanced quality & speed

Output Formats:
    mp3_44100_128   - MP3, 44.1kHz, 128kbps (default)
    mp3_44100_192   - MP3, 44.1kHz, 192kbps
    pcm_16000       - PCM, 16kHz
    pcm_22050       - PCM, 22.05kHz
    pcm_24000       - PCM, 24kHz
    pcm_44100       - PCM, 44.1kHz (CD quality)

Examples:
    # Basic test
    $(basename "$0") "Hello world" --voice-id pNInz6obpgDQGcFmaJgB

    # Test with specific model
    $(basename "$0") "Hello world" --voice-id pNInz6obpgDQGcFmaJgB --model eleven_flash_v2_5

    # Test with custom settings
    $(basename "$0") "Hello world" \\
        --voice-id pNInz6obpgDQGcFmaJgB \\
        --stability 0.7 \\
        --similarity-boost 0.8 \\
        --output custom-output.mp3

    # Compare all models
    $(basename "$0") "Compare voice quality" --voice-id pNInz6obpgDQGcFmaJgB --compare-models

    # Test connectivity
    $(basename "$0") --test-connection

    # List available voices
    $(basename "$0") --list-voices

Environment Variables:
    ELEVENLABS_API_KEY     Your ElevenLabs API key (required)

EOF
}

# Main script logic
main() {
    check_dependencies

    if [[ $# -eq 0 ]]; then
        show_usage
        exit 0
    fi

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --voice-id)
                VOICE_ID="$2"
                shift 2
                ;;
            --model)
                MODEL="$2"
                shift 2
                ;;
            --output)
                OUTPUT="$2"
                shift 2
                ;;
            --stability)
                STABILITY="$2"
                shift 2
                ;;
            --similarity-boost)
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
            --format)
                OUTPUT_FORMAT="$2"
                shift 2
                ;;
            --compare-models)
                COMPARE_MODELS=true
                shift
                ;;
            --list-voices)
                validate_api_key
                list_voices
                exit 0
                ;;
            --test-connection)
                validate_api_key
                test_connectivity
                exit $?
                ;;
            --help)
                show_usage
                exit 0
                ;;
            -*)
                print_color "$RED" "Error: Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                TEXT="$1"
                shift
                ;;
        esac
    done

    # Validate required parameters
    validate_api_key

    if [[ -z "$TEXT" ]]; then
        print_color "$RED" "Error: No text provided"
        show_usage
        exit 1
    fi

    if [[ -z "$VOICE_ID" ]]; then
        print_color "$RED" "Error: --voice-id is required"
        show_usage
        exit 1
    fi

    # Test connection first
    if ! test_connectivity; then
        exit 1
    fi

    echo ""

    # Generate speech or compare models
    if [[ "$COMPARE_MODELS" == true ]]; then
        compare_all_models "$TEXT" "$VOICE_ID"
    else
        generate_speech "$TEXT" "$VOICE_ID" "$MODEL" "$OUTPUT"
    fi
}

main "$@"
