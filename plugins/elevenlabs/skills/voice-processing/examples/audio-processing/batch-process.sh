#!/usr/bin/env bash
# Batch process multiple audio files

set -euo pipefail

INPUT_DIR="${1:-raw_audio}"
OUTPUT_DIR="${2:-processed_audio}"

if [[ ! -d "$INPUT_DIR" ]]; then
    echo "Error: Input directory not found: $INPUT_DIR"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

echo "Batch Processing Audio Files"
echo "============================="
echo "Input: $INPUT_DIR"
echo "Output: $OUTPUT_DIR"
echo ""

# Find all audio files
FILES=$(find "$INPUT_DIR" -name "*.mp3" -o -name "*.wav" -o -name "*.flac")
FILE_COUNT=$(echo "$FILES" | wc -l)

echo "Found $FILE_COUNT files to process"
echo ""

count=0
while IFS= read -r file; do
    count=$((count + 1))
    output="$OUTPUT_DIR/$(basename "$file" | sed 's/\.[^.]*$/.mp3/')"

    echo "[$count/$FILE_COUNT] Processing: $(basename "$file")"

    python ../../scripts/process-audio.py \
        --input "$file" \
        --output "$output" \
        --sample-rate 22050 \
        --remove-noise \
        --normalize \
        --trim-silence \
        --validate \
        2>&1 | grep -E "(✓|Error|Warning)" || true

    echo ""
done <<< "$FILES"

echo "Batch processing complete!"
echo "Processed files: $OUTPUT_DIR"

exit 0
