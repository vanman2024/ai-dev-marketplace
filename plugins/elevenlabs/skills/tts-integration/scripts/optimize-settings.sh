#!/usr/bin/env bash
# Voice settings optimizer for ElevenLabs TTS
# Provides optimized settings for different use cases

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_color() {
    local color=$1
    shift
    echo -e "${color}$*${NC}"
}

# Use case presets
get_preset() {
    local use_case="$1"

    case "$use_case" in
        audiobook|narration|book)
            echo '{"stability": 0.8, "similarity_boost": 0.75, "style": 0.0, "use_speaker_boost": true}'
            ;;
        dialogue|character|conversation)
            echo '{"stability": 0.4, "similarity_boost": 0.75, "style": 0.3, "use_speaker_boost": true}'
            ;;
        elearning|training|education)
            echo '{"stability": 0.6, "similarity_boost": 0.8, "style": 0.0, "use_speaker_boost": true}'
            ;;
        marketing|advertisement|promo)
            echo '{"stability": 0.5, "similarity_boost": 0.75, "style": 0.4, "use_speaker_boost": true}'
            ;;
        ivr|phone|customer-service)
            echo '{"stability": 0.7, "similarity_boost": 0.8, "style": 0.0, "use_speaker_boost": true}'
            ;;
        gaming|voiceover)
            echo '{"stability": 0.5, "similarity_boost": 0.75, "style": 0.2, "use_speaker_boost": true}'
            ;;
        podcast|radio)
            echo '{"stability": 0.6, "similarity_boost": 0.75, "style": 0.1, "use_speaker_boost": true}'
            ;;
        natural|neutral|default)
            echo '{"stability": 0.5, "similarity_boost": 0.75, "style": 0.0, "use_speaker_boost": true}'
            ;;
        expressive|emotional|dramatic)
            echo '{"stability": 0.3, "similarity_boost": 0.7, "style": 0.5, "use_speaker_boost": true}'
            ;;
        consistent|stable|predictable)
            echo '{"stability": 0.9, "similarity_boost": 0.8, "style": 0.0, "use_speaker_boost": true}'
            ;;
        *)
            print_color "$RED" "Unknown use case: $use_case"
            return 1
            ;;
    esac
}

# Show preset information
show_preset_info() {
    local use_case="$1"
    local settings=$(get_preset "$use_case")

    if [[ -z "$settings" ]]; then
        return 1
    fi

    print_color "$BLUE" "═══════════════════════════════════════════════════════════════"
    print_color "$GREEN" "Optimized Settings for: $use_case"
    print_color "$BLUE" "═══════════════════════════════════════════════════════════════"

    echo "$settings" | jq -r 'to_entries[] | "  \(.key): \(.value)"'

    print_color "$BLUE" "═══════════════════════════════════════════════════════════════"

    # Add recommendations
    echo ""
    print_color "$YELLOW" "Recommendations:"

    case "$use_case" in
        audiobook|narration|book)
            echo "  - High stability for consistent narration"
            echo "  - No style exaggeration for natural reading"
            echo "  - Use with Multilingual v2 model"
            echo "  - Split long chapters for better prosody"
            ;;
        dialogue|character|conversation)
            echo "  - Low stability for expressive dialogue"
            echo "  - Moderate style for character personality"
            echo "  - Use with Eleven v3 for best emotion"
            echo "  - Add emotional cues in text"
            ;;
        elearning|training|education)
            echo "  - Moderate stability for clear delivery"
            echo "  - High similarity for professional sound"
            echo "  - Use with Turbo v2.5 for balance"
            echo "  - Keep sentences clear and structured"
            ;;
        marketing|advertisement|promo)
            echo "  - Moderate stability with style exaggeration"
            echo "  - Use for energetic, attention-grabbing content"
            echo "  - Test with Flash v2.5 for cost efficiency"
            echo "  - Emphasize key phrases in text"
            ;;
        ivr|phone|customer-service)
            echo "  - High stability for professional consistency"
            echo "  - Use with Turbo v2.5 for good quality"
            echo "  - Consider μ-law format for telephony"
            echo "  - Keep messages short and clear"
            ;;
        gaming|voiceover)
            echo "  - Balanced settings for character variety"
            echo "  - Adjust per character personality"
            echo "  - Use Multilingual v2 for quality"
            echo "  - Create separate profiles per character"
            ;;
        podcast|radio)
            echo "  - Moderate stability for natural flow"
            echo "  - Slight style for engaging delivery"
            echo "  - Use Multilingual v2 for quality"
            echo "  - Add natural pauses and inflection cues"
            ;;
    esac

    echo ""
}

# Interactive optimizer
interactive_optimizer() {
    print_color "$BLUE" "Voice Settings Optimization Wizard"
    print_color "$BLUE" "═══════════════════════════════════════════════════════════════"
    echo ""

    # Question 1: Use case
    echo "Select your primary use case:"
    echo "1) Audiobook/Narration"
    echo "2) Character Dialogue"
    echo "3) E-learning/Training"
    echo "4) Marketing/Advertisement"
    echo "5) IVR/Customer Service"
    echo "6) Gaming/Voiceover"
    echo "7) Podcast/Radio"
    echo "8) Custom settings"
    read -p "Enter choice (1-8): " use_case_choice

    local preset=""
    case $use_case_choice in
        1) preset="audiobook" ;;
        2) preset="dialogue" ;;
        3) preset="elearning" ;;
        4) preset="marketing" ;;
        5) preset="ivr" ;;
        6) preset="gaming" ;;
        7) preset="podcast" ;;
        8) preset="custom" ;;
        *)
            print_color "$RED" "Invalid choice"
            exit 1
            ;;
    esac

    echo ""

    if [[ "$preset" == "custom" ]]; then
        # Custom settings
        print_color "$YELLOW" "Custom Settings Configuration"
        echo ""

        echo "Stability (0.0-1.0):"
        echo "  - Higher = More consistent, predictable"
        echo "  - Lower = More expressive, variable"
        read -p "Stability [0.5]: " stability
        stability="${stability:-0.5}"

        echo ""
        echo "Similarity Boost (0.0-1.0):"
        echo "  - Higher = Closer to original voice"
        echo "  - Lower = More creative interpretation"
        read -p "Similarity Boost [0.75]: " similarity
        similarity="${similarity:-0.75}"

        echo ""
        echo "Style (0.0-1.0):"
        echo "  - Higher = More dramatic style"
        echo "  - Use with caution, can cause instability"
        read -p "Style [0.0]: " style
        style="${style:-0.0}"

        echo ""
        read -p "Use Speaker Boost? (y/n) [y]: " speaker_boost
        speaker_boost="${speaker_boost:-y}"

        if [[ "$speaker_boost" == "y" || "$speaker_boost" == "Y" ]]; then
            speaker_boost_val="true"
        else
            speaker_boost_val="false"
        fi

        settings=$(jq -n \
            --arg stability "$stability" \
            --arg similarity "$similarity" \
            --arg style "$style" \
            --argjson speaker_boost "$speaker_boost_val" \
            '{
                stability: ($stability | tonumber),
                similarity_boost: ($similarity | tonumber),
                style: ($style | tonumber),
                use_speaker_boost: $speaker_boost
            }')
    else
        settings=$(get_preset "$preset")
    fi

    echo ""
    print_color "$GREEN" "Optimized Settings:"
    echo "$settings" | jq '.'

    # Ask to save
    echo ""
    read -p "Save settings to file? (y/n): " save_choice
    if [[ "$save_choice" == "y" || "$save_choice" == "Y" ]]; then
        read -p "Output file [voice-settings.json]: " output_file
        output_file="${output_file:-voice-settings.json}"
        echo "$settings" | jq '.' > "$output_file"
        print_color "$GREEN" "✓ Settings saved to $output_file"
    fi
}

# List all presets
list_presets() {
    print_color "$BLUE" "Available Presets"
    print_color "$BLUE" "═══════════════════════════════════════════════════════════════"
    echo ""

    local presets=(
        "audiobook:Audiobook/Narration"
        "dialogue:Character Dialogue"
        "elearning:E-learning/Training"
        "marketing:Marketing/Advertisement"
        "ivr:IVR/Customer Service"
        "gaming:Gaming/Voiceover"
        "podcast:Podcast/Radio"
        "natural:Natural/Neutral"
        "expressive:Expressive/Emotional"
        "consistent:Consistent/Stable"
    )

    for preset_info in "${presets[@]}"; do
        IFS=':' read -r key name <<< "$preset_info"
        printf "  %-20s - %s\n" "$key" "$name"
    done

    echo ""
    print_color "$YELLOW" "Use: $(basename "$0") --use-case <preset> to see details"
}

# Compare presets
compare_presets() {
    print_color "$BLUE" "Preset Comparison"
    print_color "$BLUE" "═══════════════════════════════════════════════════════════════"
    echo ""

    printf "%-20s %-12s %-18s %-10s %-15s\n" "Use Case" "Stability" "Similarity Boost" "Style" "Speaker Boost"
    print_color "$BLUE" "─────────────────────────────────────────────────────────────────────────────────"

    local presets=("audiobook" "dialogue" "elearning" "marketing" "ivr" "gaming" "podcast" "natural" "expressive" "consistent")

    for preset in "${presets[@]}"; do
        local settings=$(get_preset "$preset")
        local stability=$(echo "$settings" | jq -r '.stability')
        local similarity=$(echo "$settings" | jq -r '.similarity_boost')
        local style=$(echo "$settings" | jq -r '.style')
        local speaker=$(echo "$settings" | jq -r '.use_speaker_boost')

        printf "%-20s %-12s %-18s %-10s %-15s\n" "$preset" "$stability" "$similarity" "$style" "$speaker"
    done

    echo ""
}

# Show usage
show_usage() {
    cat << EOF
Voice Settings Optimizer for ElevenLabs TTS

Usage:
    $(basename "$0") [OPTIONS]

Options:
    --interactive           Interactive settings wizard
    --use-case USE_CASE    Get optimized settings for use case
    --list                 List all available presets
    --compare              Compare all presets side-by-side
    --output FILE          Save settings to JSON file
    --help                 Show this help message

Available Use Cases:
    audiobook              Audiobook/narration (high consistency)
    dialogue               Character dialogue (high expressiveness)
    elearning              E-learning/training (clear delivery)
    marketing              Marketing/advertisement (energetic)
    ivr                    IVR/customer service (professional)
    gaming                 Gaming/voiceover (balanced)
    podcast                Podcast/radio (engaging)
    natural                Natural/neutral (default)
    expressive             Expressive/emotional (dramatic)
    consistent             Consistent/stable (predictable)

Examples:
    # Interactive wizard
    $(basename "$0") --interactive

    # Get preset for audiobook
    $(basename "$0") --use-case audiobook

    # Save preset to file
    $(basename "$0") --use-case elearning --output elearning-settings.json

    # Compare all presets
    $(basename "$0") --compare

    # List all presets
    $(basename "$0") --list

Settings Parameters:
    stability           (0.0-1.0) Higher = more consistent
    similarity_boost    (0.0-1.0) Higher = closer to original voice
    style              (0.0-1.0) Higher = more dramatic style
    use_speaker_boost  (boolean) Enhances similarity to speaker

Recommendations:
    - Start with a preset matching your use case
    - Test with sample text before bulk generation
    - Adjust one parameter at a time
    - Higher stability = more predictable but less expressive
    - Style parameter can cause instability if too high

EOF
}

# Main script logic
main() {
    if ! command -v jq &> /dev/null; then
        print_color "$RED" "Error: jq is required but not installed."
        echo "Install with: sudo apt-get install jq (Linux) or brew install jq (Mac)"
        exit 1
    fi

    if [[ $# -eq 0 ]]; then
        show_usage
        exit 0
    fi

    local output_file=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --interactive)
                interactive_optimizer
                exit 0
                ;;
            --use-case)
                if [[ $# -lt 2 ]]; then
                    print_color "$RED" "Error: --use-case requires an argument"
                    exit 1
                fi
                show_preset_info "$2"

                if [[ -n "$output_file" ]]; then
                    settings=$(get_preset "$2")
                    echo "$settings" | jq '.' > "$output_file"
                    print_color "$GREEN" "✓ Settings saved to $output_file"
                fi
                exit 0
                ;;
            --output)
                output_file="$2"
                shift 2
                ;;
            --list)
                list_presets
                exit 0
                ;;
            --compare)
                compare_presets
                exit 0
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                print_color "$RED" "Error: Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

main "$@"
