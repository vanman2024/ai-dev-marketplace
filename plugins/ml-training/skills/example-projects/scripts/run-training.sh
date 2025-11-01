#!/bin/bash
# Run training for ML example project
# Usage: ./run-training.sh <project-name>

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_NAME="$1"

if [ -z "$PROJECT_NAME" ]; then
    echo -e "${RED}Error: Project name required${NC}"
    echo "Usage: $0 <project-name>"
    exit 1
fi

# Check if project directory exists
if [ ! -d "$PROJECT_NAME" ]; then
    echo -e "${RED}Error: Project directory '$PROJECT_NAME' not found${NC}"
    echo "Run setup-example.sh first to create the project"
    exit 1
fi

cd "$PROJECT_NAME"

# Check for virtual environment
if [ ! -d "venv" ]; then
    echo -e "${RED}Error: Virtual environment not found${NC}"
    echo "Run setup-example.sh first to set up the project"
    exit 1
fi

# Activate virtual environment
source venv/bin/activate

# Load environment variables if .env exists
if [ -f ".env" ]; then
    set -a
    source .env
    set +a
fi

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Training $PROJECT_NAME${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check for GPU
if command -v nvidia-smi &> /dev/null; then
    echo -e "${BLUE}GPU Status:${NC}"
    nvidia-smi --query-gpu=index,name,utilization.gpu,memory.used,memory.total --format=csv,noheader | while read line; do
        echo "  GPU: $line"
    done
    echo ""
    USE_GPU="--device cuda"
else
    echo -e "${YELLOW}⚠️  No GPU detected - using CPU${NC}"
    echo ""
    USE_GPU="--device cpu"
fi

# Create directories if they don't exist
mkdir -p models checkpoints logs

# Start training with monitoring
echo -e "${BLUE}Starting training...${NC}"
echo ""

# Training script location
TRAIN_SCRIPT="train.py"

if [ ! -f "$TRAIN_SCRIPT" ]; then
    echo -e "${RED}Error: train.py not found${NC}"
    exit 1
fi

# Run training with timestamp and logging
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="logs/training_${TIMESTAMP}.log"

echo "📝 Logging to: $LOG_FILE"
echo ""

# Function to monitor training
monitor_training() {
    local pid=$1
    local log=$2

    # Show real-time log output
    tail -f "$log" &
    TAIL_PID=$!

    # Wait for training to complete
    wait $pid
    TRAIN_EXIT_CODE=$?

    # Stop tail
    kill $TAIL_PID 2>/dev/null

    return $TRAIN_EXIT_CODE
}

# Start training in background and monitor
if [ -f "config.yaml" ]; then
    # Training with config file
    python "$TRAIN_SCRIPT" --config config.yaml $USE_GPU 2>&1 | tee "$LOG_FILE" &
else
    # Training with default parameters
    python "$TRAIN_SCRIPT" $USE_GPU 2>&1 | tee "$LOG_FILE" &
fi

TRAIN_PID=$!

# Wait for training
wait $TRAIN_PID
EXIT_CODE=$?

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✓ Training completed successfully!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Find latest checkpoint
    if [ -d "checkpoints" ] && [ "$(ls -A checkpoints)" ]; then
        LATEST_CHECKPOINT=$(ls -t checkpoints | head -n1)
        echo "📦 Latest checkpoint: checkpoints/$LATEST_CHECKPOINT"
    fi

    if [ -d "models" ] && [ "$(ls -A models)" ]; then
        LATEST_MODEL=$(ls -t models | head -n1)
        echo "🤖 Latest model: models/$LATEST_MODEL"
    fi

    echo "📊 Training log: $LOG_FILE"
    echo ""
    echo "Next steps:"
    echo "  1. Test inference: python inference.py"
    echo "  2. Review logs: cat $LOG_FILE"
    echo "  3. Deploy model: python modal_deploy.py (if available)"

else
    echo -e "${RED}✗ Training failed with exit code $EXIT_CODE${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Check the log file for details:"
    echo "  cat $LOG_FILE"
    echo ""
    echo "Common issues:"
    echo "  - Out of memory: Reduce batch size in config"
    echo "  - CUDA error: Check GPU drivers with nvidia-smi"
    echo "  - Data not found: Verify data files exist"
    exit 1
fi

# Training summary
echo ""
echo -e "${BLUE}Training Summary:${NC}"
echo "  Project: $PROJECT_NAME"
echo "  Duration: $(grep -o 'Training time:.*' "$LOG_FILE" | tail -n1 || echo 'See log file')"
echo "  Device: $(echo $USE_GPU | cut -d' ' -f2)"

if grep -q "Final accuracy" "$LOG_FILE"; then
    echo "  Final accuracy: $(grep 'Final accuracy' "$LOG_FILE" | tail -n1 | awk '{print $NF}')"
fi

if grep -q "Final loss" "$LOG_FILE"; then
    echo "  Final loss: $(grep 'Final loss' "$LOG_FILE" | tail -n1 | awk '{print $NF}')"
fi

echo ""
echo -e "${GREEN}✓ All done!${NC}"
