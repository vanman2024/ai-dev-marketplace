# Professional Voice Cloning Example

This example demonstrates the complete workflow for professional voice cloning using ElevenLabs, which produces hyper-realistic, high-quality voice clones suitable for production applications.

## Overview

Professional Voice Cloning (PVC) requires extended training audio (30+ minutes recommended) to produce high-fidelity voice clones that can be shared in the Voice Library for cash rewards.

## Key Differences from Instant Cloning

| Feature | Instant Cloning | Professional Cloning |
|---------|----------------|---------------------|
| Training Audio | 1-5 minutes | 30+ minutes |
| Quality | Good | Hyper-realistic |
| Processing Time | Immediate | Hours |
| Voice Library Sharing | No | Yes |
| Cash Rewards | No | Yes |
| Use Cases | Prototyping, testing | Production, commercial |

## Prerequisites

- ElevenLabs API key (Creator plan or higher)
- 30+ minutes of high-quality audio samples
- Consistent recording environment
- Verification capability (for sharing)

## Step-by-Step Workflow

### Step 1: Collect Training Audio

Professional cloning requires substantial, high-quality audio:

**Requirements:**
- **Duration**: 30-60 minutes minimum (more is better)
- **Variety**: Different emotions, intonations, speaking styles
- **Consistency**: Same microphone, environment, recording settings
- **Quality**: Clean, professional-grade audio

**Audio Collection Tips:**
```bash
# Create training audio directory
mkdir -p training_audio

# Organize samples by category
training_audio/
  ├── neutral/      # Neutral, conversational speech
  ├── expressive/   # Emotional, varied delivery
  ├── formal/       # Professional, structured content
  └── casual/       # Informal, relaxed speech
```

### Step 2: Process and Validate Audio

Process each audio file for optimal quality:

```bash
# Process all audio files
for audio_file in training_audio/*/*.mp3; do
    output_file="processed_$(basename "$audio_file")"

    python ../../scripts/process-audio.py \
        --input "$audio_file" \
        --output "processed_training/$output_file" \
        --sample-rate 44100 \
        --remove-noise \
        --normalize \
        --trim-silence \
        --validate
done
```

### Step 3: Clone Professional Voice

Use professional cloning method:

```bash
# Collect all processed files
AUDIO_FILES=$(ls -1 processed_training/*.mp3 | tr '\n' ',' | sed 's/,$//')

# Clone voice
bash ../../scripts/clone-voice.sh \
    --name "Professional Voice Clone" \
    --method professional \
    --files "$AUDIO_FILES" \
    --description "High-fidelity voice clone for production use" \
    --labels "professional,production,commercial"
```

Expected output:
```
ElevenLabs Voice Cloning
=========================
Voice Name: Professional Voice Clone
Method: professional

Validating audio files...
✓ processed_training/sample_01.mp3 (5.2MB)
✓ processed_training/sample_02.mp3 (4.8MB)
... (20+ files)

Cloning voice...
✓ Voice cloned successfully!

Voice ID: 9xL2K4pQrT7vZ3wM5eS8

Note: Professional voice cloning requires training.
The voice will be processed and refined over the next few hours.
```

### Step 4: Monitor Training Progress

Check voice status periodically:

```bash
# Check voice details
curl -s -X GET \
    "https://api.elevenlabs.io/v1/voices/${VOICE_ID}" \
    -H "xi-api-key: ${ELEVEN_API_KEY}" \
    | jq '{
        name: .name,
        category: .category,
        samples: (.samples | length),
        fine_tuning: .fine_tuning
    }'
```

Training typically takes 2-8 hours depending on:
- Amount of training audio
- Audio quality and consistency
- Current API processing queue

### Step 5: Test Voice Quality

Once training completes:

```bash
# Generate comprehensive test samples
bash verify-clone.sh "${VOICE_ID}"
```

This will generate multiple test samples to evaluate:
- Voice fidelity (similarity to original)
- Naturalness and flow
- Emotional range
- Consistency across different texts

### Step 6: Fine-Tune Settings

Optimize voice parameters for your use case:

```bash
# For audiobook narration
bash ../../scripts/configure-voice-settings.sh \
    --voice-id "${VOICE_ID}" \
    --stability 0.85 \
    --similarity 0.9 \
    --style 0.0

# For character performance
bash ../../scripts/configure-voice-settings.sh \
    --voice-id "${VOICE_ID}" \
    --stability 0.4 \
    --similarity 0.85 \
    --style 0.5
```

### Step 7: Share in Voice Library (Optional)

Professional clones can be shared for cash rewards:

```bash
bash ../../scripts/manage-voice-library.sh \
    --action share \
    --voice-id "${VOICE_ID}" \
    --enable-rewards \
    --description "Professional narrator voice with neutral accent" \
    --tags "narration,professional,neutral,american"
```

## Complete Workflow Script

See `clone-workflow.sh` for automated professional cloning workflow.

## Training Audio Best Practices

### Recording Setup
- **Microphone**: Use professional or semi-professional microphone
- **Environment**: Quiet room with acoustic treatment
- **Distance**: Maintain consistent distance from microphone
- **Levels**: Avoid clipping, maintain consistent volume
- **Format**: Record in WAV or FLAC, convert to MP3 if needed

### Content Variety

**Include diverse content:**
1. **Neutral Speech** (40%): Conversational, natural delivery
2. **Expressive Content** (30%): Varied emotions and intonations
3. **Formal Speech** (15%): Professional, structured content
4. **Dynamic Range** (15%): Whispers to loud speech

**Sample text categories:**
- Storytelling and narration
- Conversational dialogue
- Technical/informational content
- Emotional expressions
- Questions and responses
- Different pacing (slow, normal, fast)

### File Organization

```bash
training_audio/
├── neutral/
│   ├── conversation_01.mp3
│   ├── conversation_02.mp3
│   └── narration_01.mp3
├── expressive/
│   ├── emotional_01.mp3
│   ├── excited_01.mp3
│   └── dramatic_01.mp3
├── formal/
│   ├── presentation_01.mp3
│   └── technical_01.mp3
└── dynamic/
    ├── whisper_01.mp3
    └── loud_01.mp3
```

## Quality Assessment

### Evaluation Criteria

After training completes, evaluate the voice on:

1. **Fidelity**: How closely does it match the original voice?
2. **Naturalness**: Does it sound human and natural?
3. **Consistency**: Is quality consistent across different texts?
4. **Expressiveness**: Can it convey emotion appropriately?
5. **Clarity**: Is speech clear and intelligible?

### Testing Protocol

```bash
# Generate test samples with varied content
test_phrases=(
    "This is a neutral statement in a conversational tone."
    "Wow! That's absolutely incredible and amazing!"
    "I'm sorry to hear that. That must be difficult."
    "The technical specifications indicate a sample rate of 44.1 kilohertz."
    "One moment please. Let me check that for you."
)

for i in "${!test_phrases[@]}"; do
    curl -X POST "https://api.elevenlabs.io/v1/text-to-speech/${VOICE_ID}" \
        -H "xi-api-key: ${ELEVEN_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "{\"text\":\"${test_phrases[$i]}\"}" \
        --output "test_quality_$((i+1)).mp3"
done
```

### If Quality Needs Improvement

**Option 1: Add More Training Audio**
```bash
# Add additional samples
bash ../../scripts/clone-voice.sh \
    --name "Professional Voice Clone" \
    --method professional \
    --files "additional_samples.mp3" \
    --description "Additional training data"
```

**Option 2: Adjust Settings**
```bash
# Increase similarity for closer match
bash ../../scripts/configure-voice-settings.sh \
    --voice-id "${VOICE_ID}" \
    --similarity 0.95

# Adjust stability for consistency
bash ../../scripts/configure-voice-settings.sh \
    --voice-id "${VOICE_ID}" \
    --stability 0.8
```

**Option 3: Re-record Training Audio**
- Improve recording environment
- Use better microphone
- Ensure consistent delivery
- Add more variety in samples

## Sharing and Monetization

### Preparation for Sharing

Before sharing in Voice Library:

1. **Complete Verification**: Voice captcha required
2. **Add Description**: Clear, descriptive voice characteristics
3. **Add Tags**: Relevant searchable tags
4. **Test Quality**: Ensure professional quality
5. **Set Pricing**: Enable cash rewards if desired

### Sharing Workflow

```bash
# Share voice with rewards enabled
bash ../../scripts/manage-voice-library.sh \
    --action share \
    --voice-id "${VOICE_ID}" \
    --enable-rewards \
    --description "Professional American narrator, neutral accent, clear articulation" \
    --tags "narrator,professional,neutral,american,audiobook,podcast"
```

### Voice Library Optimization

**Effective Descriptions:**
- Include accent/dialect
- Mention tone and style
- Specify use cases
- Highlight unique characteristics

**Example:**
```
"Professional female narrator with neutral American accent.
Clear, warm delivery perfect for audiobooks, e-learning, and
corporate content. Versatile range from formal presentations
to casual conversation."
```

**Effective Tags:**
```
narrator, audiobook, podcast, professional, neutral, american,
female, warm, clear, versatile, e-learning, corporate
```

## Production Use Cases

### 1. Audiobook Production

```bash
# Optimize for long-form narration
bash ../../scripts/configure-voice-settings.sh \
    --voice-id "${VOICE_ID}" \
    --stability 0.9 \
    --similarity 0.85 \
    --style 0.0

# Generate chapter audio
curl -X POST "https://api.elevenlabs.io/v1/text-to-speech/${VOICE_ID}" \
    -H "xi-api-key: ${ELEVEN_API_KEY}" \
    -H "Content-Type: application/json" \
    -d @chapter_text.json \
    --output "audiobook_chapter_01.mp3"
```

### 2. Podcast Production

```bash
# Optimize for conversational style
bash ../../scripts/configure-voice-settings.sh \
    --voice-id "${VOICE_ID}" \
    --stability 0.6 \
    --similarity 0.8 \
    --style 0.2
```

### 3. Commercial/Advertising

```bash
# Optimize for impactful delivery
bash ../../scripts/configure-voice-settings.sh \
    --voice-id "${VOICE_ID}" \
    --stability 0.5 \
    --similarity 0.85 \
    --style 0.4
```

## Troubleshooting

### Training Takes Too Long
- **Normal**: 2-8 hours is typical
- **Check Status**: Use API to check processing status
- **Contact Support**: If > 24 hours without completion

### Voice Quality Issues
- **Add More Audio**: Increase training data to 60+ minutes
- **Improve Consistency**: Ensure all samples have similar quality
- **Adjust Settings**: Fine-tune stability and similarity
- **Re-record**: Consider starting over with better quality audio

### Cannot Share Voice
- **Verify Voice Type**: Only Professional clones can be shared
- **Complete Verification**: Voice captcha must be completed
- **Check Plan**: Ensure account has required permissions

## Resources

- [Training Audio Guide](training-guide.md)
- [Voice Library Best Practices](../voice-library/)
- [Professional Cloning Documentation](https://elevenlabs.io/docs/api-reference/voices)
