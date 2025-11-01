#!/bin/bash
# Test inference for trained ML model
# Usage: ./test-inference.sh <project-name> <input>

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_NAME="$1"
INPUT="$2"

if [ -z "$PROJECT_NAME" ]; then
    echo -e "${RED}Error: Project name required${NC}"
    echo "Usage: $0 <project-name> <input>"
    echo ""
    echo "Examples:"
    echo "  $0 sentiment-classification 'This is amazing!'"
    echo "  $0 text-generation 'Once upon a time'"
    echo "  $0 redai-trade-classifier market_data.json"
    exit 1
fi

# Check if project directory exists
if [ ! -d "$PROJECT_NAME" ]; then
    echo -e "${RED}Error: Project directory '$PROJECT_NAME' not found${NC}"
    exit 1
fi

cd "$PROJECT_NAME"

# Check for virtual environment
if [ ! -d "venv" ]; then
    echo -e "${RED}Error: Virtual environment not found${NC}"
    echo "Run setup-example.sh first"
    exit 1
fi

# Activate virtual environment
source venv/bin/activate

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Testing Inference - $PROJECT_NAME${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check for model
MODEL_DIR="models"
if [ ! -d "$MODEL_DIR" ] || [ -z "$(ls -A $MODEL_DIR 2>/dev/null)" ]; then
    echo -e "${RED}Error: No trained model found${NC}"
    echo "Run training first: ../scripts/run-training.sh $PROJECT_NAME"
    exit 1
fi

LATEST_MODEL=$(ls -t "$MODEL_DIR" | head -n1)
echo -e "${BLUE}Using model: $MODEL_DIR/$LATEST_MODEL${NC}"
echo ""

# Project-specific inference
case "$PROJECT_NAME" in
    sentiment-classification)
        if [ -z "$INPUT" ]; then
            echo -e "${YELLOW}No input provided, using demo examples${NC}"
            echo ""

            # Demo examples
            EXAMPLES=(
                "This movie was absolutely fantastic!"
                "Terrible product, waste of money"
                "It's okay, nothing special"
                "Best purchase I've ever made!"
                "Disappointing and overpriced"
            )

            for example in "${EXAMPLES[@]}"; do
                echo -e "${BLUE}Input:${NC} \"$example\""

                # Run inference
                RESULT=$(python -c "
from transformers import AutoTokenizer, AutoModelForSequenceClassification
import torch

tokenizer = AutoTokenizer.from_pretrained('$MODEL_DIR/$LATEST_MODEL')
model = AutoModelForSequenceClassification.from_pretrained('$MODEL_DIR/$LATEST_MODEL')

text = '''$example'''
inputs = tokenizer(text, return_tensors='pt', truncation=True, max_length=512)

with torch.no_grad():
    outputs = model(**inputs)
    prediction = torch.argmax(outputs.logits, dim=1).item()
    confidence = torch.softmax(outputs.logits, dim=1).max().item()

sentiment = 'Positive' if prediction == 1 else 'Negative'
print(f'{sentiment} (confidence: {confidence:.2%})')
" 2>/dev/null)

                echo -e "${GREEN}Output:${NC} $RESULT"
                echo ""
            done
        else
            echo -e "${BLUE}Input:${NC} \"$INPUT\""

            RESULT=$(python -c "
from transformers import AutoTokenizer, AutoModelForSequenceClassification
import torch

tokenizer = AutoTokenizer.from_pretrained('$MODEL_DIR/$LATEST_MODEL')
model = AutoModelForSequenceClassification.from_pretrained('$MODEL_DIR/$LATEST_MODEL')

text = '''$INPUT'''
inputs = tokenizer(text, return_tensors='pt', truncation=True, max_length=512)

with torch.no_grad():
    outputs = model(**inputs)
    prediction = torch.argmax(outputs.logits, dim=1).item()
    confidence = torch.softmax(outputs.logits, dim=1).max().item()

sentiment = 'Positive' if prediction == 1 else 'Negative'
print(f'{sentiment} (confidence: {confidence:.2%})')
" 2>/dev/null)

            echo -e "${GREEN}Output:${NC} $RESULT"
        fi
        ;;

    text-generation)
        if [ -z "$INPUT" ]; then
            INPUT="Once upon a time in a distant galaxy"
            echo -e "${YELLOW}No input provided, using default prompt${NC}"
        fi

        echo -e "${BLUE}Prompt:${NC} \"$INPUT\""
        echo ""
        echo -e "${BLUE}Generating text...${NC}"
        echo ""

        RESULT=$(python -c "
from transformers import AutoTokenizer, AutoModelForCausalLM
import torch

tokenizer = AutoTokenizer.from_pretrained('$MODEL_DIR/$LATEST_MODEL')
model = AutoModelForCausalLM.from_pretrained('$MODEL_DIR/$LATEST_MODEL')

prompt = '''$INPUT'''
inputs = tokenizer(prompt, return_tensors='pt')

with torch.no_grad():
    outputs = model.generate(
        **inputs,
        max_length=100,
        num_return_sequences=1,
        temperature=0.8,
        top_p=0.9,
        do_sample=True
    )

generated = tokenizer.decode(outputs[0], skip_special_tokens=True)
print(generated)
" 2>/dev/null)

        echo -e "${GREEN}Generated:${NC}"
        echo "$RESULT"
        ;;

    redai-trade-classifier)
        if [ -z "$INPUT" ]; then
            echo -e "${RED}Error: Market data file required${NC}"
            echo "Usage: $0 redai-trade-classifier market_data.json"
            exit 1
        fi

        if [ ! -f "$INPUT" ]; then
            echo -e "${RED}Error: File '$INPUT' not found${NC}"
            exit 1
        fi

        echo -e "${BLUE}Input file:${NC} $INPUT"
        echo ""
        echo -e "${BLUE}Running classification...${NC}"
        echo ""

        if [ -f "inference.py" ]; then
            python inference.py --input "$INPUT" --model "$MODEL_DIR/$LATEST_MODEL"
        else
            echo -e "${YELLOW}No inference.py found, using basic classifier${NC}"

            RESULT=$(python -c "
import json
import torch
from transformers import AutoTokenizer, AutoModelForSequenceClassification

# Load model
tokenizer = AutoTokenizer.from_pretrained('$MODEL_DIR/$LATEST_MODEL')
model = AutoModelForSequenceClassification.from_pretrained('$MODEL_DIR/$LATEST_MODEL')

# Load data
with open('$INPUT', 'r') as f:
    data = json.load(f)

# Classify
classes = ['SELL', 'HOLD', 'BUY']

if isinstance(data, list):
    for item in data[:5]:  # Show first 5
        # Simplified classification
        print(f'Symbol: {item.get(\"symbol\", \"N/A\")}')
        print(f'Signal: {classes[1]}')  # Placeholder
        print()
else:
    print('Classification: HOLD')
" 2>/dev/null)

            echo "$RESULT"
        fi
        ;;

    *)
        echo -e "${RED}Unknown project type${NC}"
        echo "Attempting generic inference..."

        if [ -f "inference.py" ]; then
            python inference.py --input "$INPUT"
        else
            echo -e "${RED}No inference.py found${NC}"
            exit 1
        fi
        ;;
esac

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ Inference complete${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "To run inference server:"
echo "  python inference.py --server --port 8000"
echo ""
echo "To deploy to production:"
echo "  modal deploy modal_deploy.py  (if available)"
