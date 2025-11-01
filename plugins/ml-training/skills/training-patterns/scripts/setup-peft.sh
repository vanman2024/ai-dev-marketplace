#!/bin/bash
set -e

# PEFT/LoRA Setup Script
# Creates parameter-efficient fine-tuning project

PROJECT_NAME=$1
MODEL_NAME=${2:-"roberta-base"}
PEFT_METHOD=${3:-"lora"}

if [ -z "$PROJECT_NAME" ]; then
    echo "Usage: $0 <project-name> [model-name] [peft-method]"
    echo "Example: $0 efficient-model roberta-base lora"
    echo "PEFT methods: lora, qlora, prefix-tuning, adapter"
    exit 1
fi

echo "Setting up PEFT training project: $PROJECT_NAME"
echo "Model: $MODEL_NAME"
echo "PEFT method: $PEFT_METHOD"

# Create project directory structure
mkdir -p "$PROJECT_NAME"/{data,outputs,adapters,logs}

# Create requirements.txt
cat > "$PROJECT_NAME/requirements.txt" << 'EOF'
torch>=2.0.0
transformers>=4.30.0
peft>=0.7.0
datasets>=2.14.0
accelerate>=0.20.0
scikit-learn>=1.3.0
pandas>=2.0.0
numpy>=1.24.0
tqdm>=4.65.0
bitsandbytes>=0.41.0  # For QLoRA
wandb>=0.15.0
EOF

# Copy PEFT config template
SKILL_DIR="$(dirname "$0")/.."
cp "$SKILL_DIR/templates/peft-config.json" "$PROJECT_NAME/peft_config.json"

# Create PEFT training script
cat > "$PROJECT_NAME/train.py" << 'EOFPY'
"""
PEFT Training Script
Parameter-Efficient Fine-Tuning with LoRA, QLoRA, or other methods
"""

import argparse
import json
import torch
from transformers import (
    AutoTokenizer,
    AutoModelForSequenceClassification,
    AutoModelForCausalLM,
    TrainingArguments,
    Trainer,
    BitsAndBytesConfig,
    EarlyStoppingCallback
)
from peft import (
    get_peft_model,
    LoraConfig,
    PrefixTuningConfig,
    TaskType,
    prepare_model_for_kbit_training
)
from datasets import load_dataset
import numpy as np
from sklearn.metrics import accuracy_score, precision_recall_fscore_support


def load_peft_config(config_path='peft_config.json'):
    """Load PEFT configuration"""
    with open(config_path, 'r') as f:
        return json.load(f)


def create_peft_config(peft_method='lora', task_type='SEQ_CLS', **kwargs):
    """Create PEFT configuration"""
    task_type_map = {
        'classification': TaskType.SEQ_CLS,
        'generation': TaskType.CAUSAL_LM,
        'seq2seq': TaskType.SEQ_2_SEQ_LM
    }

    task_type_enum = task_type_map.get(task_type, TaskType.SEQ_CLS)

    if peft_method.lower() == 'lora':
        return LoraConfig(
            task_type=task_type_enum,
            inference_mode=False,
            r=kwargs.get('r', 8),
            lora_alpha=kwargs.get('lora_alpha', 16),
            lora_dropout=kwargs.get('lora_dropout', 0.1),
            target_modules=kwargs.get('target_modules', ['query', 'key', 'value', 'dense']),
            bias=kwargs.get('bias', 'none')
        )
    elif peft_method.lower() == 'prefix-tuning':
        return PrefixTuningConfig(
            task_type=task_type_enum,
            num_virtual_tokens=kwargs.get('num_virtual_tokens', 20),
            prefix_projection=kwargs.get('prefix_projection', False)
        )
    else:
        raise ValueError(f"Unsupported PEFT method: {peft_method}")


def setup_quantized_model(model_name, quantization='4bit'):
    """Setup model with quantization for QLoRA"""
    if quantization == '4bit':
        bnb_config = BitsAndBytesConfig(
            load_in_4bit=True,
            bnb_4bit_use_double_quant=True,
            bnb_4bit_quant_type="nf4",
            bnb_4bit_compute_dtype=torch.bfloat16
        )
    elif quantization == '8bit':
        bnb_config = BitsAndBytesConfig(load_in_8bit=True)
    else:
        return None

    return bnb_config


def compute_metrics(eval_pred):
    """Compute evaluation metrics"""
    predictions, labels = eval_pred
    predictions = np.argmax(predictions, axis=-1)

    accuracy = accuracy_score(labels, predictions)
    precision, recall, f1, _ = precision_recall_fscore_support(
        labels, predictions, average='weighted', zero_division=0
    )

    return {
        'accuracy': accuracy,
        'precision': precision,
        'recall': recall,
        'f1': f1
    }


def main():
    parser = argparse.ArgumentParser(description='PEFT training')
    parser.add_argument('--model_name', type=str, required=True)
    parser.add_argument('--peft_method', type=str, default='lora',
                       choices=['lora', 'qlora', 'prefix-tuning'])
    parser.add_argument('--task_type', type=str, default='classification',
                       choices=['classification', 'generation', 'seq2seq'])
    parser.add_argument('--train_file', type=str, required=True)
    parser.add_argument('--val_file', type=str, required=True)
    parser.add_argument('--num_labels', type=int, default=2)
    parser.add_argument('--peft_config', type=str, help='Path to PEFT config JSON')

    # LoRA hyperparameters
    parser.add_argument('--lora_r', type=int, default=8, help='LoRA rank')
    parser.add_argument('--lora_alpha', type=int, default=16, help='LoRA alpha')
    parser.add_argument('--lora_dropout', type=float, default=0.1)

    # Training hyperparameters
    parser.add_argument('--epochs', type=int, default=3)
    parser.add_argument('--batch_size', type=int, default=16)
    parser.add_argument('--learning_rate', type=float, default=3e-4)
    parser.add_argument('--output_dir', type=str, default='./outputs')
    parser.add_argument('--adapter_dir', type=str, default='./adapters')

    args = parser.parse_args()

    # Device info
    device = 'cuda' if torch.cuda.is_available() else 'cpu'
    print(f"\n🖥️  Device: {device}")
    if device == 'cuda':
        print(f"🎮 GPU: {torch.cuda.get_device_name(0)}")
        print(f"💾 Memory: {torch.cuda.get_device_properties(0).total_memory / 1e9:.1f} GB")

    # Load tokenizer
    print(f"\n📥 Loading tokenizer: {args.model_name}")
    tokenizer = AutoTokenizer.from_pretrained(args.model_name)
    if tokenizer.pad_token is None:
        tokenizer.pad_token = tokenizer.eos_token

    # Setup quantization for QLoRA
    quantization_config = None
    if args.peft_method == 'qlora':
        print("⚙️  Setting up 4-bit quantization for QLoRA...")
        quantization_config = setup_quantized_model(args.model_name, '4bit')

    # Load base model
    print(f"📥 Loading base model...")
    if args.task_type == 'classification':
        model = AutoModelForSequenceClassification.from_pretrained(
            args.model_name,
            num_labels=args.num_labels,
            quantization_config=quantization_config,
            device_map='auto' if quantization_config else None
        )
    else:
        model = AutoModelForCausalLM.from_pretrained(
            args.model_name,
            quantization_config=quantization_config,
            device_map='auto' if quantization_config else None
        )

    # Prepare model for k-bit training if using quantization
    if quantization_config:
        print("🔧 Preparing model for k-bit training...")
        model = prepare_model_for_kbit_training(model)

    # Create PEFT config
    if args.peft_config:
        print(f"📋 Loading PEFT config from {args.peft_config}")
        peft_config_dict = load_peft_config(args.peft_config)
        # Convert to PEFT config object (simplified)
        peft_config = create_peft_config(
            args.peft_method,
            args.task_type,
            r=args.lora_r,
            lora_alpha=args.lora_alpha,
            lora_dropout=args.lora_dropout
        )
    else:
        peft_config = create_peft_config(
            args.peft_method,
            args.task_type,
            r=args.lora_r,
            lora_alpha=args.lora_alpha,
            lora_dropout=args.lora_dropout
        )

    # Apply PEFT
    print(f"🎯 Applying {args.peft_method.upper()} to model...")
    model = get_peft_model(model, peft_config)

    # Print trainable parameters
    model.print_trainable_parameters()

    # Load datasets
    print(f"\n📚 Loading datasets...")
    if args.train_file.endswith('.csv'):
        dataset = load_dataset('csv', data_files={
            'train': args.train_file,
            'validation': args.val_file
        })
    else:
        dataset = load_dataset('json', data_files={
            'train': args.train_file,
            'validation': args.val_file
        })

    print(f"✅ Train: {len(dataset['train'])}")
    print(f"✅ Validation: {len(dataset['validation'])}")

    # Tokenize
    def tokenize_function(examples):
        text_column = 'text' if 'text' in examples else list(examples.keys())[0]
        return tokenizer(
            examples[text_column],
            truncation=True,
            padding='max_length',
            max_length=512
        )

    tokenized_datasets = dataset.map(tokenize_function, batched=True)

    # Training arguments
    training_args = TrainingArguments(
        output_dir=args.output_dir,
        num_train_epochs=args.epochs,
        per_device_train_batch_size=args.batch_size,
        per_device_eval_batch_size=args.batch_size * 2,
        learning_rate=args.learning_rate,
        warmup_ratio=0.1,
        weight_decay=0.01,
        evaluation_strategy='epoch',
        save_strategy='epoch',
        logging_steps=50,
        load_best_model_at_end=True,
        metric_for_best_model='f1',
        fp16=not quantization_config and torch.cuda.is_available(),
        save_total_limit=2,
        report_to='none',
    )

    # Trainer
    trainer = Trainer(
        model=model,
        args=training_args,
        train_dataset=tokenized_datasets['train'],
        eval_dataset=tokenized_datasets['validation'],
        compute_metrics=compute_metrics if args.task_type == 'classification' else None,
        callbacks=[EarlyStoppingCallback(early_stopping_patience=2)]
    )

    # Train
    print("\n" + "="*60)
    print(f"🚀 Starting {args.peft_method.upper()} training...")
    print("="*60)
    trainer.train()

    # Save adapters
    print(f"\n💾 Saving {args.peft_method.upper()} adapters...")
    model.save_pretrained(args.adapter_dir)
    tokenizer.save_pretrained(args.adapter_dir)

    print("\n" + "="*60)
    print("✅ PEFT training completed!")
    print("="*60)
    print(f"📁 Adapters saved to: {args.adapter_dir}")
    print(f"📊 Checkpoints saved to: {args.output_dir}")
    print(f"\n💡 Adapter size is tiny (~1-10MB) compared to full model!")
    print(f"   You can share/swap adapters easily while keeping the base model.")


if __name__ == '__main__':
    main()
EOFPY

chmod +x "$PROJECT_NAME/train.py"

# Create inference script for PEFT
cat > "$PROJECT_NAME/predict.py" << 'EOFPY'
"""
PEFT Inference Script
Load base model + adapters for prediction
"""

import torch
from transformers import AutoTokenizer, AutoModelForSequenceClassification
from peft import PeftModel


class PEFTClassifier:
    """PEFT model wrapper for inference"""

    def __init__(self, base_model_name, adapter_path='./adapters'):
        self.device = 'cuda' if torch.cuda.is_available() else 'cpu'
        print(f"Loading base model: {base_model_name}")
        print(f"Loading adapters from: {adapter_path}")

        # Load tokenizer
        self.tokenizer = AutoTokenizer.from_pretrained(adapter_path)

        # Load base model
        base_model = AutoModelForSequenceClassification.from_pretrained(base_model_name)

        # Load PEFT adapters on top
        self.model = PeftModel.from_pretrained(base_model, adapter_path)
        self.model.to(self.device)
        self.model.eval()

        self.id2label = self.model.config.id2label

        print(f"✅ Model ready on {self.device}")

    def predict(self, text):
        """Predict class for text"""
        inputs = self.tokenizer(
            text,
            return_tensors='pt',
            truncation=True,
            max_length=512
        ).to(self.device)

        with torch.no_grad():
            outputs = self.model(**inputs)
            predictions = torch.softmax(outputs.logits, dim=-1)

        predicted_class_id = predictions.argmax().item()
        predicted_label = self.id2label[predicted_class_id]
        confidence = predictions[0][predicted_class_id].item()

        return predicted_label, confidence


def main():
    # Replace with your base model name
    BASE_MODEL = "roberta-base"

    classifier = PEFTClassifier(BASE_MODEL, './adapters')

    # Example predictions
    test_texts = [
        "This is amazing!",
        "Terrible experience.",
        "It's okay."
    ]

    print("\nPredictions:\n")
    for text in test_texts:
        label, confidence = classifier.predict(text)
        print(f"Text: {text}")
        print(f"Predicted: {label} ({confidence:.3f})\n")


if __name__ == '__main__':
    main()
EOFPY

chmod +x "$PROJECT_NAME/predict.py"

# Create README
cat > "$PROJECT_NAME/README.md" << EOF
# $PROJECT_NAME

Parameter-Efficient Fine-Tuning (PEFT) with ${PEFT_METHOD}.

## What is PEFT?

PEFT only trains a small subset of model parameters (adapters), making it:
- **10-100x more memory efficient** than full fine-tuning
- **3-10x faster** to train
- Able to **fine-tune 7B+ models on consumer GPUs**
- Easy to **share and swap** adapters (tiny files)

## LoRA Overview

LoRA (Low-Rank Adaptation) freezes the base model and adds small trainable adapter layers.

**Key benefits:**
- Train only ~0.1-1% of parameters
- Adapter files are tiny (1-10MB vs multi-GB for full models)
- Can train multiple adapters for different tasks
- No degradation in model quality

## Setup

\`\`\`bash
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
\`\`\`

## Training

### Basic LoRA Training

\`\`\`bash
python train.py \\
  --model_name $MODEL_NAME \\
  --peft_method lora \\
  --task_type classification \\
  --train_file data/train.csv \\
  --val_file data/val.csv \\
  --num_labels 2 \\
  --epochs 3
\`\`\`

### QLoRA Training (4-bit Quantization)

For even more memory efficiency:

\`\`\`bash
python train.py \\
  --model_name $MODEL_NAME \\
  --peft_method qlora \\
  --task_type classification \\
  --train_file data/train.csv \\
  --val_file data/val.csv \\
  --num_labels 2 \\
  --epochs 3 \\
  --batch_size 32
\`\`\`

**QLoRA allows fine-tuning 7B models on 16GB GPU!**

### Custom LoRA Configuration

\`\`\`bash
python train.py \\
  --model_name $MODEL_NAME \\
  --peft_method lora \\
  --train_file data/train.csv \\
  --val_file data/val.csv \\
  --lora_r 16 \\
  --lora_alpha 32 \\
  --lora_dropout 0.05 \\
  --learning_rate 1e-3 \\
  --batch_size 32 \\
  --epochs 5
\`\`\`

## LoRA Hyperparameters

**\`lora_r\` (rank):**
- Lower = fewer parameters (4-8 typical)
- Higher = more capacity but larger adapters (16-64)
- Start with 8

**\`lora_alpha\`:**
- Scaling factor, typically 2x the rank
- If r=8, use alpha=16
- If r=16, use alpha=32

**\`lora_dropout\`:**
- Regularization, use 0.05-0.1
- Default: 0.1

**Learning rate:**
- Higher than full fine-tuning: 1e-4 to 1e-3
- Start with 3e-4

## GPU Requirements

**LoRA:**
- 8GB VRAM: Can train base models (110M-340M params)
- 16GB VRAM: Can train large models (1B-3B params)
- 24GB+ VRAM: Can train very large models (7B+ params)

**QLoRA (4-bit):**
- 16GB VRAM: Can train 7B models!
- 24GB VRAM: Can train 13B models
- 40GB VRAM: Can train 30B+ models

## Inference

\`\`\`bash
python predict.py
\`\`\`

Or in your code:

\`\`\`python
from predict import PEFTClassifier

classifier = PEFTClassifier('$MODEL_NAME', './adapters')
label, confidence = classifier.predict("Your text")
\`\`\`

## Multi-Adapter Management

Train multiple adapters for different tasks:

\`\`\`bash
# Train adapter 1
python train.py ... --adapter_dir ./adapters/sentiment

# Train adapter 2
python train.py ... --adapter_dir ./adapters/intent

# Train adapter 3
python train.py ... --adapter_dir ./adapters/ner
\`\`\`

Then swap adapters at inference time!

## Adapter Sharing

Adapters are tiny (1-10MB), making them easy to share:

\`\`\`bash
# Upload to HuggingFace
huggingface-cli upload username/my-adapter ./adapters

# Download and use
from peft import PeftModel
model = PeftModel.from_pretrained(base_model, "username/my-adapter")
\`\`\`

## Performance Comparison

| Method | GPU Memory | Training Time | Adapter Size |
|--------|-----------|---------------|--------------|
| Full Fine-Tuning | 16GB+ | Hours | Multi-GB |
| LoRA | 8-16GB | Minutes | 1-10MB |
| QLoRA | 8GB | Minutes | 1-10MB |

## When to Use PEFT

**Use PEFT/LoRA when:**
- Limited GPU memory (<16GB)
- Quick experimentation
- Small dataset (<10k examples)
- Need multiple task-specific models
- Want to fine-tune large models (7B+)

**Use full fine-tuning when:**
- Plenty of GPU resources (40GB+)
- Large dataset (>100k examples)
- Maximum performance critical
- Substantial domain shift

## Next Steps

1. Prepare dataset (CSV or JSON)
2. Start with default LoRA config (r=8, alpha=16)
3. Train for 3-5 epochs
4. Evaluate and adjust hyperparameters
5. Try QLoRA for even more efficiency

Generated by ML Training Plugin
EOF

echo ""
echo "✅ PEFT training project created: $PROJECT_NAME/"
echo ""
echo "🎯 PEFT/LoRA Benefits:"
echo "  - 10-100x less memory than full fine-tuning"
echo "  - Train 7B models on 16GB GPU (with QLoRA)"
echo "  - Adapter files are tiny (1-10MB)"
echo "  - Multiple adapters for different tasks"
echo ""
echo "Next steps:"
echo "  1. cd $PROJECT_NAME"
echo "  2. python -m venv venv && source venv/bin/activate"
echo "  3. pip install -r requirements.txt"
echo "  4. Prepare your data"
echo "  5. python train.py --model_name $MODEL_NAME --train_file data/train.csv --val_file data/val.csv"
echo ""
echo "💡 Start with default settings (r=8, alpha=16, lr=3e-4)"
echo ""
