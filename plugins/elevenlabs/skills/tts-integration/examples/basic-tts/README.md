# Basic TTS Example

Complete guide to basic text-to-speech generation with ElevenLabs.

## Overview

This example demonstrates simple TTS generation with model selection, voice settings customization, and audio format conversion.

## Prerequisites

- ElevenLabs API key
- Voice ID (get from ElevenLabs dashboard)
- curl and jq installed
- Optional: ffmpeg for format conversion

## Quick Start

### 1. Set API Key

```bash
export ELEVENLABS_API_KEY="your-api-key-here"
```

### 2. Choose a Voice

List available voices:

```bash
curl -s -H "xi-api-key: $ELEVENLABS_API_KEY" \
  "https://api.elevenlabs.io/v1/voices" | jq -r '.voices[] | "\(.voice_id): \(.name)"'
```

### 3. Generate Speech

```bash
bash basic-example.sh \
  --text "Hello, this is a test of ElevenLabs text-to-speech." \
  --voice-id "YOUR_VOICE_ID" \
  --output "hello.mp3"
```

## Model Selection

Use the model selection script to choose the right model:

```bash
# Interactive selection
bash ../../scripts/select-model.sh --interactive

# By priority
bash ../../scripts/select-model.sh --priority speed      # Flash v2.5
bash ../../scripts/select-model.sh --priority quality    # Multilingual v2
bash ../../scripts/select-model.sh --priority balanced   # Turbo v2.5

# By use case
bash ../../scripts/select-model.sh --use-case "audiobook"
bash ../../scripts/select-model.sh --use-case "real-time chat"
```

## Voice Settings

### Using Presets

```bash
# Get preset for audiobook
bash ../../scripts/optimize-settings.sh --use-case audiobook --output audiobook-settings.json

# Use preset in generation
bash basic-example.sh \
  --text "Chapter one begins..." \
  --voice-id "YOUR_VOICE_ID" \
  --settings-file audiobook-settings.json \
  --output "chapter-01.mp3"
```

### Custom Settings

```bash
bash basic-example.sh \
  --text "Your text here" \
  --voice-id "YOUR_VOICE_ID" \
  --model eleven_turbo_v2_5 \
  --stability 0.7 \
  --similarity-boost 0.8 \
  --style 0.1 \
  --output "custom.mp3"
```

## Format Conversion

Convert generated audio to different formats:

```bash
# Generate as MP3
bash basic-example.sh --text "Hello" --voice-id "YOUR_VOICE_ID" --output audio.mp3

# Convert to Opus for web
bash ../../scripts/convert-audio.sh audio.mp3 --to-opus --output audio.opus

# Convert to PCM for processing
bash ../../scripts/convert-audio.sh audio.mp3 --to-pcm --output audio.wav

# High quality MP3
bash ../../scripts/convert-audio.sh audio.mp3 --to-mp3 --bitrate 320k --output audio-hq.mp3
```

## Complete Examples

### Example 1: Audiobook Narration

```bash
# Select optimal model
MODEL=$(bash ../../scripts/select-model.sh --use-case "audiobook")

# Get optimized settings
bash ../../scripts/optimize-settings.sh --use-case audiobook --output narrator-settings.json

# Generate chapter
bash basic-example.sh \
  --text "$(cat chapter-01.txt)" \
  --voice-id "YOUR_VOICE_ID" \
  --model "$MODEL" \
  --settings-file narrator-settings.json \
  --format mp3_44100_192 \
  --output "chapter-01-narration.mp3"
```

### Example 2: E-Learning Content

```bash
# Select balanced model
MODEL="eleven_turbo_v2_5"

# Use e-learning preset
bash ../../scripts/optimize-settings.sh --use-case elearning --output elearning-settings.json

# Generate lesson audio
bash basic-example.sh \
  --text "Welcome to lesson one. Today we'll learn about..." \
  --voice-id "YOUR_VOICE_ID" \
  --model "$MODEL" \
  --settings-file elearning-settings.json \
  --output "lesson-01-intro.mp3"
```

### Example 3: Marketing Content

```bash
# Use expressive model
MODEL="eleven_turbo_v2_5"

# Marketing preset for energetic delivery
bash ../../scripts/optimize-settings.sh --use-case marketing --output marketing-settings.json

# Generate ad
bash basic-example.sh \
  --text "Introducing our new product! Amazing features that will change your life!" \
  --voice-id "YOUR_VOICE_ID" \
  --model "$MODEL" \
  --settings-file marketing-settings.json \
  --output "product-ad.mp3"
```

### Example 4: Fast Bulk Processing

```bash
# Use Flash model for speed and cost
MODEL="eleven_flash_v2_5"

# Generate with default settings
bash basic-example.sh \
  --text "Quick notification message" \
  --voice-id "YOUR_VOICE_ID" \
  --model "$MODEL" \
  --format mp3_22050_64 \
  --output "notification.mp3"

# Convert to Opus for even smaller size
bash ../../scripts/convert-audio.sh notification.mp3 --to-opus --bitrate 32k
```

## Testing Multiple Models

Compare output from all models:

```bash
bash ../../scripts/test-tts.sh \
  "Compare the quality and character of each voice model" \
  --voice-id "YOUR_VOICE_ID" \
  --compare-models
```

This generates:
- `compare-eleven_v3.mp3`
- `compare-eleven_multilingual_v2.mp3`
- `compare-eleven_flash_v2_5.mp3`
- `compare-eleven_turbo_v2_5.mp3`

## Using Sample Texts

The `sample-texts.txt` file contains various sample texts for testing:

```bash
# Generate from first line
TEXT=$(head -n 1 sample-texts.txt)
bash basic-example.sh --text "$TEXT" --voice-id "YOUR_VOICE_ID" --output "sample-01.mp3"

# Generate from all lines
index=1
while IFS= read -r line; do
  bash basic-example.sh \
    --text "$line" \
    --voice-id "YOUR_VOICE_ID" \
    --output "sample-$(printf '%02d' $index).mp3"
  index=$((index + 1))
done < sample-texts.txt
```

## Common Issues

### Issue: "Character limit exceeded"

**Solution**: Check model limits:
- Eleven v3: 3,000 characters
- Multilingual v2: 10,000 characters
- Flash v2.5: 40,000 characters
- Turbo v2.5: 40,000 characters

Split long text or use model with higher limit.

### Issue: "API rate limit reached"

**Solution**: Add delay between requests:

```bash
for text in "${texts[@]}"; do
  bash basic-example.sh --text "$text" --voice-id "YOUR_VOICE_ID" --output "audio-$i.mp3"
  sleep 1  # 1 second delay
  i=$((i + 1))
done
```

### Issue: "Voice quality inconsistent"

**Solution**: Increase stability parameter:

```bash
bash basic-example.sh \
  --text "Your text" \
  --voice-id "YOUR_VOICE_ID" \
  --stability 0.8 \
  --output "consistent.mp3"
```

## Best Practices

1. **Start with presets**: Use optimize-settings.sh to get proven configurations
2. **Test before bulk**: Generate samples before processing large volumes
3. **Choose right model**: Use select-model.sh decision tree
4. **Format selection**: Match format to use case (web = Opus, professional = PCM)
5. **Add text cues**: Include emotional cues in text ("she said excitedly")
6. **Split long content**: Break long texts into logical chunks
7. **Cache results**: Save generated audio to avoid regeneration

## Performance Tips

- Use Flash v2.5 for fastest generation (~75ms latency)
- Lower bitrate formats generate faster
- Stability 0.5 is fastest (less variation to compute)
- Batch similar content together for consistency

## Cost Optimization

- Flash v2.5 is 50% cheaper per character
- Lower bitrate formats save bandwidth
- Cache and reuse common phrases
- Use appropriate quality for use case (not all need 192kbps)

## Next Steps

- Try streaming TTS: See `examples/streaming-tts/`
- Batch processing: See `examples/multi-voice/`
- Advanced features: Check ElevenLabs documentation

## Resources

- Model selection: `../../scripts/select-model.sh --help`
- Settings optimization: `../../scripts/optimize-settings.sh --help`
- Format conversion: `../../scripts/convert-audio.sh --help`
- Testing: `../../scripts/test-tts.sh --help`
