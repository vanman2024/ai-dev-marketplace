#!/usr/bin/env bash
#
# Professional voice cloning workflow
#

set -euo pipefail

# Configuration
VOICE_NAME="${1:-Professional Voice}"
TRAINING_DIR="${2:-training_audio}"
ELEVEN_API_KEY="${ELEVEN_API_KEY:-}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}Professional Voice Cloning Workflow${NC}"
echo "====================================="
echo ""

# Validate inputs
if [[ ! -d "$TRAINING_DIR" ]]; then
    echo -e "${RED}Error: Training directory not found: $TRAINING_DIR${NC}"
    exit 1
fi

if [[ -z "$ELEVEN_API_KEY" ]]; then
    echo -e "${RED}Error: ELEVEN_API_KEY not set${NC}"
    exit 1
fi

# Step 1: Inventory training audio
echo -e "${GREEN}Step 1: Analyzing training audio${NC}"
AUDIO_FILES=$(find "$TRAINING_DIR" -name "*.mp3" -o -name "*.wav" -o -name "*.flac" | sort)
FILE_COUNT=$(echo "$AUDIO_FILES" | wc -l)

echo "Found $FILE_COUNT audio files"

if [[ $FILE_COUNT -lt 10 ]]; then
    echo -e "${YELLOW}Warning: Professional cloning works best with 30+ minutes of audio${NC}"
    echo -e "${YELLOW}You have $FILE_COUNT files. Consider adding more for better quality.${NC}"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

# Calculate total duration
echo ""
echo "Calculating total duration..."
TOTAL_DURATION=0
while IFS= read -r file; do
    duration=$(python -c "from pydub import AudioSegment; print(len(AudioSegment.from_file('$file')) / 1000.0)" 2>/dev/null || echo "0")
    TOTAL_DURATION=$(python -c "print($TOTAL_DURATION + $duration)")
done <<< "$AUDIO_FILES"

echo "Total duration: $(printf "%.1f" $TOTAL_DURATION) seconds ($(printf "%.1f" $(echo "$TOTAL_DURATION / 60" | bc -l)) minutes)"

if (( $(echo "$TOTAL_DURATION < 1800" | bc -l) )); then
    echo -e "${YELLOW}Warning: Less than 30 minutes of audio. Recommend 30+ minutes for best results.${NC}"
fi

# Step 2: Process audio files
echo ""
read -p "Process audio files (noise reduction, normalization)? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}Step 2: Processing audio files${NC}"
    mkdir -p processed_training

    count=0
    while IFS= read -r file; do
        count=$((count + 1))
        output_file="processed_training/$(basename "$file" .mp3)_processed.mp3"

        echo "[$count/$FILE_COUNT] Processing: $(basename "$file")"

        python ../../scripts/process-audio.py \
            --input "$file" \
            --output "$output_file" \
            --sample-rate 44100 \
            --remove-noise \
            --normalize \
            --trim-silence \
            > /dev/null 2>&1

        echo -e "${GREEN}✓${NC} $output_file"
    done <<< "$AUDIO_FILES"

    TRAINING_DIR="processed_training"
    echo ""
    echo -e "${GREEN}All files processed${NC}"
fi

# Step 3: Clone voice
echo ""
echo -e "${GREEN}Step 3: Creating professional voice clone${NC}"

# Collect all files as comma-separated list
ALL_FILES=$(find "$TRAINING_DIR" -name "*.mp3" | tr '\n' ',' | sed 's/,$//')

echo "Uploading $FILE_COUNT training files..."
echo ""

bash ../../scripts/clone-voice.sh \
    --name "$VOICE_NAME" \
    --method professional \
    --files "$ALL_FILES" \
    --description "Professional voice clone with $FILE_COUNT training samples" \
    --labels "professional,production"

# Extract voice ID
VOICE_ID=$(ls -t voice_*.json | head -1 | sed 's/voice_//' | sed 's/.json//')

echo ""
echo -e "${GREEN}Voice clone initiated!${NC}"
echo "Voice ID: $VOICE_ID"
echo ""
echo -e "${YELLOW}Note: Professional voice cloning requires training time (2-8 hours typically)${NC}"

# Step 4: Save workflow info
echo ""
echo -e "${GREEN}Step 4: Saving workflow information${NC}"

cat > "workflow_${VOICE_ID}.json" <<EOF
{
  "voice_id": "$VOICE_ID",
  "voice_name": "$VOICE_NAME",
  "method": "professional",
  "training_files": $FILE_COUNT,
  "total_duration_seconds": $TOTAL_DURATION,
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "training_directory": "$TRAINING_DIR",
  "status": "training"
}
EOF

echo -e "${GREEN}✓ Workflow info saved to: workflow_${VOICE_ID}.json${NC}"

# Step 5: Instructions for monitoring
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "==========="
echo ""
echo "1. Monitor training progress (check every few hours):"
echo "   curl -s -X GET 'https://api.elevenlabs.io/v1/voices/${VOICE_ID}' \\"
echo "     -H 'xi-api-key: \$ELEVEN_API_KEY' | jq '{name, category, fine_tuning}'"
echo ""
echo "2. Once training completes, test voice quality:"
echo "   bash verify-clone.sh '$VOICE_ID'"
echo ""
echo "3. Configure voice settings for your use case:"
echo "   bash ../../scripts/configure-voice-settings.sh --voice-id '$VOICE_ID' --stability 0.8 --similarity 0.9"
echo ""
echo "4. Share in Voice Library (optional):"
echo "   bash ../../scripts/manage-voice-library.sh --action share --voice-id '$VOICE_ID' --enable-rewards"
echo ""

# Create monitoring script
cat > "monitor_${VOICE_ID}.sh" <<'MONITOR_SCRIPT'
#!/usr/bin/env bash
VOICE_ID="VOICE_ID_PLACEHOLDER"
ELEVEN_API_KEY="${ELEVEN_API_KEY:-}"

if [[ -z "$ELEVEN_API_KEY" ]]; then
    echo "Error: ELEVEN_API_KEY not set"
    exit 1
fi

while true; do
    clear
    echo "Monitoring Voice Training: $VOICE_ID"
    echo "===================================="
    echo ""

    STATUS=$(curl -s -X GET \
        "https://api.elevenlabs.io/v1/voices/${VOICE_ID}" \
        -H "xi-api-key: ${ELEVEN_API_KEY}")

    echo "$STATUS" | jq '{
        name: .name,
        category: .category,
        samples: (.samples | length),
        fine_tuning: .fine_tuning
    }'

    echo ""
    echo "Last checked: $(date)"
    echo "Press Ctrl+C to stop monitoring"

    sleep 300  # Check every 5 minutes
done
MONITOR_SCRIPT

sed -i "s/VOICE_ID_PLACEHOLDER/$VOICE_ID/" "monitor_${VOICE_ID}.sh"
chmod +x "monitor_${VOICE_ID}.sh"

echo "5. Monitor training automatically (checks every 5 minutes):"
echo "   bash monitor_${VOICE_ID}.sh"
echo ""

echo -e "${GREEN}Workflow setup complete!${NC}"

exit 0
