#!/usr/bin/env bash
# Audio format conversion examples

set -euo pipefail

INPUT="${1:-}"

if [[ -z "$INPUT" ]]; then
    echo "Usage: $0 <input_file>"
    exit 1
fi

BASENAME=$(basename "$INPUT" | sed 's/\.[^.]*$//')

echo "Converting audio formats..."

# Convert to MP3
python ../../scripts/process-audio.py \
    --input "$INPUT" \
    --output "${BASENAME}.mp3" \
    --format mp3 \
    --bitrate 192k

# Convert to WAV
python ../../scripts/process-audio.py \
    --input "$INPUT" \
    --output "${BASENAME}.wav" \
    --format wav

# Convert to FLAC
python ../../scripts/process-audio.py \
    --input "$INPUT" \
    --output "${BASENAME}.flac" \
    --format flac

echo ""
echo "Conversions complete!"
ls -lh "${BASENAME}".{mp3,wav,flac}

exit 0
