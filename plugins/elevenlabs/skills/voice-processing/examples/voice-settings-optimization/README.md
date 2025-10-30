# Voice Settings Optimization Examples

Fine-tune voice parameters for different use cases.

## Quick Reference

### Get Current Settings
```bash
bash ../../scripts/configure-voice-settings.sh \
    --voice-id "YOUR_VOICE_ID" \
    --get-current
```

### Apply Preset

**Narration (Audiobooks)**
```bash
bash ../../scripts/configure-voice-settings.sh \
    --voice-id "YOUR_VOICE_ID" \
    --stability 0.85 \
    --similarity 0.8 \
    --style 0.0
```

**Dialogue (Conversational)**
```bash
bash ../../scripts/configure-voice-settings.sh \
    --voice-id "YOUR_VOICE_ID" \
    --stability 0.5 \
    --similarity 0.8 \
    --style 0.2
```

**Character (Expressive)**
```bash
bash ../../scripts/configure-voice-settings.sh \
    --voice-id "YOUR_VOICE_ID" \
    --stability 0.3 \
    --similarity 0.7 \
    --style 0.6
```

## Parameter Guide

### Stability (0.0-1.0)
- **Low (0.2-0.4)**: Variable, expressive, emotional
- **Medium (0.5-0.7)**: Balanced, natural conversation
- **High (0.8-1.0)**: Consistent, stable narration

### Similarity Boost (0.0-1.0)
- **Low (0.3-0.5)**: Creative interpretation
- **Medium (0.6-0.8)**: Balanced clone fidelity
- **High (0.85-0.95)**: Maximum similarity to original

### Style (0.0-1.0)
- **Low (0.0-0.2)**: Neutral, flat delivery
- **Medium (0.3-0.5)**: Moderate expressiveness
- **High (0.6-1.0)**: Highly expressive, dramatic

## Use Case Examples

### Audiobook Narration
```bash
bash ../../scripts/configure-voice-settings.sh \
    --voice-id "$VOICE_ID" \
    --stability 0.9 \
    --similarity 0.85 \
    --style 0.0
```

### Podcast Host
```bash
bash ../../scripts/configure-voice-settings.sh \
    --voice-id "$VOICE_ID" \
    --stability 0.6 \
    --similarity 0.8 \
    --style 0.15
```

### Video Game Character
```bash
bash ../../scripts/configure-voice-settings.sh \
    --voice-id "$VOICE_ID" \
    --stability 0.3 \
    --similarity 0.7 \
    --style 0.7
```

### Corporate Training
```bash
bash ../../scripts/configure-voice-settings.sh \
    --voice-id "$VOICE_ID" \
    --stability 0.75 \
    --similarity 0.8 \
    --style 0.1
```

### AI Assistant
```bash
bash ../../scripts/configure-voice-settings.sh \
    --voice-id "$VOICE_ID" \
    --stability 0.55 \
    --similarity 0.85 \
    --style 0.2
```

See complete examples in optimize-stability.sh, optimize-similarity.sh, and test-settings.sh
