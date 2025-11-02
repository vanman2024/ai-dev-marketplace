#!/bin/bash
# Model Compatibility Checker
# Validates if a model name is supported by the specified provider

set -e

PROVIDER=${1:-""}
MODEL=${2:-""}

if [ -z "$PROVIDER" ] || [ -z "$MODEL" ]; then
    echo "Usage: $0 <provider> <model>"
    echo "Example: $0 openai gpt-4"
    exit 1
fi

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "🔍 Checking model compatibility..."
echo "   Provider: $PROVIDER"
echo "   Model: $MODEL"
echo ""

# Define supported models for each provider
declare -A PROVIDER_MODELS

PROVIDER_MODELS[openai]="gpt-4o gpt-4o-mini gpt-4 gpt-4-turbo gpt-3.5-turbo o1-preview o1-mini"
PROVIDER_MODELS[anthropic]="claude-sonnet-4-5-20250929 claude-opus-4-20250514 claude-3-sonnet-20240229 claude-haiku-4-20250514 claude-3-5-haiku-20241022"
PROVIDER_MODELS[google]="gemini-1.5-pro gemini-1.5-flash gemini-1.0-pro gemini-2.0-flash-exp"
PROVIDER_MODELS[xai]="grok-beta grok-vision-beta grok-2-latest"
PROVIDER_MODELS[groq]="llama-3.1-70b-versatile llama-3.1-8b-instant mixtral-8x7b-32768 gemma-7b-it"
PROVIDER_MODELS[mistral]="mistral-large-latest mistral-medium-latest mistral-small-latest open-mistral-7b"
PROVIDER_MODELS[cohere]="command-r-plus command-r command command-light"
PROVIDER_MODELS[deepseek]="deepseek-chat deepseek-coder"

# Check if provider is supported
if [ -z "${PROVIDER_MODELS[$PROVIDER]}" ]; then
    echo -e "${RED}❌ Unknown provider: $PROVIDER${NC}"
    echo ""
    echo "Supported providers:"
    for p in "${!PROVIDER_MODELS[@]}"; do
        echo "  - $p"
    done
    exit 1
fi

# Check if model is supported
SUPPORTED_MODELS="${PROVIDER_MODELS[$PROVIDER]}"
MODEL_FOUND=false

for valid_model in $SUPPORTED_MODELS; do
    if [ "$MODEL" = "$valid_model" ]; then
        MODEL_FOUND=true
        break
    fi
done

if [ "$MODEL_FOUND" = true ]; then
    echo -e "${GREEN}✅ Model '$MODEL' is supported by $PROVIDER${NC}"
    echo ""

    # Provide additional info based on model
    case "$MODEL" in
        gpt-4o*)
            echo "ℹ️  GPT-4o models support:"
            echo "   - Text and vision"
            echo "   - Function/tool calling"
            echo "   - 128K context window"
            ;;
        claude-sonnet-4*)
            echo "ℹ️  Claude 3.5 Sonnet supports:"
            echo "   - Text and vision"
            echo "   - Tool use"
            echo "   - 200K context window"
            echo "   - Computer use (beta)"
            ;;
        gemini-1.5-pro)
            echo "ℹ️  Gemini 1.5 Pro supports:"
            echo "   - Text, image, video, audio"
            echo "   - Function calling"
            echo "   - 2M context window"
            ;;
    esac

    exit 0
else
    echo -e "${RED}❌ Model '$MODEL' is NOT supported by $PROVIDER${NC}"
    echo ""
    echo -e "${BLUE}📋 Valid models for $PROVIDER:${NC}"
    echo ""

    # Show models in a nice format
    for valid_model in $SUPPORTED_MODELS; do
        echo "  • $valid_model"
    done
    echo ""

    # Suggest closest match
    echo -e "${YELLOW}💡 Did you mean?${NC}"
    for valid_model in $SUPPORTED_MODELS; do
        # Simple similarity check (contains substring)
        if [[ "$valid_model" == *"${MODEL:0:5}"* ]] || [[ "$MODEL" == *"${valid_model:0:5}"* ]]; then
            echo "  → $valid_model"
        fi
    done
    echo ""

    # Provider documentation link
    echo "📚 Documentation:"
    case "$PROVIDER" in
        openai)
            echo "   https://ai-sdk.dev/providers/ai-sdk-providers/openai"
            ;;
        anthropic)
            echo "   https://ai-sdk.dev/providers/ai-sdk-providers/anthropic"
            ;;
        google)
            echo "   https://ai-sdk.dev/providers/ai-sdk-providers/google-generative-ai"
            ;;
        xai)
            echo "   https://ai-sdk.dev/providers/ai-sdk-providers/xai"
            ;;
        groq)
            echo "   https://ai-sdk.dev/providers/ai-sdk-providers/groq"
            ;;
        mistral)
            echo "   https://ai-sdk.dev/providers/ai-sdk-providers/mistral"
            ;;
        cohere)
            echo "   https://ai-sdk.dev/providers/ai-sdk-providers/cohere"
            ;;
        deepseek)
            echo "   https://ai-sdk.dev/providers/ai-sdk-providers/deepseek"
            ;;
    esac

    exit 1
fi
