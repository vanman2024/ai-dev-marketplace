#!/bin/bash
# calculate-cost.sh
# Estimate generation costs before execution

set -e

# Default values
TYPE=""
MODEL=""
QUALITY="SD"
COUNT=1
LENGTH=0
DURATION=0

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --type)
            TYPE="$2"
            shift 2
            ;;
        --model)
            MODEL="$2"
            shift 2
            ;;
        --quality)
            QUALITY="$2"
            shift 2
            ;;
        --count)
            COUNT="$2"
            shift 2
            ;;
        --length)
            LENGTH="$2"
            shift 2
            ;;
        --duration)
            DURATION="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            shift
            ;;
    esac
done

if [ -z "$TYPE" ]; then
    echo "Usage: $0 --type TYPE [OPTIONS]"
    echo
    echo "Types:"
    echo "  image    Generate images with Imagen"
    echo "  video    Generate videos with Veo"
    echo "  content  Generate content with Claude/Gemini"
    echo
    echo "Options:"
    echo "  --model MODEL       Model to use (imagen3, imagen4, veo2, veo3, claude-sonnet-4, gemini-2.0-pro)"
    echo "  --quality QUALITY   Quality level (SD, HD) - for images/videos"
    echo "  --count COUNT       Number of items to generate - default: 1"
    echo "  --length LENGTH     Content length in words - for content generation"
    echo "  --duration DURATION Video duration in seconds - for video generation"
    echo
    echo "Examples:"
    echo "  $0 --type image --quality HD --count 5"
    echo "  $0 --type content --model claude-sonnet-4 --length 1000"
    echo "  $0 --type video --duration 5 --quality HD"
    exit 1
fi

echo "=== AI Generation Cost Estimation ==="
echo

# Pricing data (approximate, as of 2025)
# Imagen 3: ~$0.020 per image (SD), ~$0.040 per image (HD)
# Imagen 4: ~$0.025 per image (SD), ~$0.050 per image (HD)
# Veo 2: ~$0.10 per second (SD), ~$0.20 per second (HD)
# Veo 3: ~$0.15 per second (SD), ~$0.30 per second (HD)
# Claude Sonnet 4: ~$3 per million input tokens, ~$15 per million output tokens
# Gemini 2.0 Pro: ~$1.25 per million input tokens, ~$5 per million output tokens

calculate_image_cost() {
    local model="${1:-imagen3}"
    local quality="$2"
    local count="$3"

    local unit_cost
    case "$model" in
        imagen3)
            [ "$quality" = "HD" ] && unit_cost=0.040 || unit_cost=0.020
            ;;
        imagen4)
            [ "$quality" = "HD" ] && unit_cost=0.050 || unit_cost=0.025
            ;;
        *)
            [ "$quality" = "HD" ] && unit_cost=0.040 || unit_cost=0.020
            ;;
    esac

    local total_cost=$(echo "$unit_cost * $count" | bc -l)
    printf "%.4f" "$total_cost"
}

calculate_video_cost() {
    local model="${1:-veo2}"
    local quality="$2"
    local duration="$3"
    local count="${4:-1}"

    local unit_cost_per_second
    case "$model" in
        veo2)
            [ "$quality" = "HD" ] && unit_cost_per_second=0.20 || unit_cost_per_second=0.10
            ;;
        veo3)
            [ "$quality" = "HD" ] && unit_cost_per_second=0.30 || unit_cost_per_second=0.15
            ;;
        *)
            [ "$quality" = "HD" ] && unit_cost_per_second=0.20 || unit_cost_per_second=0.10
            ;;
    esac

    local total_cost=$(echo "$unit_cost_per_second * $duration * $count" | bc -l)
    printf "%.4f" "$total_cost"
}

calculate_content_cost() {
    local model="${1:-claude-sonnet-4}"
    local word_count="$2"
    local count="${3:-1}"

    # Rough estimate: 1 word ≈ 1.3 tokens (input), output ≈ word_count tokens
    local input_tokens=$(echo "$word_count * 0.3 * $count" | bc -l)  # Prompt is shorter
    local output_tokens=$(echo "$word_count * 1.3 * $count" | bc -l)

    local input_cost_per_million output_cost_per_million
    case "$model" in
        claude-sonnet-4)
            input_cost_per_million=3.0
            output_cost_per_million=15.0
            ;;
        gemini-2.0-pro)
            input_cost_per_million=1.25
            output_cost_per_million=5.0
            ;;
        *)
            input_cost_per_million=3.0
            output_cost_per_million=15.0
            ;;
    esac

    local input_cost=$(echo "$input_tokens * $input_cost_per_million / 1000000" | bc -l)
    local output_cost=$(echo "$output_tokens * $output_cost_per_million / 1000000" | bc -l)
    local total_cost=$(echo "$input_cost + $output_cost" | bc -l)

    printf "%.4f" "$total_cost"
}

# Calculate cost based on type
TOTAL_COST=0

case "$TYPE" in
    image)
        MODEL="${MODEL:-imagen3}"
        echo "Generation type: Image"
        echo "Model: $MODEL"
        echo "Quality: $QUALITY"
        echo "Count: $COUNT"
        echo
        TOTAL_COST=$(calculate_image_cost "$MODEL" "$QUALITY" "$COUNT")
        echo "Estimated cost: \$$TOTAL_COST USD"
        echo
        echo "Breakdown:"
        UNIT_COST=$(calculate_image_cost "$MODEL" "$QUALITY" 1)
        echo "  • Per image: \$$UNIT_COST USD"
        echo "  • Total ($COUNT images): \$$TOTAL_COST USD"
        ;;
    video)
        MODEL="${MODEL:-veo2}"
        echo "Generation type: Video"
        echo "Model: $MODEL"
        echo "Quality: $QUALITY"
        echo "Duration: ${DURATION}s"
        echo "Count: $COUNT"
        echo
        TOTAL_COST=$(calculate_video_cost "$MODEL" "$QUALITY" "$DURATION" "$COUNT")
        echo "Estimated cost: \$$TOTAL_COST USD"
        echo
        echo "Breakdown:"
        UNIT_COST=$(calculate_video_cost "$MODEL" "$QUALITY" "$DURATION" 1)
        echo "  • Per video (${DURATION}s): \$$UNIT_COST USD"
        echo "  • Total ($COUNT videos): \$$TOTAL_COST USD"
        ;;
    content)
        MODEL="${MODEL:-claude-sonnet-4}"
        echo "Generation type: Content"
        echo "Model: $MODEL"
        echo "Length: $LENGTH words"
        echo "Count: $COUNT"
        echo
        TOTAL_COST=$(calculate_content_cost "$MODEL" "$LENGTH" "$COUNT")
        echo "Estimated cost: \$$TOTAL_COST USD"
        echo
        echo "Breakdown:"
        UNIT_COST=$(calculate_content_cost "$MODEL" "$LENGTH" 1)
        echo "  • Per content piece ($LENGTH words): \$$UNIT_COST USD"
        echo "  • Total ($COUNT pieces): \$$TOTAL_COST USD"
        ;;
    *)
        echo "✗ Unknown type: $TYPE"
        exit 1
        ;;
esac

echo
echo "=== Cost Optimization Tips ==="
echo

case "$TYPE" in
    image)
        echo "• Use SD quality for thumbnails and secondary images (50% cost reduction)"
        echo "• Batch similar images together for better efficiency"
        echo "• Use Imagen 3 instead of Imagen 4 if quality difference is minimal (20% savings)"
        echo "• Reuse and crop existing images when possible"
        ;;
    video)
        echo "• Keep videos short (5-10s) to reduce costs significantly"
        echo "• Use SD quality for social media and previews (50% cost reduction)"
        echo "• Use Veo 2 instead of Veo 3 if quality difference is acceptable (33% savings)"
        echo "• Consider using static images with transitions instead of video"
        ;;
    content)
        echo "• Use Gemini 2.0 Pro for marketing content (60% cost reduction)"
        echo "• Use Claude Sonnet 4 for technical/detailed content (higher quality)"
        echo "• Generate outlines first, then expand to reduce iteration costs"
        echo "• Batch similar content pieces together"
        echo "• Provide clear, detailed prompts to reduce regeneration needs"
        ;;
esac

echo
echo "Note: Prices are approximate and may vary. Check current pricing at:"
echo "  • Google Cloud Vertex AI: https://cloud.google.com/vertex-ai/pricing"
echo "  • Anthropic Claude: https://www.anthropic.com/pricing"
echo "  • Google AI Gemini: https://ai.google.dev/pricing"
