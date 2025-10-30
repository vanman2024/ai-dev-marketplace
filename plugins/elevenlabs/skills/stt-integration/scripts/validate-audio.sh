#!/usr/bin/env bash
set -euo pipefail

#############################################################
# Audio File Validation Script
#############################################################
# Usage: ./validate-audio.sh <audio_file> [--fix] [--verbose]
#
# Validates audio files for ElevenLabs STT compatibility:
#   - File exists and is readable
#   - File format is supported
#   - File size is within limits (max 3 GB)
#   - Duration is within limits (max 10 hours)
#   - Audio properties (if ffmpeg/ffprobe available)
#
# Options:
#   --fix      Attempt to fix issues (convert format, compress, etc.)
#   --verbose  Show detailed audio information
#############################################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Options
FIX_ISSUES="false"
VERBOSE="false"
AUDIO_FILE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --fix)
            FIX_ISSUES="true"
            shift
            ;;
        --verbose)
            VERBOSE="true"
            shift
            ;;
        -*)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
        *)
            AUDIO_FILE="$1"
            shift
            ;;
    esac
done

# Validate audio file argument
if [[ -z "$AUDIO_FILE" ]]; then
    echo -e "${RED}Error: Audio file path required${NC}"
    echo "Usage: $0 <audio_file> [--fix] [--verbose]"
    exit 1
fi

# Validation counters
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0

# Helper functions
check_pass() {
    echo -e "${GREEN}✓ $1${NC}"
    ((CHECKS_PASSED++))
}

check_fail() {
    echo -e "${RED}✗ $1${NC}"
    ((CHECKS_FAILED++))
}

check_warn() {
    echo -e "${YELLOW}⚠ $1${NC}"
    ((CHECKS_WARNING++))
}

# Start validation
echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Audio File Validation                         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}File: $AUDIO_FILE${NC}"
echo ""

#############################################################
# Check 1: File Exists
#############################################################
if [[ ! -e "$AUDIO_FILE" ]]; then
    check_fail "File does not exist"
    exit 1
fi
check_pass "File exists"

#############################################################
# Check 2: File is Readable
#############################################################
if [[ ! -r "$AUDIO_FILE" ]]; then
    check_fail "File is not readable"
    echo -e "${YELLOW}  Fix with: chmod +r \"$AUDIO_FILE\"${NC}"
    exit 1
fi
check_pass "File is readable"

#############################################################
# Check 3: File is Not Empty
#############################################################
if [[ ! -s "$AUDIO_FILE" ]]; then
    check_fail "File is empty (0 bytes)"
    exit 1
fi
check_pass "File is not empty"

#############################################################
# Check 4: File Format
#############################################################
FILENAME=$(basename "$AUDIO_FILE")
EXTENSION="${FILENAME##*.}"
EXTENSION_LOWER=$(echo "$EXTENSION" | tr '[:upper:]' '[:lower:]')

# Supported formats
SUPPORTED_AUDIO="aac aiff ogg mp3 opus wav webm flac m4a"
SUPPORTED_VIDEO="mp4 avi mkv mov wmv flv mpeg 3gp"
ALL_SUPPORTED="$SUPPORTED_AUDIO $SUPPORTED_VIDEO"

if [[ " $ALL_SUPPORTED " =~ " $EXTENSION_LOWER " ]]; then
    check_pass "Format .$EXTENSION_LOWER is supported"

    # Determine if audio or video
    if [[ " $SUPPORTED_AUDIO " =~ " $EXTENSION_LOWER " ]]; then
        FILE_TYPE="audio"
    else
        FILE_TYPE="video"
    fi
else
    check_fail "Format .$EXTENSION_LOWER may not be supported"
    echo -e "${YELLOW}  Supported audio: $SUPPORTED_AUDIO${NC}"
    echo -e "${YELLOW}  Supported video: $SUPPORTED_VIDEO${NC}"

    if [[ "$FIX_ISSUES" == "true" ]] && command -v ffmpeg &> /dev/null; then
        echo -e "${BLUE}  Attempting to convert to MP3...${NC}"
        OUTPUT_FILE="${AUDIO_FILE%.*}.mp3"
        if ffmpeg -i "$AUDIO_FILE" -acodec libmp3lame -b:a 192k "$OUTPUT_FILE" -y 2>/dev/null; then
            check_pass "Converted to MP3: $OUTPUT_FILE"
            AUDIO_FILE="$OUTPUT_FILE"
            EXTENSION_LOWER="mp3"
        else
            check_fail "Conversion failed"
        fi
    fi
fi

#############################################################
# Check 5: File Size (Max 3 GB)
#############################################################
FILE_SIZE=$(stat -f%z "$AUDIO_FILE" 2>/dev/null || stat -c%s "$AUDIO_FILE" 2>/dev/null)
MAX_SIZE=$((3 * 1024 * 1024 * 1024)) # 3 GB in bytes

# Format file size for display
if command -v numfmt &> /dev/null; then
    FILE_SIZE_HUMAN=$(numfmt --to=iec-i --suffix=B $FILE_SIZE)
else
    FILE_SIZE_HUMAN="$FILE_SIZE bytes"
fi

echo -e "${BLUE}File size: $FILE_SIZE_HUMAN${NC}"

if [[ $FILE_SIZE -gt $MAX_SIZE ]]; then
    check_fail "File exceeds 3 GB limit"

    if [[ "$FIX_ISSUES" == "true" ]] && command -v ffmpeg &> /dev/null; then
        echo -e "${BLUE}  Attempting to compress...${NC}"
        OUTPUT_FILE="${AUDIO_FILE%.*}_compressed.$EXTENSION_LOWER"

        # Compress audio with lower bitrate
        if [[ "$FILE_TYPE" == "audio" ]]; then
            ffmpeg -i "$AUDIO_FILE" -acodec libmp3lame -b:a 128k "$OUTPUT_FILE" -y 2>/dev/null
        else
            ffmpeg -i "$AUDIO_FILE" -vn -acodec libmp3lame -b:a 128k "$OUTPUT_FILE" -y 2>/dev/null
        fi

        NEW_SIZE=$(stat -f%z "$OUTPUT_FILE" 2>/dev/null || stat -c%s "$OUTPUT_FILE" 2>/dev/null)
        if [[ $NEW_SIZE -le $MAX_SIZE ]]; then
            check_pass "Compressed to $(numfmt --to=iec-i --suffix=B $NEW_SIZE): $OUTPUT_FILE"
            AUDIO_FILE="$OUTPUT_FILE"
            FILE_SIZE=$NEW_SIZE
        else
            check_fail "Compression insufficient"
        fi
    fi
elif [[ $FILE_SIZE -gt $((1 * 1024 * 1024 * 1024)) ]]; then
    check_warn "File is large (>1 GB), processing may take time"
    check_pass "File size within 3 GB limit"
else
    check_pass "File size within 3 GB limit"
fi

#############################################################
# Check 6: Audio Properties (if ffprobe available)
#############################################################
if command -v ffprobe &> /dev/null; then
    echo ""
    echo -e "${BLUE}Audio Properties:${NC}"

    # Get duration
    DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$AUDIO_FILE" 2>/dev/null || echo "0")
    DURATION_INT=${DURATION%.*}
    MAX_DURATION=$((10 * 60 * 60)) # 10 hours in seconds

    if [[ -n "$DURATION" ]] && [[ "$DURATION_INT" -gt 0 ]]; then
        # Format duration
        HOURS=$((DURATION_INT / 3600))
        MINUTES=$(((DURATION_INT % 3600) / 60))
        SECONDS=$((DURATION_INT % 60))

        echo -e "${BLUE}  Duration: ${HOURS}h ${MINUTES}m ${SECONDS}s${NC}"

        if [[ $DURATION_INT -gt $MAX_DURATION ]]; then
            check_fail "Duration exceeds 10 hours limit"
        elif [[ $DURATION_INT -gt 3600 ]]; then
            check_warn "Long audio (>1 hour), processing may take time"
            check_pass "Duration within 10 hours limit"
        else
            check_pass "Duration within 10 hours limit"
        fi
    fi

    # Get audio codec
    CODEC=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$AUDIO_FILE" 2>/dev/null || echo "unknown")
    echo -e "${BLUE}  Codec: $CODEC${NC}"

    # Get sample rate
    SAMPLE_RATE=$(ffprobe -v error -select_streams a:0 -show_entries stream=sample_rate -of default=noprint_wrappers=1:nokey=1 "$AUDIO_FILE" 2>/dev/null || echo "unknown")
    if [[ "$SAMPLE_RATE" != "unknown" ]]; then
        echo -e "${BLUE}  Sample rate: $SAMPLE_RATE Hz${NC}"

        # Recommend 16000 Hz for optimal performance
        if [[ $SAMPLE_RATE -lt 16000 ]]; then
            check_warn "Sample rate <16kHz may reduce transcription quality"
        fi
    fi

    # Get channels
    CHANNELS=$(ffprobe -v error -select_streams a:0 -show_entries stream=channels -of default=noprint_wrappers=1:nokey=1 "$AUDIO_FILE" 2>/dev/null || echo "unknown")
    if [[ "$CHANNELS" != "unknown" ]]; then
        echo -e "${BLUE}  Channels: $CHANNELS${NC}"

        if [[ $CHANNELS -gt 2 ]]; then
            check_warn "Multi-channel audio detected (max 5 channels supported)"
        fi
    fi

    # Get bitrate
    BITRATE=$(ffprobe -v error -select_streams a:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 "$AUDIO_FILE" 2>/dev/null || echo "")
    if [[ -n "$BITRATE" ]] && [[ "$BITRATE" != "N/A" ]]; then
        BITRATE_KBPS=$((BITRATE / 1000))
        echo -e "${BLUE}  Bitrate: ${BITRATE_KBPS} kbps${NC}"
    fi

    if [[ "$VERBOSE" == "true" ]]; then
        echo ""
        echo -e "${BLUE}Detailed Information:${NC}"
        ffprobe -v error -show_format -show_streams "$AUDIO_FILE" 2>&1 | grep -E "(codec_name|sample_rate|channels|duration|bit_rate)"
    fi
else
    check_warn "ffprobe not available (install ffmpeg for detailed audio info)"
fi

#############################################################
# Check 7: File Integrity
#############################################################
if command -v ffprobe &> /dev/null; then
    echo ""
    if ffprobe -v error "$AUDIO_FILE" >/dev/null 2>&1; then
        check_pass "File integrity OK (no corruption detected)"
    else
        check_fail "File may be corrupted or invalid"
    fi
fi

#############################################################
# Summary
#############################################################
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Validation Summary                            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Passed:   $CHECKS_PASSED${NC}"
echo -e "${RED}Failed:   $CHECKS_FAILED${NC}"
echo -e "${YELLOW}Warnings: $CHECKS_WARNING${NC}"
echo ""

if [[ $CHECKS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}✓ File is ready for transcription${NC}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "  bash scripts/transcribe-audio.sh \"$AUDIO_FILE\" [language_code]"
    exit 0
else
    echo -e "${RED}✗ File validation failed${NC}"
    if [[ "$FIX_ISSUES" == "false" ]]; then
        echo ""
        echo -e "${YELLOW}Try running with --fix to attempt automatic fixes:${NC}"
        echo "  bash $0 \"$AUDIO_FILE\" --fix"
    fi
    exit 1
fi
