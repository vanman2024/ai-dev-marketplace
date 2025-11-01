# Example Projects Skill

Production-ready ML training examples demonstrating complete workflows from data to deployment.

## What This Skill Provides

Three complete, runnable example projects:

1. **Sentiment Classification** - Binary text classification with DistilBERT
2. **Text Generation** - GPT-2 fine-tuning with LoRA
3. **RedAI Trade Classifier** - Financial trading signal prediction

## Directory Structure

```
example-projects/
├── SKILL.md                          # Skill manifest
├── README.md                         # This file
├── scripts/                          # Helper scripts
│   ├── setup-example.sh             # Setup any example
│   ├── run-training.sh              # Run training
│   └── test-inference.sh            # Test inference
├── examples/                         # Example projects
│   ├── sentiment-classification/
│   │   ├── train.py                 # Training script
│   │   ├── inference.py             # Inference script
│   │   ├── data.json                # Sample data (50 examples)
│   │   ├── requirements.txt         # Dependencies
│   │   └── README.md                # Documentation
│   ├── text-generation/
│   │   ├── train.py                 # LoRA training
│   │   ├── generate.py              # Text generation
│   │   ├── config.yaml              # Configuration
│   │   ├── training_data.txt        # Sample text
│   │   ├── requirements.txt         # Dependencies
│   │   └── README.md                # Documentation
│   └── redai-trade-classifier/
│       ├── train.py                 # Classifier training
│       ├── inference.py             # Prediction script
│       ├── modal_deploy.py          # Modal deployment
│       ├── sample_data.csv          # Market data (50 samples)
│       ├── requirements.txt         # Dependencies
│       └── README.md                # Documentation
└── templates/                        # Project scaffolding
    ├── train_template.py            # Training template
    ├── inference_template.py        # Inference template
    ├── modal_deploy_template.py     # Deployment template
    ├── README_template.md           # Documentation template
    └── requirements_template.txt    # Dependencies template
```

## Quick Start

### 1. Setup an Example

```bash
cd /path/to/ml-training/skills/example-projects

# Setup sentiment classification
./scripts/setup-example.sh sentiment-classification

# Setup text generation
./scripts/setup-example.sh text-generation

# Setup trade classifier
./scripts/setup-example.sh redai-trade-classifier
```

### 2. Train Model

```bash
# From skill directory
./scripts/run-training.sh sentiment-classification

# Or from project directory
cd sentiment-classification
source venv/bin/activate
python train.py
```

### 3. Test Inference

```bash
# From skill directory
./scripts/test-inference.sh sentiment-classification "This is amazing!"

# Or from project directory
cd sentiment-classification
source venv/bin/activate
python inference.py --text "This is amazing!"
```

## Example Projects

### Sentiment Classification

**What it does:** Binary sentiment analysis (positive/negative)

**Model:** DistilBERT fine-tuned on custom data

**Features:**
- 50 training examples provided
- FastAPI inference server
- 90%+ accuracy on sample data
- 5-10 minute training time

**Use cases:**
- Product review sentiment
- Customer feedback analysis
- Social media monitoring

### Text Generation

**What it does:** Custom text generation with fine-tuned GPT-2

**Model:** GPT-2 with LoRA adapters

**Features:**
- Parameter-efficient training (LoRA)
- 15 training paragraphs provided
- Interactive generation
- Configurable via YAML
- 15-30 minute training time

**Use cases:**
- Story generation
- Code completion
- Email drafting
- Creative writing

### RedAI Trade Classifier

**What it does:** Predict trading signals (BUY/HOLD/SELL)

**Model:** Custom neural network with technical indicators

**Features:**
- 50 market data samples
- 8 technical indicators
- Class imbalance handling
- Modal serverless deployment
- 10-20 minute training time

**Use cases:**
- Algorithmic trading
- Market signal detection
- Portfolio management
- Risk assessment

## Scripts

### setup-example.sh

Initializes example project:
- Creates project directory
- Copies files
- Creates virtual environment
- Installs dependencies
- Downloads pretrained models
- Validates setup

**Usage:**
```bash
./scripts/setup-example.sh <project-name>
```

### run-training.sh

Runs training with monitoring:
- Activates virtual environment
- Checks GPU availability
- Runs training script
- Logs output
- Shows training summary

**Usage:**
```bash
./scripts/run-training.sh <project-name>
```

### test-inference.sh

Tests trained model:
- Loads model
- Runs predictions
- Shows results
- Supports interactive mode

**Usage:**
```bash
./scripts/test-inference.sh <project-name> [input]
```

## Templates

Pre-built templates for creating new ML projects:

- **train_template.py** - Customizable training script
- **inference_template.py** - Inference boilerplate
- **modal_deploy_template.py** - Modal deployment setup
- **README_template.md** - Documentation structure
- **requirements_template.txt** - Dependency management

## When to Use This Skill

Claude will invoke this skill when:
- User requests ML training examples
- User wants to see working code
- User needs reference implementations
- User mentions sentiment analysis, text generation, or trading
- User asks for starter templates
- User needs deployment examples

## Customization

### Modify Example Projects

1. **Change model:**
   - Edit model name in training script
   - Update config files

2. **Add more data:**
   - Replace data files with larger datasets
   - Update data loading functions

3. **Adjust hyperparameters:**
   - Modify config files
   - Use command-line arguments

### Create New Project from Template

```bash
# Copy template files
cp templates/train_template.py my_project/train.py
cp templates/inference_template.py my_project/inference.py
cp templates/modal_deploy_template.py my_project/modal_deploy.py

# Customize for your use case
# Edit TODO comments in files
```

## Requirements

### System Requirements

- Python 3.8+
- 4GB+ RAM (CPU) or 2GB+ VRAM (GPU)
- ~5GB disk space for models

### Software Dependencies

All examples include `requirements.txt`:
- PyTorch
- Transformers (for NLP examples)
- scikit-learn
- NumPy/Pandas
- Optional: Modal (for deployment)

### GPU Recommendations

- **Sentiment:** Optional (works well on CPU)
- **Text Generation:** Recommended (10x faster)
- **Trade Classifier:** Optional (small model)

## Testing

All examples are fully tested and runnable:

```bash
# Test sentiment classification
cd examples/sentiment-classification
python train.py --epochs 1  # Quick test
python inference.py         # Demo mode

# Test text generation
cd examples/text-generation
python train.py --epochs 1
python generate.py

# Test trade classifier
cd examples/redai-trade-classifier
python train.py --epochs 5
python inference.py
```

## Deployment

All examples support deployment:

### Local FastAPI

```bash
python inference.py --server --port 8000
```

### Modal Serverless

```bash
modal deploy modal_deploy.py
```

### Docker

```dockerfile
FROM python:3.9-slim
WORKDIR /app
COPY . .
RUN pip install -r requirements.txt
CMD ["python", "inference.py", "--server"]
```

## Troubleshooting

### Scripts Won't Execute

```bash
chmod +x scripts/*.sh
```

### Virtual Environment Issues

```bash
python3 -m venv venv --clear
source venv/bin/activate
pip install --upgrade pip
```

### Out of Memory

Reduce batch size:
```bash
python train.py --batch-size 4
```

### Model Download Fails

Check internet connection and retry:
```bash
HF_HUB_OFFLINE=0 python train.py
```

## Contributing

To add new examples:

1. Create directory in `examples/`
2. Include all files (train.py, inference.py, README.md, etc.)
3. Provide sample data
4. Test thoroughly
5. Update SKILL.md

## Resources

- **PyTorch Docs:** https://pytorch.org/docs
- **Transformers:** https://huggingface.co/docs/transformers
- **PEFT/LoRA:** https://huggingface.co/docs/peft
- **Modal:** https://modal.com/docs

## License

MIT - Free to use for any purpose
