#!/usr/bin/env bash
# Prepare audio for voice cloning workflow

set -euo pipefail

INPUT="${1:-}"
OUTPUT="${2:-cloning_ready.mp3}"

if [[ -z "$INPUT" ]]; then
    echo "Usage: $0 <input_file> [output_file]"
    exit 1
fi

echo "Preparing audio for voice cloning..."

python ../../scripts/process-audio.py \
    --input "$INPUT" \
    --output "$OUTPUT" \
    --sample-rate 22050 \
    --remove-noise \
    --normalize \
    --trim-silence \
    --validate

echo ""
echo "Audio prepared for cloning: $OUTPUT"
echo ""
echo "Next step:"
echo "bash ../../scripts/clone-voice.sh --name 'Voice' --files '$OUTPUT'"

exit 0
