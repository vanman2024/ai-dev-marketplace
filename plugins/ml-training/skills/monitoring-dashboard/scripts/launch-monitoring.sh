#!/bin/bash
# Launch monitoring dashboards (TensorBoard, WandB, or both)
# Usage: ./launch-monitoring.sh <tensorboard|wandb|both> [options]

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
MODE=""
LOGDIR="./runs"
PORT=6006
WANDB_PROJECT=""
BACKGROUND=false

# Parse arguments
show_usage() {
    echo "Usage: $0 <tensorboard|wandb|both> [options]"
    echo ""
    echo "Modes:"
    echo "  tensorboard    Launch TensorBoard only"
    echo "  wandb          Open WandB dashboard only"
    echo "  both           Launch TensorBoard and open WandB"
    echo ""
    echo "Options:"
    echo "  --logdir PATH      TensorBoard log directory (default: ./runs)"
    echo "  --port PORT        TensorBoard port (default: 6006)"
    echo "  --project NAME     WandB project name"
    echo "  --background       Run TensorBoard in background"
    echo "  --help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 tensorboard --logdir ./logs --port 6007"
    echo "  $0 wandb --project my-ml-project"
    echo "  $0 both --logdir ./runs --project my-project --background"
}

if [ $# -eq 0 ]; then
    show_usage
    exit 1
fi

MODE=$1
shift

# Parse options
while [[ $# -gt 0 ]]; do
    case $1 in
        --logdir)
            LOGDIR="$2"
            shift 2
            ;;
        --port)
            PORT="$2"
            shift 2
            ;;
        --project)
            WANDB_PROJECT="$2"
            shift 2
            ;;
        --background)
            BACKGROUND=true
            shift
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Unknown option $1${NC}"
            show_usage
            exit 1
            ;;
    esac
done

# Validate mode
if [[ ! "$MODE" =~ ^(tensorboard|wandb|both)$ ]]; then
    echo -e "${RED}Error: Invalid mode '$MODE'${NC}"
    show_usage
    exit 1
fi

# Function to launch TensorBoard
launch_tensorboard() {
    echo -e "${YELLOW}Launching TensorBoard...${NC}"

    # Check if TensorBoard is installed
    if ! command -v tensorboard &> /dev/null && ! python3 -c "import tensorboard" 2>/dev/null; then
        echo -e "${RED}Error: TensorBoard is not installed${NC}"
        echo "Install with: pip install tensorboard"
        exit 1
    fi

    # Check if log directory exists
    if [ ! -d "$LOGDIR" ]; then
        echo -e "${YELLOW}Warning: Log directory '$LOGDIR' does not exist${NC}"
        read -p "Create it now? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            mkdir -p "$LOGDIR"
            echo -e "${GREEN}✓ Created $LOGDIR${NC}"
        else
            echo -e "${RED}Cannot launch TensorBoard without log directory${NC}"
            exit 1
        fi
    fi

    # Check if port is in use
    if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${YELLOW}Warning: Port $PORT is already in use${NC}"
        read -p "Kill existing process and continue? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            pkill -f "tensorboard.*--port $PORT" || true
            sleep 1
        else
            echo -e "${RED}Please use a different port with --port${NC}"
            exit 1
        fi
    fi

    # Launch TensorBoard
    echo -e "${GREEN}Starting TensorBoard...${NC}"
    echo "  Log directory: $LOGDIR"
    echo "  Port: $PORT"
    echo "  URL: http://localhost:$PORT"
    echo ""

    if [ "$BACKGROUND" = true ]; then
        nohup tensorboard --logdir "$LOGDIR" --port "$PORT" > /tmp/tensorboard.log 2>&1 &
        TB_PID=$!
        echo -e "${GREEN}✓ TensorBoard started in background (PID: $TB_PID)${NC}"
        echo "  View logs: tail -f /tmp/tensorboard.log"
        echo "  Stop: kill $TB_PID"
    else
        echo -e "${BLUE}Press Ctrl+C to stop TensorBoard${NC}"
        echo ""
        tensorboard --logdir "$LOGDIR" --port "$PORT"
    fi
}

# Function to open WandB dashboard
open_wandb() {
    echo -e "${YELLOW}Opening WandB dashboard...${NC}"

    # Check if WandB is installed
    if ! python3 -c "import wandb" 2>/dev/null; then
        echo -e "${RED}Error: WandB is not installed${NC}"
        echo "Install with: pip install wandb"
        exit 1
    fi

    # Check if logged in
    if ! python3 -c "import wandb; wandb.api.api_key" 2>/dev/null && [ -z "$WANDB_API_KEY" ]; then
        echo -e "${YELLOW}Warning: Not logged in to WandB${NC}"
        read -p "Login now? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            wandb login
        else
            echo -e "${YELLOW}You can login later with: wandb login${NC}"
        fi
    fi

    # Get username/entity
    ENTITY=$(python3 -c "import wandb; print(wandb.api.viewer()['entity'])" 2>/dev/null || echo "")

    if [ -z "$ENTITY" ]; then
        echo -e "${YELLOW}Could not determine WandB username${NC}"
        WANDB_URL="https://wandb.ai"
    elif [ -n "$WANDB_PROJECT" ]; then
        WANDB_URL="https://wandb.ai/$ENTITY/$WANDB_PROJECT"
    else
        WANDB_URL="https://wandb.ai/$ENTITY"
    fi

    echo -e "${GREEN}✓ Opening WandB dashboard${NC}"
    echo "  URL: $WANDB_URL"
    echo ""

    # Try to open browser
    if command -v xdg-open &> /dev/null; then
        xdg-open "$WANDB_URL" 2>/dev/null || echo "Please open: $WANDB_URL"
    elif command -v open &> /dev/null; then
        open "$WANDB_URL" 2>/dev/null || echo "Please open: $WANDB_URL"
    else
        echo "Please open in browser: $WANDB_URL"
    fi
}

# Execute based on mode
echo -e "${GREEN}=== Monitoring Dashboard Launcher ===${NC}\n"

case $MODE in
    tensorboard)
        launch_tensorboard
        ;;
    wandb)
        open_wandb
        ;;
    both)
        # Launch TensorBoard in background
        BACKGROUND=true
        launch_tensorboard
        echo ""
        # Open WandB
        open_wandb
        echo ""
        echo -e "${GREEN}=== Both dashboards are ready ===${NC}"
        echo "  TensorBoard: http://localhost:$PORT"
        echo "  WandB: $WANDB_URL"
        echo ""
        echo "To stop TensorBoard:"
        echo "  pkill -f tensorboard"
        ;;
esac

echo ""
echo -e "${GREEN}Done!${NC}"
