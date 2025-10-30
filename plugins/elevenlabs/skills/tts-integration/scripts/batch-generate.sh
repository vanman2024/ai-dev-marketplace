#!/usr/bin/env bash
# Batch TTS generation for ElevenLabs
# Process multiple texts with progress tracking and error handling

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
OUTPUT_DIR="./audio-output"
OUTPUT_FORMAT="mp3_44100_128"
SETTINGS_FILE=""
MAX_RETRIES=3
RETRY_DELAY=2
PARALLEL_JOBS=1

# Voice settings defaults
STABILITY="0.5"
SIMILARITY_BOOST="0.75"
STYLE="0.0"
USE_SPEAKER_BOOST="true"

# Statistics
TOTAL_COUNT=0
SUCCESS_COUNT=0
FAILED_COUNT=0
SKIPPED_COUNT=0

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

# Load settings from file
load_settings() {
    local settings_file="$1"

    if [[ ! -f "$settings_file" ]]; then
        print_color "$RED" "Error: Settings file not found: $settings_file"
        exit 1
    fi

    STABILITY=$(jq -r '.stability // 0.5' "$settings_file")
    SIMILARITY_BOOST=$(jq -r '.similarity_boost // 0.75' "$settings_file")
    STYLE=$(jq -r '.style // 0.0' "$settings_file")
    USE_SPEAKER_BOOST=$(jq -r '.use_speaker_boost // true' "$settings_file")

    print_color "$GREEN" "✓ Loaded settings from $settings_file"
}

# Generate filename from text
generate_filename() {
    local text="$1"
    local index="$2"

    # Create safe filename from text (first 50 chars, replace special chars)
    local safe_name=$(echo "$text" | head -c 50 | tr -cs '[:alnum:]' '_' | tr '[:upper:]' '[:lower:]')
    safe_name="${safe_name%_}"  # Remove trailing underscore

    # Pad index with zeros
    local padded_index=$(printf "%04d" "$index")

    echo "${padded_index}_${safe_name}"
}

# Generate single speech with retry
generate_with_retry() {
    local text="$1"
    local output_file="$2"
    local attempt=1

    while [[ $attempt -le $MAX_RETRIES ]]; do
        local json_payload=$(jq -n \
            --arg text "$text" \
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

        local response=$(curl -s -w "\n%{http_code}" \
            -X POST \
            -H "xi-api-key: $API_KEY" \
            -H "Content-Type: application/json" \
            -d "$json_payload" \
            --output "$output_file" \
            "https://api.elevenlabs.io/v1/text-to-speech/$VOICE_ID?output_format=$OUTPUT_FORMAT")

        local http_code=$(echo "$response" | tail -n1)

        if [[ "$http_code" == "200" ]]; then
            return 0
        else
            if [[ $attempt -lt $MAX_RETRIES ]]; then
                print_color "$YELLOW" "  Retry $attempt/$MAX_RETRIES after ${RETRY_DELAY}s..."
                sleep "$RETRY_DELAY"
                attempt=$((attempt + 1))
            else
                # Extract error message
                if [[ -f "$output_file" ]]; then
                    local error=$(cat "$output_file" | jq -r '.detail.message // .detail // "Unknown error"' 2>/dev/null || echo "Unknown error")
                    print_color "$RED" "  Error: $error"
                    rm -f "$output_file"
                fi
                return 1
            fi
        fi
    done

    return 1
}

# Process batch file
process_batch() {
    local input_file="$1"

    if [[ ! -f "$input_file" ]]; then
        print_color "$RED" "Error: Input file not found: $input_file"
        exit 1
    fi

    # Create output directory
    mkdir -p "$OUTPUT_DIR"

    # Count total lines
    TOTAL_COUNT=$(grep -c . "$input_file" || echo 0)

    if [[ $TOTAL_COUNT -eq 0 ]]; then
        print_color "$RED" "Error: Input file is empty"
        exit 1
    fi

    print_color "$BLUE" "═══════════════════════════════════════════════════════════════"
    print_color "$GREEN" "Starting Batch Generation"
    print_color "$BLUE" "═══════════════════════════════════════════════════════════════"
    echo "Input file:    $input_file"
    echo "Output dir:    $OUTPUT_DIR"
    echo "Voice ID:      $VOICE_ID"
    echo "Model:         $MODEL"
    echo "Format:        $OUTPUT_FORMAT"
    echo "Total items:   $TOTAL_COUNT"
    print_color "$BLUE" "═══════════════════════════════════════════════════════════════"
    echo ""

    local index=1
    local start_time=$(date +%s)

    while IFS= read -r line; do
        # Skip empty lines
        if [[ -z "$line" ]]; then
            SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
            continue
        fi

        # Generate filename
        local filename=$(generate_filename "$line" "$index")
        local extension="${OUTPUT_FORMAT%%_*}"  # Extract format (mp3, pcm, etc.)
        local output_file="$OUTPUT_DIR/${filename}.${extension}"

        # Skip if file already exists
        if [[ -f "$output_file" ]]; then
            print_color "$YELLOW" "[$index/$TOTAL_COUNT] Skipping (exists): ${filename}.${extension}"
            SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
            index=$((index + 1))
            continue
        fi

        # Generate speech
        print_color "$BLUE" "[$index/$TOTAL_COUNT] Generating: ${filename}.${extension}"
        echo "  Text: ${line:0:80}$([ ${#line} -gt 80 ] && echo '...')"

        if generate_with_retry "$line" "$output_file"; then
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
            local file_size=$(du -h "$output_file" | cut -f1)
            print_color "$GREEN" "  ✓ Success (${file_size})"
        else
            FAILED_COUNT=$((FAILED_COUNT + 1))
            print_color "$RED" "  ✗ Failed"
        fi

        echo ""
        index=$((index + 1))

        # Small delay to avoid rate limiting
        sleep 0.5
    done < "$input_file"

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    # Print summary
    print_color "$BLUE" "═══════════════════════════════════════════════════════════════"
    print_color "$GREEN" "Batch Generation Complete"
    print_color "$BLUE" "═══════════════════════════════════════════════════════════════"
    echo "Total items:   $TOTAL_COUNT"
    echo "Successful:    $SUCCESS_COUNT"
    echo "Failed:        $FAILED_COUNT"
    echo "Skipped:       $SKIPPED_COUNT"
    echo "Duration:      ${duration}s"
    echo "Output dir:    $OUTPUT_DIR"
    print_color "$BLUE" "═══════════════════════════════════════════════════════════════"

    if [[ $FAILED_COUNT -gt 0 ]]; then
        echo ""
        print_color "$YELLOW" "Warning: $FAILED_COUNT items failed. Check errors above."
    fi
}

# Create sample input file
create_sample() {
    local output_file="${1:-sample-input.txt}"

    cat > "$output_file" << 'EOF'
Welcome to ElevenLabs text-to-speech generation.
This is a sample batch processing file.
Each line will be converted to a separate audio file.
You can add as many lines as you need.
Empty lines will be skipped automatically.
EOF

    print_color "$GREEN" "✓ Sample input file created: $output_file"
    print_color "$YELLOW" "Edit this file and add your texts (one per line), then run:"
    echo "  $(basename "$0") $output_file --voice-id <VOICE_ID>"
}

# Show usage
show_usage() {
    cat << EOF
Batch TTS Generation for ElevenLabs

Usage:
    $(basename "$0") INPUT_FILE --voice-id VOICE_ID [OPTIONS]

Required:
    INPUT_FILE              Text file with one phrase per line
    --voice-id ID          Voice ID to use

Options:
    --model MODEL          Model to use (default: eleven_turbo_v2_5)
    --output-dir DIR       Output directory (default: ./audio-output)
    --format FORMAT        Output format (default: mp3_44100_128)
    --settings-file FILE   JSON file with voice settings
    --max-retries N        Max retry attempts (default: 3)
    --retry-delay N        Delay between retries in seconds (default: 2)
    --create-sample [FILE] Create sample input file
    --help                 Show this help message

Voice Settings (if --settings-file not provided):
    --stability VALUE      Stability (0.0-1.0, default: 0.5)
    --similarity-boost VAL Similarity boost (0.0-1.0, default: 0.75)
    --style VALUE          Style (0.0-1.0, default: 0.0)
    --speaker-boost BOOL   Use speaker boost (true/false, default: true)

Available Models:
    eleven_v3               - Most emotionally expressive (Alpha)
    eleven_multilingual_v2  - Quality & consistency
    eleven_flash_v2_5       - Ultra-low latency (recommended for bulk)
    eleven_turbo_v2_5       - Balanced quality & speed

Output Formats:
    mp3_44100_128   - MP3, 44.1kHz, 128kbps (default)
    mp3_44100_192   - MP3, 44.1kHz, 192kbps
    opus_44100_128  - Opus, 44.1kHz, 128kbps
    pcm_44100       - PCM, 44.1kHz (CD quality)

Examples:
    # Create sample input file
    $(basename "$0") --create-sample my-texts.txt

    # Basic batch generation
    $(basename "$0") texts.txt --voice-id pNInz6obpgDQGcFmaJgB

    # With specific model and output directory
    $(basename "$0") texts.txt \\
        --voice-id pNInz6obpgDQGcFmaJgB \\
        --model eleven_flash_v2_5 \\
        --output-dir ./generated-audio/

    # Using settings file
    $(basename "$0") texts.txt \\
        --voice-id pNInz6obpgDQGcFmaJgB \\
        --settings-file audiobook-settings.json \\
        --output-dir ./audiobook/

    # Custom voice settings
    $(basename "$0") texts.txt \\
        --voice-id pNInz6obpgDQGcFmaJgB \\
        --stability 0.8 \\
        --similarity-boost 0.75 \\
        --output-dir ./narration/

Input File Format:
    - One text phrase per line
    - Empty lines are skipped
    - UTF-8 encoding recommended
    - Lines can be any length (respecting model limits)

Output Files:
    - Named: NNNN_first_50_chars_of_text.ext
    - NNNN = zero-padded index (0001, 0002, etc.)
    - Existing files are skipped automatically

Features:
    - Automatic retry on API failures
    - Progress tracking with colored output
    - Existing files are skipped
    - Detailed statistics summary
    - Safe filename generation

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

    local input_file=""

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
            --output-dir)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            --format)
                OUTPUT_FORMAT="$2"
                shift 2
                ;;
            --settings-file)
                SETTINGS_FILE="$2"
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
            --max-retries)
                MAX_RETRIES="$2"
                shift 2
                ;;
            --retry-delay)
                RETRY_DELAY="$2"
                shift 2
                ;;
            --create-sample)
                if [[ -n "${2:-}" && ! "$2" =~ ^-- ]]; then
                    create_sample "$2"
                    shift 2
                else
                    create_sample
                    shift
                fi
                exit 0
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
                input_file="$1"
                shift
                ;;
        esac
    done

    # Validate required parameters
    validate_api_key

    if [[ -z "$input_file" ]]; then
        print_color "$RED" "Error: No input file provided"
        show_usage
        exit 1
    fi

    if [[ -z "$VOICE_ID" ]]; then
        print_color "$RED" "Error: --voice-id is required"
        show_usage
        exit 1
    fi

    # Load settings file if provided
    if [[ -n "$SETTINGS_FILE" ]]; then
        load_settings "$SETTINGS_FILE"
    fi

    # Process batch
    process_batch "$input_file"
}

main "$@"
