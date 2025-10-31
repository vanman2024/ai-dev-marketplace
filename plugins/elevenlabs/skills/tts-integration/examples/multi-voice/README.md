# Multi-Voice Example

Demonstrates working with multiple voice models, comparing outputs, and creating multi-speaker dialogues.

## Overview

This example covers:
- Comparing all voice models with same text
- Multi-speaker dialogue generation
- Voice model selection for different characters
- Batch processing with multiple voices

## Use Cases

- **Character Dialogues**: Different voices for different characters
- **Model Comparison**: Testing which model sounds best
- **Audiobook Production**: Multiple narrators or character voices
- **Podcasts**: Multiple hosts with distinct voices
- **Training Content**: Instructor and student voices

## Model Comparison

### Compare All Models

Test how different models handle the same text:

```bash
bash compare-models.sh \
  --text "This is a test to compare voice model quality and characteristics" \
  --voice-id YOUR_VOICE_ID \
  --output-dir ./model-comparison/
```

This generates:
- `eleven_v3.mp3` - Most expressive
- `eleven_multilingual_v2.mp3` - Best consistency
- `eleven_flash_v2_5.mp3` - Fastest generation
- `eleven_turbo_v2_5.mp3` - Balanced quality/speed

### Model Characteristics

**Eleven v3 (Alpha)**
- Most emotional range
- Best for: Character voices, expressive dialogue
- Character limit: 3,000 chars
- Listen for: Emotion nuance, multi-speaker capability

**Eleven Multilingual v2**
- Most consistent quality
- Best for: Professional narration, e-learning
- Character limit: 10,000 chars
- Listen for: Clarity, consistency, natural flow

**Eleven Flash v2.5**
- Fastest generation (~75ms)
- Best for: Real-time apps, bulk processing
- Character limit: 40,000 chars
- Listen for: Speed vs quality tradeoff

**Eleven Turbo v2.5**
- Good balance
- Best for: General-purpose applications
- Character limit: 40,000 chars
- Listen for: Quality with reasonable speed

## Multi-Speaker Dialogue

### Two-Speaker Conversation

Create dialogue with two different voices:

```bash
bash multi-speaker-dialogue.sh \
  --script dialogue-script.txt \
  --voice-a VOICE_ID_1 \
  --voice-b VOICE_ID_2 \
  --output-dir ./dialogue-output/
```

### Dialogue Script Format

`dialogue-script.txt`:
```
A: Hello! How are you doing today?
B: I'm doing great, thanks for asking! How about you?
A: Wonderful! I wanted to talk to you about our new project.
B: That sounds exciting! Tell me more about it.
```

### Multiple Characters

For more than two speakers:

```bash
bash multi-speaker-dialogue.sh \
  --script complex-dialogue.txt \
  --voice-map voices.json \
  --output-dir ./multi-character/
```

`voices.json`:
```json
{
  "Narrator": "voice_id_narrator"
  "Alice": "voice_id_alice"
  "Bob": "voice_id_bob"
  "Charlie": "voice_id_charlie"
}
```

`complex-dialogue.txt`:
```
Narrator: It was a dark and stormy night when three friends met.
Alice: Thank you both for coming on such short notice.
Bob: Of course! What's this all about?
Charlie: Yes, we're curious. You sounded urgent on the phone.
Alice: I've discovered something incredible...
```

## Voice Selection Strategy

### By Character Personality

```bash
# Confident leader
MODEL="eleven_turbo_v2_5"
STABILITY=0.6
STYLE=0.2

# Shy character
MODEL="eleven_multilingual_v2"
STABILITY=0.4
STYLE=0.0

# Villain (dramatic)
MODEL="eleven_v3"
STABILITY=0.3
STYLE=0.4
```

### By Content Type

**Professional Narration**
```json
{
  "model": "eleven_multilingual_v2"
  "voice_settings": {
    "stability": 0.8
    "similarity_boost": 0.75
    "style": 0.0
  }
}
```

**Character Dialogue**
```json
{
  "model": "eleven_v3"
  "voice_settings": {
    "stability": 0.4
    "similarity_boost": 0.75
    "style": 0.3
  }
}
```

**Fast Background Voices**
```json
{
  "model": "eleven_flash_v2_5"
  "voice_settings": {
    "stability": 0.5
    "similarity_boost": 0.75
    "style": 0.0
  }
}
```

## Batch Processing Multiple Voices

### Process Different Texts with Different Voices

```bash
# Create voice mapping
cat > voice-assignments.json << 'EOF'
{
  "chapter-01.txt": {
    "voice_id": "narrator_voice_id"
    "model": "eleven_multilingual_v2"
    "settings": {"stability": 0.8}
  }
  "dialogue-01.txt": {
    "voice_id": "character_voice_id"
    "model": "eleven_v3"
    "settings": {"stability": 0.4, "style": 0.3}
  }
}
EOF

# Process batch
bash batch-multi-voice.sh --config voice-assignments.json
```

## Voice Model Testing Workflow

### Step 1: Select Test Text

Choose representative text for your use case:

```bash
# For audiobook
TEST_TEXT="The story begins on a cold winter morning, when everything changed forever."

# For dialogue
TEST_TEXT="Wait, you mean to tell me that you've been here the whole time?"

# For e-learning
TEST_TEXT="In this lesson, we'll explore the fundamental concepts of machine learning."
```

### Step 2: Generate with All Models

```bash
bash compare-models.sh \
  --text "$TEST_TEXT" \
  --voice-id YOUR_VOICE_ID \
  --output-dir ./comparison/
```

### Step 3: Listen and Compare

Play each file and evaluate:
- **Clarity**: How clear is the speech?
- **Natural Flow**: Does it sound natural?
- **Emotion**: Does it convey the right emotion?
- **Consistency**: Would it maintain quality over longer content?

### Step 4: Test with Voice Settings

Once you choose a model, test settings:

```bash
# Test different stability levels
for stability in 0.3 0.5 0.7 0.9; do
  bash ../basic-tts/basic-example.sh \
    --text "$TEST_TEXT" \
    --voice-id YOUR_VOICE_ID \
    --model eleven_multilingual_v2 \
    --stability $stability \
    --output "test-stability-${stability}.mp3"
done
```

## Advanced Multi-Voice Techniques

### Voice Cloning Comparison

If you have multiple cloned voices:

```bash
VOICES=("voice_1" "voice_2" "voice_3")
TEXT="This is a test of voice cloning quality"

for voice in "${VOICES[@]}"; do
  bash ../basic-tts/basic-example.sh \
    --text "$TEXT" \
    --voice-id "$voice" \
    --output "clone-${voice}.mp3"
done
```

### Language-Specific Models

Test multilingual content:

```bash
# English
bash ../basic-tts/basic-example.sh \
  --text "Hello, how are you?" \
  --voice-id YOUR_VOICE_ID \
  --model eleven_multilingual_v2 \
  --output "english.mp3"

# Spanish
bash ../basic-tts/basic-example.sh \
  --text "Hola, ¿cómo estás?" \
  --voice-id YOUR_VOICE_ID \
  --model eleven_multilingual_v2 \
  --output "spanish.mp3"

# French
bash ../basic-tts/basic-example.sh \
  --text "Bonjour, comment allez-vous?" \
  --voice-id YOUR_VOICE_ID \
  --model eleven_multilingual_v2 \
  --output "french.mp3"
```

## Complete Example: Audiobook Chapter

```bash
#!/usr/bin/env bash
# Generate audiobook chapter with narrator and character voices

NARRATOR_VOICE="narrator_id"
CHARACTER_VOICE="character_id"
OUTPUT_DIR="./chapter-01/"

mkdir -p "$OUTPUT_DIR"

# Narration segments (consistent voice)
bash ../basic-tts/basic-example.sh \
  --text "$(cat narration-segments.txt)" \
  --voice-id "$NARRATOR_VOICE" \
  --model eleven_multilingual_v2 \
  --stability 0.8 \
  --output "$OUTPUT_DIR/narration.mp3"

# Character dialogue (expressive voice)
bash ../basic-tts/basic-example.sh \
  --text "$(cat character-dialogue.txt)" \
  --voice-id "$CHARACTER_VOICE" \
  --model eleven_v3 \
  --stability 0.4 \
  --style 0.3 \
  --output "$OUTPUT_DIR/dialogue.mp3"

# Combine (requires ffmpeg)
if command -v ffmpeg &> /dev/null; then
  ffmpeg -i "$OUTPUT_DIR/narration.mp3" -i "$OUTPUT_DIR/dialogue.mp3" \
    -filter_complex "[0:a][1:a]concat=n=2:v=0:a=1" \
    "$OUTPUT_DIR/chapter-01-complete.mp3"
fi
```

## Performance Comparison

Generate timing comparison:

```bash
bash compare-models.sh \
  --text "$(cat sample-text.txt)" \
  --voice-id YOUR_VOICE_ID \
  --measure-performance \
  --output-dir ./performance-test/
```

Expected results:
- Flash v2.5: ~75ms (fastest)
- Turbo v2.5: ~250ms
- Multilingual v2: ~400ms
- Eleven v3: ~500ms

## Cost Comparison

Flash v2.5 is 50% cheaper:

```bash
# Cost calculation
CHAR_COUNT=10000
FLASH_COST=$(echo "scale=4; $CHAR_COUNT * 0.000015" | bc)
STANDARD_COST=$(echo "scale=4; $CHAR_COUNT * 0.00003" | bc)

echo "Flash v2.5: \$$FLASH_COST"
echo "Other models: \$$STANDARD_COST"
echo "Savings: \$$(echo "scale=4; $STANDARD_COST - $FLASH_COST" | bc)"
```

## Best Practices

1. **Test Before Bulk**: Generate samples with all models first
2. **Match Model to Use Case**: Don't use v3 for simple announcements
3. **Consistent Settings**: Use same settings for related content
4. **Voice Mapping**: Document which voice/model for each character
5. **Quality vs Cost**: Balance quality needs with budget
6. **Character Limits**: Check limits before splitting text

## Troubleshooting

**Models sound too similar**
- Try more contrasting voices
- Adjust stability and style parameters
- Use different models (v3 vs v2)

**Inconsistent character voices**
- Increase stability to 0.7-0.9
- Use same model for same character
- Save and reuse exact settings

**Quality varies between models**
- Expected - each optimized differently
- Use consistent model for series
- Test with target content type

## Resources

- Compare script: `compare-models.sh`
- Multi-speaker script: `multi-speaker-dialogue.sh`
- Sample dialogue: `dialogue-script.txt`
- Model selection: `../../scripts/select-model.sh`
