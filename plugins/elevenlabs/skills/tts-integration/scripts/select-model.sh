#!/usr/bin/env bash
# Model selection helper for ElevenLabs TTS
# Helps choose the right voice model based on use case, priority, or requirements

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Model definitions
declare -A MODELS
MODELS["eleven_v3"]="Eleven v3 (Alpha)|Most emotionally expressive|70+|3000|High|Standard|Character dialogues, audiobooks, multilingual narratives"
MODELS["eleven_multilingual_v2"]="Eleven Multilingual v2|Quality & Consistency|29|10000|High|Standard|Professional content, e-learning, gaming voiceovers"
MODELS["eleven_flash_v2_5"]="Eleven Flash v2.5|Ultra-low latency (~75ms)|32|40000|Ultra-low|50% lower|Real-time agents, interactive apps, bulk processing"
MODELS["eleven_turbo_v2_5"]="Eleven Turbo v2.5|Balanced quality & speed|32|40000|Low (250-300ms)|Standard|General-purpose applications"

# Function to print colored output
print_color() {
    local color=$1
    shift
    echo -e "${color}$*${NC}"
}

# Function to print model info
print_model_info() {
    local model_id=$1
    local info="${MODELS[$model_id]}"
    IFS='|' read -r name feature langs chars latency cost use_case <<< "$info"

    echo ""
    print_color "$BLUE" "═══════════════════════════════════════════════════════════════"
    print_color "$GREEN" "Model: $model_id"
    print_color "$BLUE" "═══════════════════════════════════════════════════════════════"
    echo "Name:              $name"
    echo "Key Feature:       $feature"
    echo "Languages:         $langs"
    echo "Character Limit:   $chars characters"
    echo "Latency:          $latency"
    echo "Cost:             $cost"
    echo "Best For:         $use_case"
    print_color "$BLUE" "═══════════════════════════════════════════════════════════════"
    echo ""
}

# Function to select by priority
select_by_priority() {
    local priority=$1
    case "$priority" in
        speed|latency|fast)
            echo "eleven_flash_v2_5"
            ;;
        quality|best|premium)
            echo "eleven_multilingual_v2"
            ;;
        balanced|general|moderate)
            echo "eleven_turbo_v2_5"
            ;;
        expressive|emotional|character)
            echo "eleven_v3"
            ;;
        cost|budget|cheap)
            echo "eleven_flash_v2_5"
            ;;
        *)
            print_color "$RED" "Unknown priority: $priority"
            print_color "$YELLOW" "Valid priorities: speed, quality, balanced, expressive, cost"
            exit 1
            ;;
    esac
}

# Function to select by use case
select_by_use_case() {
    local use_case=$(echo "$1" | tr '[:upper:]' '[:lower:]')

    case "$use_case" in
        *"real-time"*|*"interactive"*|*"chat"*|*"conversation"*)
            echo "eleven_flash_v2_5"
            ;;
        *"audiobook"*|*"character"*|*"dialogue"*|*"story"*)
            echo "eleven_v3"
            ;;
        *"professional"*|*"e-learning"*|*"training"*|*"course"*)
            echo "eleven_multilingual_v2"
            ;;
        *"customer service"*|*"ivr"*|*"phone"*|*"support"*)
            echo "eleven_turbo_v2_5"
            ;;
        *"bulk"*|*"batch"*|*"volume"*|*"mass"*)
            echo "eleven_flash_v2_5"
            ;;
        *"marketing"*|*"advertisement"*|*"promo"*)
            echo "eleven_turbo_v2_5"
            ;;
        *"gaming"*|*"voiceover"*|*"game"*)
            echo "eleven_multilingual_v2"
            ;;
        *"podcast"*|*"narration"*|*"documentary"*)
            echo "eleven_multilingual_v2"
            ;;
        *)
            print_color "$YELLOW" "No specific match for use case. Recommending balanced option..."
            echo "eleven_turbo_v2_5"
            ;;
    esac
}

# Function for interactive selection
interactive_selection() {
    print_color "$BLUE" "ElevenLabs Model Selection Wizard"
    print_color "$BLUE" "═══════════════════════════════════════════════════════════════"
    echo ""

    # Question 1: Priority
    echo "What is your primary priority?"
    echo "1) Speed/Latency (fastest generation)"
    echo "2) Quality (best audio quality)"
    echo "3) Balanced (good quality and speed)"
    echo "4) Expressiveness (most emotional range)"
    echo "5) Cost (budget-friendly)"
    read -p "Enter choice (1-5): " priority_choice

    # Question 2: Use case
    echo ""
    echo "What is your primary use case?"
    echo "1) Real-time/Interactive (chatbots, live agents)"
    echo "2) Audiobooks/Stories (character dialogues)"
    echo "3) Professional Content (e-learning, training)"
    echo "4) Customer Service (IVR, support systems)"
    echo "5) Bulk Processing (large volumes)"
    echo "6) Marketing/Advertisements"
    read -p "Enter choice (1-6): " usecase_choice

    # Question 3: Character length
    echo ""
    echo "What is your typical text length?"
    echo "1) Short (< 3,000 characters)"
    echo "2) Medium (3,000 - 10,000 characters)"
    echo "3) Long (> 10,000 characters)"
    read -p "Enter choice (1-3): " length_choice

    # Question 4: Language support
    echo ""
    read -p "Do you need multilingual support (70+ languages)? (y/n): " multilang

    echo ""
    print_color "$YELLOW" "Analyzing your requirements..."
    echo ""

    # Scoring system
    declare -A scores
    scores["eleven_v3"]=0
    scores["eleven_multilingual_v2"]=0
    scores["eleven_flash_v2_5"]=0
    scores["eleven_turbo_v2_5"]=0

    # Priority scoring
    case $priority_choice in
        1) scores["eleven_flash_v2_5"]=$((scores["eleven_flash_v2_5"] + 5)) ;;
        2) scores["eleven_multilingual_v2"]=$((scores["eleven_multilingual_v2"] + 5)) ;;
        3) scores["eleven_turbo_v2_5"]=$((scores["eleven_turbo_v2_5"] + 5)) ;;
        4) scores["eleven_v3"]=$((scores["eleven_v3"] + 5)) ;;
        5) scores["eleven_flash_v2_5"]=$((scores["eleven_flash_v2_5"] + 5)) ;;
    esac

    # Use case scoring
    case $usecase_choice in
        1) scores["eleven_flash_v2_5"]=$((scores["eleven_flash_v2_5"] + 4)) ;;
        2) scores["eleven_v3"]=$((scores["eleven_v3"] + 4)) ;;
        3) scores["eleven_multilingual_v2"]=$((scores["eleven_multilingual_v2"] + 4)) ;;
        4) scores["eleven_turbo_v2_5"]=$((scores["eleven_turbo_v2_5"] + 4)) ;;
        5) scores["eleven_flash_v2_5"]=$((scores["eleven_flash_v2_5"] + 4)) ;;
        6) scores["eleven_turbo_v2_5"]=$((scores["eleven_turbo_v2_5"] + 4)) ;;
    esac

    # Length scoring (penalize models with insufficient limits)
    case $length_choice in
        1)
            # All models work
            ;;
        2)
            # v3 has 3K limit, might be tight
            scores["eleven_v3"]=$((scores["eleven_v3"] - 2))
            ;;
        3)
            # v3 won't work, v2 might be tight
            scores["eleven_v3"]=$((scores["eleven_v3"] - 10))
            scores["eleven_multilingual_v2"]=$((scores["eleven_multilingual_v2"] - 1))
            scores["eleven_flash_v2_5"]=$((scores["eleven_flash_v2_5"] + 2))
            scores["eleven_turbo_v2_5"]=$((scores["eleven_turbo_v2_5"] + 2))
            ;;
    esac

    # Multilingual scoring
    if [[ "$multilang" == "y" || "$multilang" == "Y" ]]; then
        scores["eleven_v3"]=$((scores["eleven_v3"] + 3))
    fi

    # Find highest score
    local max_score=0
    local selected_model=""
    for model in "${!scores[@]}"; do
        if (( scores[$model] > max_score )); then
            max_score=${scores[$model]}
            selected_model=$model
        fi
    done

    print_color "$GREEN" "Recommended Model: $selected_model"
    print_model_info "$selected_model"

    # Show alternatives
    print_color "$YELLOW" "Alternative Options:"
    for model in "${!scores[@]}"; do
        if [[ "$model" != "$selected_model" ]]; then
            echo "  - $model (score: ${scores[$model]})"
        fi
    done
    echo ""

    echo "$selected_model"
}

# Function to compare all models
compare_models() {
    print_color "$BLUE" "ElevenLabs Voice Models Comparison"
    print_color "$BLUE" "═══════════════════════════════════════════════════════════════"
    echo ""

    printf "%-25s %-20s %-12s %-15s %-20s\n" "Model" "Key Feature" "Languages" "Char Limit" "Latency"
    print_color "$BLUE" "───────────────────────────────────────────────────────────────────────────────────────────────"

    for model_id in "${!MODELS[@]}"; do
        local info="${MODELS[$model_id]}"
        IFS='|' read -r name feature langs chars latency cost use_case <<< "$info"
        printf "%-25s %-20s %-12s %-15s %-20s\n" "$model_id" "$feature" "$langs" "$chars" "$latency"
    done

    echo ""
}

# Function to show usage
show_usage() {
    cat << EOF
ElevenLabs Voice Model Selection Helper

Usage:
    $(basename "$0") [OPTIONS]

Options:
    --interactive               Interactive model selection wizard
    --priority PRIORITY         Select by priority (speed|quality|balanced|expressive|cost)
    --use-case "USE_CASE"      Select by use case description
    --info MODEL_ID            Show detailed info for specific model
    --compare                  Compare all models side-by-side
    --list                     List all available models
    --help                     Show this help message

Examples:
    # Interactive selection
    $(basename "$0") --interactive

    # Quick selection by priority
    $(basename "$0") --priority speed
    $(basename "$0") --priority quality

    # Selection by use case
    $(basename "$0") --use-case "real-time chatbot"
    $(basename "$0") --use-case "audiobook narration"

    # Get model information
    $(basename "$0") --info eleven_flash_v2_5

    # Compare all models
    $(basename "$0") --compare

Model IDs:
    eleven_v3               - Most emotionally expressive (Alpha)
    eleven_multilingual_v2  - Quality & consistency
    eleven_flash_v2_5       - Ultra-low latency
    eleven_turbo_v2_5       - Balanced quality & speed

EOF
}

# Main script logic
main() {
    if [[ $# -eq 0 ]]; then
        show_usage
        exit 0
    fi

    case "$1" in
        --interactive)
            interactive_selection
            ;;
        --priority)
            if [[ $# -lt 2 ]]; then
                print_color "$RED" "Error: --priority requires an argument"
                exit 1
            fi
            model=$(select_by_priority "$2")
            print_color "$GREEN" "Selected Model: $model"
            print_model_info "$model"
            echo "$model"
            ;;
        --use-case)
            if [[ $# -lt 2 ]]; then
                print_color "$RED" "Error: --use-case requires an argument"
                exit 1
            fi
            model=$(select_by_use_case "$2")
            print_color "$GREEN" "Selected Model: $model"
            print_model_info "$model"
            echo "$model"
            ;;
        --info)
            if [[ $# -lt 2 ]]; then
                print_color "$RED" "Error: --info requires a model ID"
                exit 1
            fi
            if [[ -z "${MODELS[$2]:-}" ]]; then
                print_color "$RED" "Error: Unknown model ID: $2"
                exit 1
            fi
            print_model_info "$2"
            ;;
        --compare)
            compare_models
            ;;
        --list)
            print_color "$BLUE" "Available Models:"
            for model_id in "${!MODELS[@]}"; do
                echo "  - $model_id"
            done
            ;;
        --help)
            show_usage
            ;;
        *)
            print_color "$RED" "Error: Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
}

main "$@"
