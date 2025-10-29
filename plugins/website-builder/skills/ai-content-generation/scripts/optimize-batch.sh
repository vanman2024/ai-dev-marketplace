#!/bin/bash
# optimize-batch.sh
# Optimize batch generation parameters for cost and quality balance

set -e

# Default values
TYPE=""
COUNT=0
BUDGET=0
QUALITY=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --type)
            TYPE="$2"
            shift 2
            ;;
        --count)
            COUNT="$2"
            shift 2
            ;;
        --budget)
            BUDGET="$2"
            shift 2
            ;;
        --quality)
            QUALITY="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            shift
            ;;
    esac
done

if [ -z "$TYPE" ] || [ "$COUNT" -eq 0 ]; then
    echo "Usage: $0 --type TYPE --count COUNT [--budget BUDGET] [--quality QUALITY]"
    echo
    echo "Types:"
    echo "  image    Optimize image batch generation"
    echo "  video    Optimize video batch generation"
    echo "  content  Optimize content batch generation"
    echo
    echo "Options:"
    echo "  --count COUNT       Number of items to generate (required)"
    echo "  --budget BUDGET     Maximum budget in USD (optional)"
    echo "  --quality QUALITY   Preferred quality (SD, HD, auto) - default: auto"
    echo
    echo "Examples:"
    echo "  $0 --type image --count 20 --budget 1.00"
    echo "  $0 --type content --count 10 --budget 0.50"
    echo "  $0 --type video --count 5 --budget 10.00 --quality HD"
    exit 1
fi

echo "=== Batch Generation Optimization ==="
echo
echo "Type: $TYPE"
echo "Count: $COUNT items"
[ -n "$BUDGET" ] && [ "$BUDGET" != "0" ] && echo "Budget: \$$BUDGET USD"
[ -n "$QUALITY" ] && echo "Preferred quality: $QUALITY"
echo

# Optimization logic based on type
case "$TYPE" in
    image)
        echo "Optimizing image batch generation..."
        echo

        # Calculate costs for different scenarios
        COST_SD_IMAGEN3=$(echo "$COUNT * 0.020" | bc -l)
        COST_HD_IMAGEN3=$(echo "$COUNT * 0.040" | bc -l)
        COST_SD_IMAGEN4=$(echo "$COUNT * 0.025" | bc -l)
        COST_HD_IMAGEN4=$(echo "$COUNT * 0.050" | bc -l)

        printf "Cost scenarios:\n"
        printf "  • Imagen 3 SD: \$%.4f (fastest, lowest cost)\n" "$COST_SD_IMAGEN3"
        printf "  • Imagen 3 HD: \$%.4f (balanced)\n" "$COST_HD_IMAGEN3"
        printf "  • Imagen 4 SD: \$%.4f (better quality)\n" "$COST_SD_IMAGEN4"
        printf "  • Imagen 4 HD: \$%.4f (highest quality, highest cost)\n" "$COST_HD_IMAGEN4"
        echo

        # Recommend based on budget or quality
        if [ -n "$BUDGET" ] && [ "$BUDGET" != "0" ]; then
            echo "Budget-based recommendations:"

            if [ $(echo "$COST_HD_IMAGEN4 <= $BUDGET" | bc -l) -eq 1 ]; then
                echo "  ✓ Recommended: Imagen 4 HD (best quality within budget)"
                echo "    Model: imagen4, Quality: HD"
            elif [ $(echo "$COST_SD_IMAGEN4 <= $BUDGET" | bc -l) -eq 1 ]; then
                echo "  ✓ Recommended: Imagen 4 SD (good quality within budget)"
                echo "    Model: imagen4, Quality: SD"
            elif [ $(echo "$COST_HD_IMAGEN3 <= $BUDGET" | bc -l) -eq 1 ]; then
                echo "  ✓ Recommended: Imagen 3 HD (within budget)"
                echo "    Model: imagen3, Quality: HD"
            elif [ $(echo "$COST_SD_IMAGEN3 <= $BUDGET" | bc -l) -eq 1 ]; then
                echo "  ✓ Recommended: Imagen 3 SD (within budget)"
                echo "    Model: imagen3, Quality: SD"
            else
                AFFORDABLE_COUNT=$(echo "$BUDGET / 0.020" | bc)
                echo "  ⚠ Budget too low for $COUNT images"
                echo "    Consider: Generate $AFFORDABLE_COUNT images with Imagen 3 SD"
                echo "    Or increase budget to \$$(printf "%.2f" "$COST_SD_IMAGEN3")"
            fi
        else
            echo "Quality-based recommendations:"
            if [ "$QUALITY" = "HD" ]; then
                echo "  ✓ Recommended: Imagen 3 HD (balanced quality/cost)"
                printf "    Cost: \$%.4f\n" "$COST_HD_IMAGEN3"
            elif [ "$QUALITY" = "SD" ]; then
                echo "  ✓ Recommended: Imagen 3 SD (fastest, lowest cost)"
                printf "    Cost: \$%.4f\n" "$COST_SD_IMAGEN3"
            else
                echo "  ✓ Recommended: Imagen 3 HD for hero/key images (mix)"
                echo "    Imagen 3 SD for thumbnails/secondary images"
                echo "    Strategy: 30% HD, 70% SD for optimal balance"
                COST_MIXED=$(echo "$COUNT * 0.3 * 0.040 + $COUNT * 0.7 * 0.020" | bc -l)
                printf "    Estimated cost: \$%.4f\n" "$COST_MIXED"
            fi
        fi

        echo
        echo "Batch optimization tips:"
        echo "  • Group similar prompts together"
        echo "  • Use consistent aspect ratios for easier layout"
        echo "  • Generate in batches of 5-10 for progress monitoring"
        echo "  • Use seeds for reproducible results"
        echo "  • Consider generating variations of successful prompts"
        ;;

    video)
        echo "Optimizing video batch generation..."
        echo

        # Assume average 5-second videos
        AVG_DURATION=5
        COST_SD_VEO2=$(echo "$COUNT * $AVG_DURATION * 0.10" | bc -l)
        COST_HD_VEO2=$(echo "$COUNT * $AVG_DURATION * 0.20" | bc -l)
        COST_SD_VEO3=$(echo "$COUNT * $AVG_DURATION * 0.15" | bc -l)
        COST_HD_VEO3=$(echo "$COUNT * $AVG_DURATION * 0.30" | bc -l)

        printf "Cost scenarios (5s videos):\n"
        printf "  • Veo 2 SD: \$%.4f (faster, lower cost)\n" "$COST_SD_VEO2"
        printf "  • Veo 2 HD: \$%.4f (balanced)\n" "$COST_HD_VEO2"
        printf "  • Veo 3 SD: \$%.4f (better quality)\n" "$COST_SD_VEO3"
        printf "  • Veo 3 HD: \$%.4f (highest quality)\n" "$COST_HD_VEO3"
        echo

        if [ -n "$BUDGET" ] && [ "$BUDGET" != "0" ]; then
            echo "Budget-based recommendations:"

            if [ $(echo "$COST_HD_VEO3 <= $BUDGET" | bc -l) -eq 1 ]; then
                echo "  ✓ Recommended: Veo 3 HD (best quality)"
            elif [ $(echo "$COST_SD_VEO3 <= $BUDGET" | bc -l) -eq 1 ]; then
                echo "  ✓ Recommended: Veo 3 SD"
            elif [ $(echo "$COST_HD_VEO2 <= $BUDGET" | bc -l) -eq 1 ]; then
                echo "  ✓ Recommended: Veo 2 HD"
            elif [ $(echo "$COST_SD_VEO2 <= $BUDGET" | bc -l) -eq 1 ]; then
                echo "  ✓ Recommended: Veo 2 SD"
            else
                AFFORDABLE_COUNT=$(echo "$BUDGET / ($AVG_DURATION * 0.10)" | bc)
                echo "  ⚠ Budget too low for $COUNT videos"
                echo "    Consider: Generate $AFFORDABLE_COUNT videos with Veo 2 SD"
            fi
        else
            echo "  ✓ Recommended: Keep videos short (5-10s) to control costs"
            echo "  • Use Veo 2 SD for social media previews"
            echo "  • Use Veo 3 HD only for key hero videos"
        fi

        echo
        echo "Batch optimization tips:"
        echo "  • Keep videos under 10 seconds to reduce costs"
        echo "  • Use consistent durations for easier editing"
        echo "  • Generate in small batches (2-3) due to higher costs"
        echo "  • Consider static images with animations as alternative"
        echo "  • Reuse successful video concepts with variations"
        ;;

    content)
        echo "Optimizing content batch generation..."
        echo

        # Assume average 500-word content pieces
        AVG_LENGTH=500
        COST_CLAUDE=$(echo "$COUNT * $AVG_LENGTH * 1.3 * 15 / 1000000" | bc -l)
        COST_GEMINI=$(echo "$COUNT * $AVG_LENGTH * 1.3 * 5 / 1000000" | bc -l)

        printf "Cost scenarios (500-word content):\n"
        printf "  • Gemini 2.0 Pro: \$%.4f (lower cost, creative)\n" "$COST_GEMINI"
        printf "  • Claude Sonnet 4: \$%.4f (higher quality, technical)\n" "$COST_CLAUDE"
        echo

        if [ -n "$BUDGET" ] && [ "$BUDGET" != "0" ]; then
            echo "Budget-based recommendations:"

            if [ $(echo "$COST_CLAUDE <= $BUDGET" | bc -l) -eq 1 ]; then
                echo "  ✓ Recommended: Claude Sonnet 4 (best quality within budget)"
            elif [ $(echo "$COST_GEMINI <= $BUDGET" | bc -l) -eq 1 ]; then
                echo "  ✓ Recommended: Gemini 2.0 Pro (within budget)"
            else
                AFFORDABLE_COUNT_GEMINI=$(echo "$BUDGET / ($AVG_LENGTH * 1.3 * 5 / 1000000)" | bc)
                echo "  ⚠ Budget too low for $COUNT pieces"
                echo "    Consider: Generate $AFFORDABLE_COUNT_GEMINI pieces with Gemini"
            fi
        else
            echo "Model selection by content type:"
            echo "  • Marketing copy, social posts: Gemini 2.0 Pro (60% cost savings)"
            echo "  • Technical docs, detailed content: Claude Sonnet 4 (higher quality)"
            echo "  • Blog posts, general content: Either model works well"
            echo
            echo "  ✓ Recommended: Use mixed approach"
            echo "    50% Gemini (marketing), 50% Claude (technical)"
            COST_MIXED=$(echo "($COST_GEMINI + $COST_CLAUDE) / 2" | bc -l)
            printf "    Estimated cost: \$%.4f\n" "$COST_MIXED"
        fi

        echo
        echo "Batch optimization tips:"
        echo "  • Create detailed prompts to reduce regeneration"
        echo "  • Use consistent tone and style parameters"
        echo "  • Generate outlines first, then expand"
        echo "  • Batch similar content types together"
        echo "  • Review and refine incrementally"
        ;;

    *)
        echo "✗ Unknown type: $TYPE"
        exit 1
        ;;
esac

echo
echo "General batch best practices:"
echo "  • Monitor progress and costs during generation"
echo "  • Start with small batch to validate quality"
echo "  • Use parallel generation when possible"
echo "  • Implement error handling and retry logic"
echo "  • Cache and track successful prompts for reuse"
