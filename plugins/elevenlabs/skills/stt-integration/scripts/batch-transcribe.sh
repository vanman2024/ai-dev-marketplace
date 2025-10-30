#!/usr/bin/env bash
set -euo pipefail

#############################################################
# Batch Audio Transcription Script
#############################################################
# Usage: ./batch-transcribe.sh <directory> [language_code] [options]
# Example: ./batch-transcribe.sh ./recordings en --diarize --output-dir=./transcriptions
#
# Environment Variables:
#   ELEVENLABS_API_KEY - Required API key for authentication
#
# Options:
#   --output-dir=DIR       Save transcriptions to directory (default: ./transcriptions)
#   --pattern=PATTERN      File pattern to match (default: *.mp3 *.wav *.m4a)
#   --diarize              Enable speaker diarization
#   --num-speakers=N       Set max number of speakers
#   --parallel=N           Process N files in parallel (default: 1)
#   --skip-existing        Skip files that already have transcriptions
#   --json                 Save raw JSON responses
#############################################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
LANGUAGE_CODE="auto"
OUTPUT_DIR="./transcriptions"
FILE_PATTERN="*.{mp3,wav,m4a,ogg,flac,mp4,avi,mkv,mov}"
DIARIZE=""
NUM_SPEAKERS=""
PARALLEL=1
SKIP_EXISTING="false"
OUTPUT_JSON="false"
INPUT_DIR=""

# Counters
TOTAL_FILES=0
PROCESSED_FILES=0
FAILED_FILES=0
SKIPPED_FILES=0

# Check for API key
if [[ -z "${ELEVENLABS_API_KEY:-}" ]]; then
    echo -e "${RED}Error: ELEVENLABS_API_KEY environment variable not set${NC}"
    exit 1
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --output-dir=*)
            OUTPUT_DIR="${1#*=}"
            shift
            ;;
        --pattern=*)
            FILE_PATTERN="${1#*=}"
            shift
            ;;
        --diarize)
            DIARIZE="--diarize"
            shift
            ;;
        --num-speakers=*)
            NUM_SPEAKERS="--num-speakers=${1#*=}"
            shift
            ;;
        --parallel=*)
            PARALLEL="${1#*=}"
            shift
            ;;
        --skip-existing)
            SKIP_EXISTING="true"
            shift
            ;;
        --json)
            OUTPUT_JSON="--json"
            shift
            ;;
        -*)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
        *)
            if [[ -z "$INPUT_DIR" ]]; then
                INPUT_DIR="$1"
            elif [[ "$LANGUAGE_CODE" == "auto" ]]; then
                LANGUAGE_CODE="$1"
            fi
            shift
            ;;
    esac
done

# Validate input directory
if [[ -z "$INPUT_DIR" ]]; then
    echo -e "${RED}Error: Input directory required${NC}"
    echo "Usage: $0 <directory> [language_code] [options]"
    exit 1
fi

if [[ ! -d "$INPUT_DIR" ]]; then
    echo -e "${RED}Error: Directory not found: $INPUT_DIR${NC}"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Batch Audio Transcription                     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Input directory:  $INPUT_DIR${NC}"
echo -e "${BLUE}Output directory: $OUTPUT_DIR${NC}"
echo -e "${BLUE}Language:         $LANGUAGE_CODE${NC}"
echo -e "${BLUE}Parallel jobs:    $PARALLEL${NC}"
echo ""

# Find audio files
echo -e "${BLUE}Scanning for audio files...${NC}"

# Build find command for multiple extensions
AUDIO_FILES=()
shopt -s nullglob
for ext in mp3 wav m4a ogg flac mp4 avi mkv mov wmv webm; do
    while IFS= read -r -d '' file; do
        AUDIO_FILES+=("$file")
    done < <(find "$INPUT_DIR" -type f -iname "*.$ext" -print0)
done
shopt -u nullglob

TOTAL_FILES=${#AUDIO_FILES[@]}

if [[ $TOTAL_FILES -eq 0 ]]; then
    echo -e "${YELLOW}No audio files found in $INPUT_DIR${NC}"
    exit 0
fi

echo -e "${GREEN}Found $TOTAL_FILES audio file(s)${NC}"
echo ""

# Function to transcribe a single file
transcribe_file() {
    local file="$1"
    local file_basename=$(basename "$file")
    local file_no_ext="${file_basename%.*}"
    local output_file="$OUTPUT_DIR/${file_no_ext}.txt"
    local json_file="$OUTPUT_DIR/${file_no_ext}.json"

    # Skip if output exists and --skip-existing is set
    if [[ "$SKIP_EXISTING" == "true" ]] && [[ -f "$output_file" ]]; then
        echo -e "${YELLOW}⊘ Skipping (already transcribed): $file_basename${NC}"
        return 2
    fi

    echo -e "${BLUE}▸ Processing: $file_basename${NC}"

    # Build transcribe command
    local cmd="$SCRIPT_DIR/transcribe-audio.sh \"$file\" $LANGUAGE_CODE --output=\"$output_file\""
    [[ -n "$DIARIZE" ]] && cmd="$cmd $DIARIZE"
    [[ -n "$NUM_SPEAKERS" ]] && cmd="$cmd $NUM_SPEAKERS"
    [[ -n "$OUTPUT_JSON" ]] && cmd="$cmd $OUTPUT_JSON > \"$json_file\""

    # Execute transcription
    if eval "$cmd" > /dev/null 2>&1; then
        echo -e "${GREEN}  ✓ Completed: $file_basename${NC}"
        return 0
    else
        echo -e "${RED}  ✗ Failed: $file_basename${NC}"
        return 1
    fi
}

# Export function and variables for parallel execution
export -f transcribe_file
export SCRIPT_DIR OUTPUT_DIR LANGUAGE_CODE DIARIZE NUM_SPEAKERS OUTPUT_JSON SKIP_EXISTING
export ELEVENLABS_API_KEY
export RED GREEN YELLOW BLUE NC

# Process files
if [[ $PARALLEL -eq 1 ]]; then
    # Sequential processing
    echo -e "${BLUE}Processing files sequentially...${NC}"
    echo ""

    for file in "${AUDIO_FILES[@]}"; do
        if transcribe_file "$file"; then
            ((PROCESSED_FILES++))
        else
            status=$?
            if [[ $status -eq 2 ]]; then
                ((SKIPPED_FILES++))
            else
                ((FAILED_FILES++))
            fi
        fi
    done
else
    # Parallel processing
    echo -e "${BLUE}Processing files with $PARALLEL parallel jobs...${NC}"
    echo ""

    # Use GNU parallel if available, otherwise fall back to xargs
    if command -v parallel &> /dev/null; then
        printf "%s\n" "${AUDIO_FILES[@]}" | parallel -j "$PARALLEL" transcribe_file {}
    else
        printf "%s\n" "${AUDIO_FILES[@]}" | xargs -P "$PARALLEL" -I {} bash -c 'transcribe_file "$@"' _ {}
    fi

    # Count results
    for file in "${AUDIO_FILES[@]}"; do
        file_basename=$(basename "$file")
        file_no_ext="${file_basename%.*}"
        output_file="$OUTPUT_DIR/${file_no_ext}.txt"

        if [[ -f "$output_file" ]]; then
            ((PROCESSED_FILES++))
        else
            ((FAILED_FILES++))
        fi
    done
fi

# Summary
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Batch Processing Complete                     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Total files:      $TOTAL_FILES${NC}"
echo -e "${GREEN}Processed:        $PROCESSED_FILES${NC}"
echo -e "${RED}Failed:           $FAILED_FILES${NC}"
echo -e "${YELLOW}Skipped:          $SKIPPED_FILES${NC}"
echo ""

if [[ $PROCESSED_FILES -gt 0 ]]; then
    echo -e "${GREEN}✓ Transcriptions saved to: $OUTPUT_DIR${NC}"
fi

# Exit with appropriate code
if [[ $FAILED_FILES -eq 0 ]]; then
    exit 0
else
    exit 1
fi
