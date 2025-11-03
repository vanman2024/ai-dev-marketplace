#!/bin/bash
# enhance-image-prompt.sh
# Improve image generation prompts for better quality results

set -e

# Parse arguments
BASIC_PROMPT=""
STYLE=""
QUALITY_LEVEL="high"

while [[ $# -gt 0 ]]; do
    case $1 in
        --style)
            STYLE="$2"
            shift 2
            ;;
        --quality)
            QUALITY_LEVEL="$2"
            shift 2
            ;;
        *)
            if [ -z "$BASIC_PROMPT" ]; then
                BASIC_PROMPT="$1"
            else
                BASIC_PROMPT="$BASIC_PROMPT $1"
            fi
            shift
            ;;
    esac
done

if [ -z "$BASIC_PROMPT" ]; then
    echo "Usage: $0 \"your prompt\" [--style STYLE] [--quality QUALITY]"
    echo
    echo "Options:"
    echo "  --style     Style modifier (photographic, illustration, 3d-render, minimalist, artistic)"
    echo "  --quality   Quality level (high, medium, low) - default: high"
    echo
    echo "Examples:"
    echo "  $0 \"modern website hero background\""
    echo "  $0 \"product showcase\" --style photographic --quality high"
    echo "  $0 \"abstract pattern\" --style artistic"
    exit 1
fi

echo "=== Image Prompt Enhancement ==="
echo
echo "Input prompt: $BASIC_PROMPT"
[ -n "$STYLE" ] && echo "Style: $STYLE"
echo "Quality level: $QUALITY_LEVEL"
echo

# Style-specific enhancements
STYLE_MODIFIERS=""
case "$STYLE" in
    photographic)
        STYLE_MODIFIERS="high-resolution photograph, professional photography, sharp focus, natural lighting"
        ;;
    illustration)
        STYLE_MODIFIERS="digital illustration, clean lines, vibrant colors, professional artwork"
        ;;
    3d-render)
        STYLE_MODIFIERS="3D render, octane render, cinematic lighting, high detail, realistic materials"
        ;;
    minimalist)
        STYLE_MODIFIERS="minimalist design, clean composition, simple shapes, limited color palette"
        ;;
    artistic)
        STYLE_MODIFIERS="artistic style, creative composition, unique perspective, expressive colors"
        ;;
    *)
        STYLE_MODIFIERS="high quality, professional, detailed"
        ;;
esac

# Quality-specific enhancements
QUALITY_MODIFIERS=""
case "$QUALITY_LEVEL" in
    high)
        QUALITY_MODIFIERS="4K, ultra-detailed, high resolution, sharp, crisp"
        ;;
    medium)
        QUALITY_MODIFIERS="good quality, clear, detailed"
        ;;
    low)
        QUALITY_MODIFIERS="standard quality"
        ;;
esac

# Combine enhancements
ENHANCED_PROMPT="$BASIC_PROMPT, $STYLE_MODIFIERS, $QUALITY_MODIFIERS"

# Add quality control modifiers
ENHANCED_PROMPT="$ENHANCED_PROMPT, no watermark, no text, no labels"

echo "Enhanced prompt:"
echo "─────────────────────────────────────────────────────────"
echo "$ENHANCED_PROMPT"
echo "─────────────────────────────────────────────────────────"
echo

# Generate negative prompt suggestions
echo "Suggested negative prompt:"
echo "─────────────────────────────────────────────────────────"
NEGATIVE_PROMPT="blurry, low quality, distorted, watermark, text, logo, signature, cropped, out of frame, worst quality, low res, jpeg artifacts, duplicate, morbid, mutilated, poorly drawn, ugly, deformed"
echo "$NEGATIVE_PROMPT"
echo "─────────────────────────────────────────────────────────"
echo

# Additional recommendations
echo "Recommendations:"
echo "  • Use HD quality for hero images and key visuals"
echo "  • Use SD quality for thumbnails and secondary images"
echo "  • Consider aspect ratio: 16:9 for hero, 1:1 for products"
echo "  • Add specific details about colors, composition, or mood"
echo "  • Keep prompt focused on main subject and style"
echo

# Output JSON format for programmatic use
echo "JSON output (for programmatic use):"
cat <<EOF
{
  "original_prompt": "$BASIC_PROMPT",
  "enhanced_prompt": "$ENHANCED_PROMPT",
  "negative_prompt": "$NEGATIVE_PROMPT",
  "style": "${STYLE:-default}",
  "quality_level": "$QUALITY_LEVEL",
  "recommendations": {
    "hero_image": {
      "quality": "HD",
      "aspect_ratio": "16:9"
    },
    "product_image": {
      "quality": "HD",
      "aspect_ratio": "1:1"
    },
    "thumbnail": {
      "quality": "SD",
      "aspect_ratio": "16:9"
    }
  }
}
EOF
