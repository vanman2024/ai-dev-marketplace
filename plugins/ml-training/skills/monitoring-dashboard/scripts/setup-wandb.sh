#!/bin/bash
# Setup Weights & Biases for ML training monitoring
# Installs WandB, configures API key, and verifies installation

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Weights & Biases (WandB) Setup ===${NC}\n"

# Step 1: Check Python environment
echo -e "${YELLOW}[1/5] Checking Python environment...${NC}"
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Error: Python 3 is not installed${NC}"
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
echo -e "${GREEN}✓ Python ${PYTHON_VERSION} found${NC}\n"

# Step 2: Install WandB
echo -e "${YELLOW}[2/5] Installing Weights & Biases...${NC}"
if python3 -c "import wandb" 2>/dev/null; then
    WANDB_VERSION=$(python3 -c "import wandb; print(wandb.__version__)")
    echo -e "${GREEN}✓ WandB ${WANDB_VERSION} already installed${NC}\n"
else
    echo "Installing wandb..."
    pip install wandb --quiet
    WANDB_VERSION=$(python3 -c "import wandb; print(wandb.__version__)")
    echo -e "${GREEN}✓ WandB ${WANDB_VERSION} installed${NC}\n"
fi

# Step 3: Check API key configuration
echo -e "${YELLOW}[3/5] Checking API key configuration...${NC}"

if [ -n "$WANDB_API_KEY" ]; then
    echo -e "${GREEN}✓ WANDB_API_KEY environment variable is set${NC}\n"
    API_KEY_CONFIGURED=true
elif python3 -c "import wandb; wandb.api.api_key" 2>/dev/null; then
    echo -e "${GREEN}✓ WandB API key is configured${NC}\n"
    API_KEY_CONFIGURED=true
else
    echo -e "${YELLOW}⚠ WandB API key not configured${NC}"
    echo ""
    echo "To configure WandB:"
    echo "  1. Sign up at https://wandb.ai/signup"
    echo "  2. Get your API key from https://wandb.ai/authorize"
    echo "  3. Run: wandb login"
    echo "  Or set environment variable: export WANDB_API_KEY=your_key"
    echo ""
    read -p "Do you want to login now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        wandb login
        API_KEY_CONFIGURED=true
    else
        echo -e "${YELLOW}Skipping API key configuration. You can configure it later with 'wandb login'${NC}\n"
        API_KEY_CONFIGURED=false
    fi
fi

# Step 4: Create WandB configuration directory
echo -e "${YELLOW}[4/5] Creating WandB configuration...${NC}"

WANDB_DIR="${WANDB_DIR:-./wandb}"
mkdir -p "$WANDB_DIR"

cat > "$WANDB_DIR/.gitignore" << 'EOF'
# WandB files
wandb/
*.wandb

# Offline runs
offline-*

# Debug logs
debug*.log

# Keep directory structure
!.gitignore
EOF

# Create settings file
cat > "$WANDB_DIR/settings" << 'EOF'
[default]
# WandB Settings
# Docs: https://docs.wandb.ai/guides/track/environment-variables

# Project defaults
# project = my-ml-project
# entity = my-team

# Logging
# mode = online  # online, offline, disabled
# silent = false

# Console output
# console = auto  # auto, wrap, redirect, off

# Symlink
# symlink = true
EOF

echo -e "${GREEN}✓ Created WandB configuration directory${NC}\n"

# Step 5: Create example scripts
echo -e "${YELLOW}[5/5] Creating example scripts...${NC}"

cat > "$WANDB_DIR/example_basic.py" << 'EOF'
#!/usr/bin/env python3
"""
Basic WandB logging example
Usage: python3 example_basic.py
"""

import wandb
import random
import math

def main():
    # Initialize WandB run
    run = wandb.init(
        project="wandb-example",
        name="basic-example",
        config={
            "learning_rate": 0.001,
            "epochs": 10,
            "batch_size": 32,
            "model": "example-model"
        }
    )

    print(f"Run ID: {run.id}")
    print(f"Project: {run.project}")
    print(f"Dashboard: {run.url}")

    # Simulate training loop
    for epoch in range(10):
        # Simulate metrics
        train_loss = 1.0 / (epoch + 1) + random.random() * 0.1
        val_loss = 1.2 / (epoch + 1) + random.random() * 0.1
        train_acc = 1.0 - 1.0 / (epoch + 2) + random.random() * 0.05
        val_acc = 1.0 - 1.2 / (epoch + 2) + random.random() * 0.05

        # Log metrics
        wandb.log({
            "epoch": epoch,
            "train/loss": train_loss,
            "train/accuracy": train_acc,
            "val/loss": val_loss,
            "val/accuracy": val_acc,
            "learning_rate": 0.001 * math.exp(-epoch * 0.1)
        })

        print(f"Epoch {epoch}: train_loss={train_loss:.4f}, val_loss={val_loss:.4f}")

    # Finish run
    wandb.finish()
    print(f"\n✓ Run completed! View at: {run.url}")

if __name__ == "__main__":
    main()
EOF

chmod +x "$WANDB_DIR/example_basic.py"

cat > "$WANDB_DIR/example_sweep.py" << 'EOF'
#!/usr/bin/env python3
"""
WandB hyperparameter sweep example
Usage: python3 example_sweep.py
"""

import wandb
import random

def train():
    """Training function for sweep"""
    # Initialize run (sweep agent will set config)
    run = wandb.init()

    # Access hyperparameters
    config = wandb.config
    lr = config.learning_rate
    batch_size = config.batch_size

    print(f"Training with lr={lr}, batch_size={batch_size}")

    # Simulate training
    for epoch in range(5):
        # Simulate metrics based on hyperparameters
        loss = 1.0 / (epoch + 1) * (1.0 / lr) + random.random() * 0.1
        acc = (1.0 - 1.0 / (epoch + 2)) * (batch_size / 64.0) + random.random() * 0.05

        wandb.log({
            "epoch": epoch,
            "loss": loss,
            "accuracy": acc
        })

    wandb.finish()

def main():
    # Define sweep configuration
    sweep_config = {
        'method': 'bayes',  # bayes, grid, random
        'metric': {
            'name': 'loss',
            'goal': 'minimize'
        },
        'parameters': {
            'learning_rate': {
                'min': 0.0001,
                'max': 0.1
            },
            'batch_size': {
                'values': [16, 32, 64]
            }
        }
    }

    # Initialize sweep
    sweep_id = wandb.sweep(
        sweep_config,
        project="wandb-sweep-example"
    )

    print(f"Sweep ID: {sweep_id}")
    print(f"Starting sweep agent...")

    # Run sweep agent (run 5 trials)
    wandb.agent(sweep_id, function=train, count=5)

    print(f"\n✓ Sweep completed!")
    print(f"View results at: https://wandb.ai/sweeps/{sweep_id}")

if __name__ == "__main__":
    main()
EOF

chmod +x "$WANDB_DIR/example_sweep.py"

cat > "$WANDB_DIR/README.md" << 'EOF'
# Weights & Biases (WandB) Configuration

This directory contains WandB configuration and examples.

## Quick Start

1. Login to WandB:
   ```bash
   wandb login
   ```

2. Run basic example:
   ```bash
   python3 example_basic.py
   ```

3. Run hyperparameter sweep:
   ```bash
   python3 example_sweep.py
   ```

## Environment Variables

```bash
# API Key
export WANDB_API_KEY=your_api_key

# Default project
export WANDB_PROJECT=my-project

# Default entity (team/username)
export WANDB_ENTITY=my-team

# Mode (online, offline, disabled)
export WANDB_MODE=online

# Silence console output
export WANDB_SILENT=true
```

## Configuration File

Edit `settings` file to set default project, entity, and other options.

## Offline Mode

Run experiments offline and sync later:

```python
import wandb

# Run offline
wandb.init(mode="offline")
# ... training code ...
wandb.finish()

# Sync later
wandb.sync ./wandb/offline-run-*
```

## Best Practices

1. Use hierarchical metric names: `train/loss`, `val/loss`
2. Tag runs for easy filtering
3. Use sweeps for hyperparameter optimization
4. Save model artifacts for reproducibility
5. Add alerts for important metrics

## Resources

- Dashboard: https://wandb.ai
- Documentation: https://docs.wandb.ai
- Examples: https://github.com/wandb/examples
EOF

echo -e "${GREEN}✓ Created example scripts and documentation${NC}\n"

# Final summary
echo -e "${GREEN}=== Setup Complete ===${NC}\n"
echo "WandB is ready to use!"
echo ""

if [ "$API_KEY_CONFIGURED" = true ]; then
    echo -e "${GREEN}✓ API key is configured${NC}"
else
    echo -e "${YELLOW}⚠ API key not configured yet${NC}"
    echo "  Run: wandb login"
fi

echo ""
echo "Quick Start:"
echo "  1. Run basic example: python3 $WANDB_DIR/example_basic.py"
echo "  2. Run sweep example: python3 $WANDB_DIR/example_sweep.py"
echo "  3. View dashboard: https://wandb.ai"
echo ""
echo "Directory Structure:"
echo "  $WANDB_DIR/"
echo "  ├── example_basic.py  (basic logging example)"
echo "  ├── example_sweep.py  (hyperparameter sweep example)"
echo "  ├── settings          (WandB configuration)"
echo "  └── README.md         (documentation)"
echo ""

# Test WandB command
if command -v wandb &> /dev/null; then
    echo -e "${GREEN}✓ wandb command available${NC}"
    echo ""
    if [ "$API_KEY_CONFIGURED" = false ]; then
        echo "Configure API key:"
        echo "  wandb login"
    fi
else
    echo -e "${YELLOW}Warning: wandb command not found in PATH${NC}"
fi

echo ""
echo -e "${GREEN}Setup completed successfully!${NC}"
