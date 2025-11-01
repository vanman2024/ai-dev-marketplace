#!/bin/bash
# Setup TensorBoard for ML training monitoring
# Installs TensorBoard, creates log directories, and verifies installation

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== TensorBoard Setup ===${NC}\n"

# Step 1: Check Python environment
echo -e "${YELLOW}[1/5] Checking Python environment...${NC}"
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Error: Python 3 is not installed${NC}"
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
echo -e "${GREEN}✓ Python ${PYTHON_VERSION} found${NC}\n"

# Step 2: Install TensorBoard
echo -e "${YELLOW}[2/5] Installing TensorBoard...${NC}"
if python3 -c "import tensorboard" 2>/dev/null; then
    TENSORBOARD_VERSION=$(python3 -c "import tensorboard; print(tensorboard.__version__)")
    echo -e "${GREEN}✓ TensorBoard ${TENSORBOARD_VERSION} already installed${NC}\n"
else
    echo "Installing TensorBoard..."
    pip install tensorboard --quiet
    TENSORBOARD_VERSION=$(python3 -c "import tensorboard; print(tensorboard.__version__)")
    echo -e "${GREEN}✓ TensorBoard ${TENSORBOARD_VERSION} installed${NC}\n"
fi

# Step 3: Install PyTorch TensorBoard support
echo -e "${YELLOW}[3/5] Installing PyTorch TensorBoard support...${NC}"
if python3 -c "import torch.utils.tensorboard" 2>/dev/null; then
    echo -e "${GREEN}✓ PyTorch TensorBoard support available${NC}\n"
else
    echo "Installing torch (if not present)..."
    pip install torch --quiet || echo -e "${YELLOW}Warning: Could not install torch. Install manually if needed.${NC}"
fi

# Step 4: Create default log directory structure
echo -e "${YELLOW}[4/5] Creating log directory structure...${NC}"
LOG_DIR="${LOG_DIR:-./runs}"

mkdir -p "$LOG_DIR"
mkdir -p "$LOG_DIR/experiments"
mkdir -p "$LOG_DIR/archive"

cat > "$LOG_DIR/.gitignore" << 'EOF'
# TensorBoard logs
events.out.tfevents.*
*.pb

# Checkpoints
*.ckpt
*.pth

# Keep directory structure
!.gitignore
EOF

echo -e "${GREEN}✓ Created log directories:${NC}"
echo "  - $LOG_DIR (main log directory)"
echo "  - $LOG_DIR/experiments (experiment logs)"
echo "  - $LOG_DIR/archive (archived runs)"
echo ""

# Step 5: Create sample TensorBoard configuration
echo -e "${YELLOW}[5/5] Creating sample configuration...${NC}"

cat > "$LOG_DIR/README.md" << 'EOF'
# TensorBoard Logs

This directory contains TensorBoard training logs.

## Quick Start

Launch TensorBoard:
```bash
tensorboard --logdir ./runs
```

Access dashboard: http://localhost:6006

## Directory Structure

- `experiments/` - Active experiment logs
- `archive/` - Archived/old experiment logs

## Best Practices

1. Use descriptive experiment names:
   - `experiment_resnet50_lr0.001_20240101`
   - `experiment_baseline_batch32`

2. Archive old experiments regularly:
   ```bash
   mv runs/experiments/old_experiment runs/archive/
   ```

3. Compare multiple experiments:
   ```bash
   tensorboard --logdir_spec \
     exp1:runs/experiments/experiment_1,\
     exp2:runs/experiments/experiment_2
   ```

## Cleanup

Remove old logs (older than 30 days):
```bash
find runs/archive -type d -mtime +30 -exec rm -rf {} +
```
EOF

echo -e "${GREEN}✓ Created README.md in $LOG_DIR${NC}\n"

# Create sample Python script
cat > "$LOG_DIR/example_usage.py" << 'EOF'
#!/usr/bin/env python3
"""
Example TensorBoard logging script
Usage: python3 example_usage.py
"""

from torch.utils.tensorboard import SummaryWriter
import numpy as np
import datetime

def main():
    # Create writer with timestamped log directory
    timestamp = datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
    log_dir = f"experiments/example_{timestamp}"
    writer = SummaryWriter(log_dir=log_dir)

    print(f"Logging to: {log_dir}")
    print("Launch TensorBoard: tensorboard --logdir ./runs")

    # Simulate training loop
    for epoch in range(10):
        # Simulate metrics
        train_loss = 1.0 / (epoch + 1) + np.random.randn() * 0.1
        val_loss = 1.2 / (epoch + 1) + np.random.randn() * 0.1
        train_acc = 1.0 - 1.0 / (epoch + 2) + np.random.randn() * 0.05
        val_acc = 1.0 - 1.2 / (epoch + 2) + np.random.randn() * 0.05

        # Log scalars
        writer.add_scalar('Loss/train', train_loss, epoch)
        writer.add_scalar('Loss/validation', val_loss, epoch)
        writer.add_scalar('Accuracy/train', train_acc, epoch)
        writer.add_scalar('Accuracy/validation', val_acc, epoch)

        print(f"Epoch {epoch}: train_loss={train_loss:.4f}, val_loss={val_loss:.4f}")

    writer.close()
    print(f"\n✓ Logged 10 epochs to {log_dir}")
    print("Open TensorBoard to view: http://localhost:6006")

if __name__ == "__main__":
    main()
EOF

chmod +x "$LOG_DIR/example_usage.py"
echo -e "${GREEN}✓ Created example_usage.py${NC}\n"

# Final verification
echo -e "${GREEN}=== Setup Complete ===${NC}\n"
echo "TensorBoard is ready to use!"
echo ""
echo "Quick Start:"
echo "  1. Run example: python3 $LOG_DIR/example_usage.py"
echo "  2. Launch TensorBoard: tensorboard --logdir $LOG_DIR"
echo "  3. Open browser: http://localhost:6006"
echo ""
echo "Directory Structure:"
echo "  $LOG_DIR/"
echo "  ├── experiments/     (active experiment logs)"
echo "  ├── archive/         (archived logs)"
echo "  ├── example_usage.py (example script)"
echo "  └── README.md        (documentation)"
echo ""

# Test TensorBoard command
if command -v tensorboard &> /dev/null; then
    echo -e "${GREEN}✓ TensorBoard command available${NC}"
    echo ""
    echo "To launch TensorBoard now, run:"
    echo "  tensorboard --logdir $LOG_DIR"
else
    echo -e "${YELLOW}Warning: tensorboard command not found in PATH${NC}"
    echo "You may need to add it to your PATH or use: python3 -m tensorboard.main"
fi

echo ""
echo -e "${GREEN}Setup completed successfully!${NC}"
