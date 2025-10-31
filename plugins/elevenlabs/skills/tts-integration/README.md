---
name: tts-integration
description: Voice model selection logic, audio format conversion, voice settings optimization, and sample voices. Use when implementing text-to-speech, selecting voice models, configuring TTS settings, converting audio formats, or when user mentions ElevenLabs TTS, voice synthesis, audio generation, voice models, or speech generation.
allowed-tools: Bash, Read, Write, Edit
---

# TTS Integration

Voice model selection, audio format optimization, and TTS configuration for ElevenLabs text-to-speech integration.

## Voice Models Overview

ElevenLabs provides four flagship TTS models, each optimized for different use cases:

### Eleven v3 (Alpha) - `eleven_v3`
**Most Emotionally Expressive**
- **Best For**: Character dialogues, audiobooks with complex emotional delivery, multilingual narratives
- **Languages**: 70+ languages
- **Character Limit**: 3,000 characters (~3 minutes audio)
- **Latency**: Higher (not recommended for real-time)
- **Cost**: Standard pricing
- **Key Features**:
  - Most expressive emotional range
  - Natural multi-speaker dialogue
  - Alpha quality (still improving)

### Eleven Multilingual v2 - `eleven_multilingual_v2`
**Quality & Consistency**
- **Best For**: Professional content creation, e-learning, gaming voiceovers, consistent voice quality
- **Languages**: 29 languages
- **Character Limit**: 10,000 characters (~10 minutes audio)
- **Latency**: Higher
- **Cost**: Standard pricing
- **Key Features**:
  - Natural, lifelike speech
  - High emotional range
  - Most stable for long-form content
  - Excellent for language switching

### Eleven Flash v2.5 - `eleven_flash_v2_5`
**Ultra-Low Latency**
- **Best For**: Real-time agents, interactive applications, bulk processing, cost-sensitive projects
- **Languages**: 32 languages
- **Character Limit**: 40,000 characters (~40 minutes audio)
- **Latency**: ~75ms (ultra-low)
- **Cost**: 50% lower per character
- **Key Features**:
  - Fastest generation speed
  - Budget-friendly option
  - Large character limit
  - Note: Numbers not normalized by default (Enterprise can enable)

### Eleven Turbo v2.5 - `eleven_turbo_v2_5`
**Balanced Quality & Speed**
- **Best For**: Applications needing better quality than Flash but faster than Multilingual v2
- **Languages**: 32 languages
- **Character Limit**: 40,000 characters (~40 minutes audio)
- **Latency**: 250-300ms (low)
- **Cost**: Standard pricing
- **Key Features**:
  - Sweet spot between quality and speed
  - Good for most general applications
  - Reliable multilingual support

## Model Selection Decision Tree

Use the `scripts/select-model.sh` script to help choose the right model:

```bash
# Interactive model selection
bash scripts/select-model.sh --interactive

# Quick selection by priority
bash scripts/select-model.sh --priority speed      # Returns: eleven_flash_v2_5
bash scripts/select-model.sh --priority quality    # Returns: eleven_multilingual_v2
bash scripts/select-model.sh --priority balanced   # Returns: eleven_turbo_v2_5
bash scripts/select-model.sh --priority expressive # Returns: eleven_v3

# Selection by use case
bash scripts/select-model.sh --use-case "real-time chat"
bash scripts/select-model.sh --use-case "audiobook"
bash scripts/select-model.sh --use-case "e-learning"
```

### Quick Selection Guide

**Choose Eleven v3 when:**
- Need maximum emotional expressiveness
- Creating character-rich audiobooks
- Multi-speaker dialogue required
- Real-time performance not critical

**Choose Multilingual v2 when:**
- Professional content creation
- Consistent voice quality is priority
- Switching between languages
- Long-form content (up to 10K chars)

**Choose Flash v2.5 when:**
- Real-time/interactive applications
- Budget is a constraint
- Ultra-low latency required
- Processing large volumes
- Simple, straightforward speech

**Choose Turbo v2.5 when:**
- Need balance of quality and speed
- General-purpose applications
- Moderate latency tolerance
- Better quality than Flash needed

## Audio Formats

ElevenLabs supports multiple output formats:

### Supported Formats
- **MP3**: 22-192 kbps (most common, good compression)
- **PCM**: Uncompressed, highest quality
- **μ-law** (mu-law): Telephony standard, 8-bit compression
- **A-law**: European telephony standard, 8-bit compression
- **Opus**: Modern codec, excellent quality-to-size ratio

### Format Selection Guidelines
- **Web streaming**: MP3 (128 kbps) or Opus
- **High quality**: PCM or MP3 (192 kbps)
- **Telephony**: μ-law or A-law
- **Mobile apps**: Opus or MP3 (64-128 kbps)
- **Bandwidth-limited**: Opus or MP3 (64 kbps)

Use `scripts/convert-audio.sh` for format conversion:

```bash
# Convert to different formats
bash scripts/convert-audio.sh input.mp3 --to-pcm
bash scripts/convert-audio.sh input.mp3 --to-opus
bash scripts/convert-audio.sh input.pcm --to-mp3 --bitrate 128

# Batch conversion
bash scripts/convert-audio.sh *.mp3 --to-opus --output-dir ./converted/
```

## Voice Settings Optimization

Voice settings control the synthesis characteristics:

### Key Parameters

**stability** (0.0 - 1.0)
- Higher = More consistent, predictable voice
- Lower = More expressive, variable voice
- Default: 0.5
- Recommendation: 0.7-0.9 for consistency, 0.3-0.5 for expressiveness

**similarity_boost** (0.0 - 1.0)
- Higher = Closer to original voice sample
- Lower = More creative interpretation
- Default: 0.75
- Recommendation: 0.75-0.9 for cloned voices

**style** (0.0 - 1.0)
- Controls style exaggeration
- Higher = More dramatic style interpretation
- Default: 0.0
- Use with caution: can cause instability

**use_speaker_boost** (boolean)
- Enhances similarity to speaker
- Helpful for cloned voices
- Default: true
- Recommendation: Enable for voice cloning

### Optimization Strategies

**For Consistency** (narration, audiobooks):
```json
{
  "stability": 0.8
  "similarity_boost": 0.75
  "style": 0.0
  "use_speaker_boost": true
}
```

**For Expressiveness** (character dialogue, advertisements):
```json
{
  "stability": 0.4
  "similarity_boost": 0.75
  "style": 0.3
  "use_speaker_boost": true
}
```

**For Natural Speech** (e-learning, IVR):
```json
{
  "stability": 0.6
  "similarity_boost": 0.8
  "style": 0.0
  "use_speaker_boost": true
}
```

## Scripts

### select-model.sh
Model selection helper based on use case, priority, or interactive prompts.

```bash
# Interactive mode with questions
bash scripts/select-model.sh --interactive

# Quick selection
bash scripts/select-model.sh --priority speed
bash scripts/select-model.sh --use-case "customer service bot"

# Get model details
bash scripts/select-model.sh --info eleven_flash_v2_5
```

### convert-audio.sh
Audio format conversion with quality optimization.

```bash
# Single file conversion
bash scripts/convert-audio.sh input.mp3 --to-opus

# Batch conversion with quality settings
bash scripts/convert-audio.sh *.mp3 --to-mp3 --bitrate 192 --output-dir high-quality/

# Format info
bash scripts/convert-audio.sh --format-info opus
```

### test-tts.sh
Test TTS with sample text and configurations.

```bash
# Test with default settings
bash scripts/test-tts.sh "Hello world" --voice-id <VOICE_ID>

# Test specific model
bash scripts/test-tts.sh "Hello world" --model eleven_flash_v2_5 --voice-id <VOICE_ID>

# Test with custom settings
bash scripts/test-tts.sh "Hello world" \
  --voice-id <VOICE_ID> \
  --model eleven_turbo_v2_5 \
  --stability 0.7 \
  --similarity-boost 0.8 \
  --output test-output.mp3

# Test all models comparison
bash scripts/test-tts.sh "Compare voice quality" --voice-id <VOICE_ID> --compare-models
```

### optimize-settings.sh
Voice settings optimizer for specific use cases.

```bash
# Get optimized settings for use case
bash scripts/optimize-settings.sh --use-case audiobook

# Interactive optimization
bash scripts/optimize-settings.sh --interactive

# Test and compare settings
bash scripts/optimize-settings.sh --test "Sample text" --voice-id <VOICE_ID>
```

### batch-generate.sh
Batch TTS generation with progress tracking.

```bash
# Generate from text file (one phrase per line)
bash scripts/batch-generate.sh input.txt --voice-id <VOICE_ID> --output-dir audio/

# Generate with specific model
bash scripts/batch-generate.sh input.txt \
  --voice-id <VOICE_ID> \
  --model eleven_flash_v2_5 \
  --output-dir audio/

# Generate with custom settings
bash scripts/batch-generate.sh input.txt \
  --voice-id <VOICE_ID> \
  --settings-file voice-settings.json \
  --output-dir audio/ \
  --format opus
```

## Templates

### tts-config.json.template
Complete TTS configuration template with all available options.

### voice-settings.json.template
Voice settings template for different use cases (narration, dialogue, natural speech).

### streaming-config.json.template
WebSocket streaming configuration template.

### batch-config.json.template
Batch processing configuration with retry logic and error handling.

## Examples

### basic-tts/
Basic text-to-speech implementation with model selection and format conversion.

**Files:**
- `basic-example.sh` - Simple TTS generation script
- `README.md` - Usage guide and explanations
- `sample-texts.txt` - Sample texts for testing

### streaming-tts/
Real-time streaming TTS implementation using WebSocket.

**Files:**
- `stream-example.sh` - WebSocket streaming implementation
- `README.md` - Streaming setup and usage guide
- `client-example.js` - JavaScript client example

### multi-voice/
Multiple voice models comparison and multi-speaker implementation.

**Files:**
- `compare-models.sh` - Generate same text with all models
- `multi-speaker-dialogue.sh` - Multi-speaker conversation example
- `README.md` - Multi-voice usage patterns
- `dialogue-script.txt` - Sample dialogue for testing

## Best Practices

### Text Preparation
1. **Emotional Cues**: Models interpret emotion from text ("she said excitedly")
2. **Long Text**: Split long text and use previous/next text parameters for natural prosody
3. **Consistency**: Use seed parameter for deterministic outputs
4. **Numbers**: Flash models don't normalize numbers by default (spell them out)

### Model Selection
1. **Start with Turbo v2.5**: Good default for most applications
2. **Optimize for Use Case**: Use decision tree to select best model
3. **Test Multiple Models**: Use comparison scripts to validate choice
4. **Consider Costs**: Flash v2.5 is 50% cheaper for bulk processing

### Voice Settings
1. **Start with Defaults**: Test default settings first
2. **Tune Gradually**: Adjust one parameter at a time
3. **Use Presets**: Leverage optimization presets for common use cases
4. **Test Thoroughly**: Generate multiple samples to validate settings

### Production Considerations
1. **Error Handling**: Implement retry logic for API failures
2. **Caching**: Cache generated audio when possible
3. **Rate Limiting**: Respect API rate limits
4. **Monitoring**: Track generation times and costs
5. **Fallbacks**: Have backup models for high availability

## Requirements

- **ElevenLabs API Key**: Required for all TTS operations
- **curl**: For API requests
- **jq**: For JSON processing
- **ffmpeg**: For audio format conversion (optional but recommended)
- **Python 3.7+**: For batch processing scripts (optional)

## Environment Setup

```bash
# Set API key
export ELEVENLABS_API_KEY="your-api-key-here"

# Test API connection
bash scripts/test-tts.sh "API test" --voice-id <VOICE_ID>
```

## Troubleshooting

### Common Issues

**"Character limit exceeded"**
- Solution: Split text into smaller chunks, check model character limits

**"Latency too high"**
- Solution: Switch to Flash v2.5 or Turbo v2.5, check network connectivity

**"Voice quality inconsistent"**
- Solution: Increase stability parameter, use seed for consistency

**"Numbers not pronounced correctly"** (Flash models)
- Solution: Spell out numbers or enable text normalization (Enterprise)

**"Audio format not supported"**
- Solution: Use convert-audio.sh to convert to supported format

## Additional Resources

- ElevenLabs TTS Documentation: https://elevenlabs.io/docs/capabilities/text-to-speech
- API Reference: https://elevenlabs.io/docs/api-reference/text-to-speech
- Models Guide: https://elevenlabs.io/docs/models

---

**Generated for**: ElevenLabs Plugin
**Version**: 1.0.0
**Last Updated**: 2025-10-29
