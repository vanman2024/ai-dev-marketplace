#!/bin/bash
# Setup ML training example project
# Usage: ./setup-example.sh <project-name>

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
EXAMPLES_DIR="$SKILL_DIR/examples"

# Project name from argument
PROJECT_NAME="$1"

# Validate input
if [ -z "$PROJECT_NAME" ]; then
    echo -e "${RED}Error: Project name required${NC}"
    echo "Usage: $0 <project-name>"
    echo ""
    echo "Available projects:"
    echo "  - sentiment-classification"
    echo "  - text-generation"
    echo "  - redai-trade-classifier"
    exit 1
fi

# Check if project exists in examples
if [ ! -d "$EXAMPLES_DIR/$PROJECT_NAME" ]; then
    echo -e "${RED}Error: Project '$PROJECT_NAME' not found${NC}"
    echo ""
    echo "Available projects:"
    ls -1 "$EXAMPLES_DIR" | sed 's/^/  - /'
    exit 1
fi

echo -e "${GREEN}Setting up $PROJECT_NAME example...${NC}"
echo ""

# Create project directory in current location
TARGET_DIR="$(pwd)/$PROJECT_NAME"

if [ -d "$TARGET_DIR" ]; then
    echo -e "${YELLOW}Warning: Directory $TARGET_DIR already exists${NC}"
    read -p "Overwrite? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Setup cancelled"
        exit 0
    fi
    rm -rf "$TARGET_DIR"
fi

# Copy example files
echo "📂 Copying project files..."
cp -r "$EXAMPLES_DIR/$PROJECT_NAME" "$TARGET_DIR"
echo -e "${GREEN}✓ Files copied to $TARGET_DIR${NC}"

# Navigate to project directory
cd "$TARGET_DIR"

# Check for Python
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Error: Python 3 not found${NC}"
    echo "Please install Python 3.8 or higher"
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
echo "🐍 Using Python $PYTHON_VERSION"

# Create virtual environment
if [ ! -d "venv" ]; then
    echo "🔧 Creating virtual environment..."
    python3 -m venv venv
    echo -e "${GREEN}✓ Virtual environment created${NC}"
else
    echo -e "${YELLOW}Virtual environment already exists${NC}"
fi

# Activate virtual environment
source venv/bin/activate

# Upgrade pip
echo "📦 Upgrading pip..."
pip install --upgrade pip -q

# Install dependencies
if [ -f "requirements.txt" ]; then
    echo "📦 Installing dependencies..."
    pip install -r requirements.txt -q
    echo -e "${GREEN}✓ Dependencies installed${NC}"
else
    echo -e "${YELLOW}Warning: No requirements.txt found${NC}"
fi

# Project-specific setup
case "$PROJECT_NAME" in
    sentiment-classification)
        echo "🤖 Downloading DistilBERT model..."
        python3 -c "from transformers import AutoTokenizer, AutoModelForSequenceClassification; AutoTokenizer.from_pretrained('distilbert-base-uncased'); AutoModelForSequenceClassification.from_pretrained('distilbert-base-uncased')" 2>/dev/null || echo -e "${YELLOW}Model will be downloaded on first run${NC}"
        echo -e "${GREEN}✓ Sentiment classification ready${NC}"
        ;;

    text-generation)
        echo "🤖 Downloading GPT-2 model..."
        python3 -c "from transformers import AutoTokenizer, AutoModelForCausalLM; AutoTokenizer.from_pretrained('gpt2'); AutoModelForCausalLM.from_pretrained('gpt2')" 2>/dev/null || echo -e "${YELLOW}Model will be downloaded on first run${NC}"
        echo -e "${GREEN}✓ Text generation ready${NC}"
        ;;

    redai-trade-classifier)
        echo "📈 Validating trading data format..."
        if [ -f "sample_data.csv" ]; then
            echo -e "${GREEN}✓ Sample data found${NC}"
        else
            echo -e "${YELLOW}Warning: No sample_data.csv found${NC}"
            echo "You'll need to provide market data in CSV format"
        fi
        echo -e "${GREEN}✓ Trade classifier ready${NC}"
        ;;
esac

# Check for GPU
if command -v nvidia-smi &> /dev/null; then
    GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader | head -n1)
    echo -e "${GREEN}🎮 GPU detected: $GPU_NAME${NC}"
else
    echo -e "${YELLOW}⚠️  No GPU detected - training will use CPU (slower)${NC}"
fi

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    cat > .env << 'EOF'
# ML Training Configuration
MODEL_DIR=./models
DATA_DIR=./data
CHECKPOINT_DIR=./checkpoints

# Training parameters
BATCH_SIZE=8
LEARNING_RATE=2e-5
NUM_EPOCHS=3

# Inference
INFERENCE_PORT=8000
EOF
    echo -e "${GREEN}✓ Created .env file${NC}"
fi

# Print next steps
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Setup complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "📍 Project location: $TARGET_DIR"
echo ""
echo "Next steps:"
echo "  1. cd $PROJECT_NAME"
echo "  2. source venv/bin/activate"
echo "  3. Review README.md for usage instructions"
echo "  4. Run training: python train.py"
echo ""
echo "Quick start:"
echo "  Training:  python train.py"
echo "  Inference: python inference.py  (after training)"
echo ""
echo -e "${YELLOW}💡 Tip: Check README.md for detailed documentation${NC}"
