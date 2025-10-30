#!/usr/bin/env bash
# Audio format conversion utility for ElevenLabs TTS outputs
# Supports MP3, PCM, Opus, WAV, and other formats using ffmpeg

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check dependencies
check_dependencies() {
    if ! command -v ffmpeg &> /dev/null; then
        echo -e "${RED}Error: ffmpeg is required but not installed.${NC}"
        echo "Install with: sudo apt-get install ffmpeg (Linux) or brew install ffmpeg (Mac)"
        exit 1
    fi
}

# Print colored output
print_color() {
    local color=$1
    shift
    echo -e "${color}$*${NC}"
}

# Format information
declare -A FORMAT_INFO
FORMAT_INFO["mp3"]="MP3|Lossy compression|Good quality-to-size|Web streaming, general use|22-320 kbps"
FORMAT_INFO["opus"]="Opus|Modern codec|Best quality-to-size|Web streaming, mobile|6-510 kbps"
FORMAT_INFO["pcm"]="PCM|Uncompressed|Highest quality|Professional audio|1411 kbps (CD)"
FORMAT_INFO["wav"]="WAV|Uncompressed|High quality|Professional audio|1411 kbps (CD)"
FORMAT_INFO["aac"]="AAC|Lossy compression|Good quality|Apple devices, streaming|96-320 kbps"
FORMAT_INFO["flac"]="FLAC|Lossless compression|Very high quality|Archival, audiophile|~600-1000 kbps"
FORMAT_INFO["ogg"]="OGG Vorbis|Lossy compression|Good quality|Open source projects|64-320 kbps"
FORMAT_INFO["ulaw"]="μ-law|Telephony codec|Low quality|Phone systems|64 kbps"
FORMAT_INFO["alaw"]="A-law|Telephony codec|Low quality|Phone systems (EU)|64 kbps"

# Show format info
show_format_info() {
    local format=$1
    local info="${FORMAT_INFO[$format]}"
    IFS='|' read -r name type quality use_case bitrate <<< "$info"

    echo ""
    print_color "$BLUE" "═══════════════════════════════════════════════════════════════"
    print_color "$GREEN" "Format: $format"
    print_color "$BLUE" "═══════════════════════════════════════════════════════════════"
    echo "Name:         $name"
    echo "Type:         $type"
    echo "Quality:      $quality"
    echo "Best For:     $use_case"
    echo "Bitrate:      $bitrate"
    print_color "$BLUE" "═══════════════════════════════════════════════════════════════"
    echo ""
}

# Convert single file
convert_file() {
    local input="$1"
    local output="$2"
    local format="$3"
    local bitrate="${4:-128k}"
    local sample_rate="${5:-44100}"

    if [[ ! -f "$input" ]]; then
        print_color "$RED" "Error: Input file not found: $input"
        return 1
    fi

    print_color "$YELLOW" "Converting: $input -> $output"

    case "$format" in
        mp3)
            ffmpeg -i "$input" -codec:a libmp3lame -b:a "$bitrate" -ar "$sample_rate" "$output" -y -loglevel error
            ;;
        opus)
            ffmpeg -i "$input" -codec:a libopus -b:a "$bitrate" -ar "$sample_rate" "$output" -y -loglevel error
            ;;
        pcm|wav)
            ffmpeg -i "$input" -codec:a pcm_s16le -ar "$sample_rate" "$output" -y -loglevel error
            ;;
        aac)
            ffmpeg -i "$input" -codec:a aac -b:a "$bitrate" -ar "$sample_rate" "$output" -y -loglevel error
            ;;
        flac)
            ffmpeg -i "$input" -codec:a flac -ar "$sample_rate" "$output" -y -loglevel error
            ;;
        ogg)
            ffmpeg -i "$input" -codec:a libvorbis -b:a "$bitrate" -ar "$sample_rate" "$output" -y -loglevel error
            ;;
        ulaw)
            ffmpeg -i "$input" -codec:a pcm_mulaw -ar 8000 "$output" -y -loglevel error
            ;;
        alaw)
            ffmpeg -i "$input" -codec:a pcm_alaw -ar 8000 "$output" -y -loglevel error
            ;;
        *)
            print_color "$RED" "Error: Unsupported format: $format"
            return 1
            ;;
    esac

    if [[ $? -eq 0 ]]; then
        print_color "$GREEN" "✓ Successfully converted to $format"

        # Show file sizes
        local input_size=$(du -h "$input" | cut -f1)
        local output_size=$(du -h "$output" | cut -f1)
        echo "  Input size:  $input_size"
        echo "  Output size: $output_size"
    else
        print_color "$RED" "✗ Conversion failed"
        return 1
    fi
}

# Batch conversion
batch_convert() {
    local pattern="$1"
    local format="$2"
    local output_dir="$3"
    local bitrate="${4:-128k}"

    mkdir -p "$output_dir"

    local count=0
    local success=0
    local failed=0

    for input in $pattern; do
        if [[ ! -f "$input" ]]; then
            continue
        fi

        count=$((count + 1))
        local basename=$(basename "$input")
        local filename="${basename%.*}"
        local output="$output_dir/${filename}.${format}"

        if convert_file "$input" "$output" "$format" "$bitrate"; then
            success=$((success + 1))
        else
            failed=$((failed + 1))
        fi
    done

    echo ""
    print_color "$BLUE" "═══════════════════════════════════════════════════════════════"
    print_color "$GREEN" "Batch Conversion Complete"
    print_color "$BLUE" "═══════════════════════════════════════════════════════════════"
    echo "Total files:      $count"
    echo "Successful:       $success"
    echo "Failed:          $failed"
    echo "Output directory: $output_dir"
    print_color "$BLUE" "═══════════════════════════════════════════════════════════════"
}

# Get audio info
get_audio_info() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        print_color "$RED" "Error: File not found: $file"
        return 1
    fi

    print_color "$BLUE" "═══════════════════════════════════════════════════════════════"
    print_color "$GREEN" "Audio File Information: $(basename "$file")"
    print_color "$BLUE" "═══════════════════════════════════════════════════════════════"

    ffprobe -v error -show_entries format=duration,size,bit_rate,format_name \
            -show_entries stream=codec_name,sample_rate,channels,bit_rate \
            -of default=noprint_wrappers=1 "$file" 2>/dev/null | while IFS='=' read -r key value; do
        case "$key" in
            duration)
                local mins=$((${value%.*} / 60))
                local secs=$((${value%.*} % 60))
                echo "Duration:     ${mins}m ${secs}s"
                ;;
            size)
                local size_mb=$(echo "scale=2; $value / 1024 / 1024" | bc)
                echo "File Size:    ${size_mb} MB"
                ;;
            bit_rate)
                local kbps=$(echo "scale=0; $value / 1000" | bc)
                echo "Bitrate:      ${kbps} kbps"
                ;;
            format_name)
                echo "Format:       $value"
                ;;
            codec_name)
                echo "Codec:        $value"
                ;;
            sample_rate)
                local khz=$(echo "scale=1; $value / 1000" | bc)
                echo "Sample Rate:  ${khz} kHz"
                ;;
            channels)
                echo "Channels:     $value"
                ;;
        esac
    done

    print_color "$BLUE" "═══════════════════════════════════════════════════════════════"
}

# Show usage
show_usage() {
    cat << EOF
Audio Format Conversion Utility for ElevenLabs TTS

Usage:
    $(basename "$0") INPUT [OPTIONS]

Single File Conversion:
    $(basename "$0") input.mp3 --to-opus
    $(basename "$0") input.mp3 --to-mp3 --bitrate 192k
    $(basename "$0") input.mp3 --to-pcm --sample-rate 48000

Batch Conversion:
    $(basename "$0") "*.mp3" --to-opus --output-dir ./converted/
    $(basename "$0") "audio/*.mp3" --to-aac --bitrate 256k --output-dir ./aac/

Options:
    --to-FORMAT               Target format (mp3|opus|pcm|wav|aac|flac|ogg|ulaw|alaw)
    --bitrate BITRATE        Audio bitrate (e.g., 128k, 192k, 256k)
    --sample-rate RATE       Sample rate in Hz (e.g., 44100, 48000)
    --output FILE            Output file path (single file mode)
    --output-dir DIR         Output directory (batch mode)
    --info                   Show audio file information
    --format-info FORMAT     Show information about a format
    --list-formats          List all supported formats
    --help                   Show this help message

Supported Formats:
    mp3     - MP3 (lossy, good compression)
    opus    - Opus (modern, best quality-to-size)
    pcm     - PCM/WAV (uncompressed, highest quality)
    wav     - WAV (uncompressed)
    aac     - AAC (lossy, Apple devices)
    flac    - FLAC (lossless compression)
    ogg     - OGG Vorbis (lossy, open source)
    ulaw    - μ-law (telephony)
    alaw    - A-law (telephony, EU)

Examples:
    # Convert to Opus for web streaming
    $(basename "$0") audio.mp3 --to-opus --bitrate 96k

    # Convert to high-quality MP3
    $(basename "$0") audio.wav --to-mp3 --bitrate 320k

    # Convert all MP3s to Opus
    $(basename "$0") "*.mp3" --to-opus --output-dir opus/

    # Get file information
    $(basename "$0") audio.mp3 --info

    # Get format information
    $(basename "$0") --format-info opus

Recommended Settings:
    Web streaming:     --to-opus --bitrate 96k
    High quality:      --to-mp3 --bitrate 192k
    Archival:          --to-flac
    Telephony:         --to-ulaw
    Mobile apps:       --to-opus --bitrate 64k

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
    local input=""
    local output=""
    local format=""
    local bitrate="128k"
    local sample_rate="44100"
    local output_dir=""
    local show_info=false
    local batch_mode=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --to-*)
                format="${1#--to-}"
                shift
                ;;
            --bitrate)
                bitrate="$2"
                shift 2
                ;;
            --sample-rate)
                sample_rate="$2"
                shift 2
                ;;
            --output)
                output="$2"
                shift 2
                ;;
            --output-dir)
                output_dir="$2"
                batch_mode=true
                shift 2
                ;;
            --info)
                show_info=true
                shift
                ;;
            --format-info)
                if [[ -z "${FORMAT_INFO[$2]:-}" ]]; then
                    print_color "$RED" "Error: Unknown format: $2"
                    exit 1
                fi
                show_format_info "$2"
                exit 0
                ;;
            --list-formats)
                print_color "$BLUE" "Supported Formats:"
                for fmt in "${!FORMAT_INFO[@]}"; do
                    echo "  - $fmt"
                done
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
                input="$1"
                shift
                ;;
        esac
    done

    # Validate input
    if [[ -z "$input" ]]; then
        print_color "$RED" "Error: No input file specified"
        show_usage
        exit 1
    fi

    # Handle info mode
    if [[ "$show_info" == true ]]; then
        get_audio_info "$input"
        exit 0
    fi

    # Validate format
    if [[ -z "$format" ]]; then
        print_color "$RED" "Error: No output format specified (use --to-FORMAT)"
        exit 1
    fi

    # Batch or single file mode
    if [[ "$batch_mode" == true || "$input" == *"*"* ]]; then
        if [[ -z "$output_dir" ]]; then
            output_dir="./converted"
        fi
        batch_convert "$input" "$format" "$output_dir" "$bitrate"
    else
        if [[ -z "$output" ]]; then
            local basename=$(basename "$input")
            local filename="${basename%.*}"
            output="${filename}.${format}"
        fi
        convert_file "$input" "$output" "$format" "$bitrate" "$sample_rate"
    fi
}

main "$@"
