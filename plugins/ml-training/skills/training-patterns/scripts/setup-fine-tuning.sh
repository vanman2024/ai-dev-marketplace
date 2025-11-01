#!/bin/bash
set -e

# Full Fine-Tuning Setup Script
# Creates a complete fine-tuning project with all model parameters

PROJECT_NAME=$1
MODEL_NAME=${2:-"bert-base-uncased"}
TASK_TYPE=${3:-"classification"}

if [ -z "$PROJECT_NAME" ]; then
    echo "Usage: $0 <project-name> [model-name] [task-type]"
    echo "Example: $0 domain-model bert-base-uncased classification"
    echo "Task types: classification, generation"
    exit 1
fi

echo "Setting up full fine-tuning project: $PROJECT_NAME"
echo "Model: $MODEL_NAME"
echo "Task type: $TASK_TYPE"

# Create project directory structure
mkdir -p "$PROJECT_NAME"/{data,outputs,logs,checkpoints}

# Create requirements.txt with optimization libraries
cat > "$PROJECT_NAME/requirements.txt" << 'EOF'
torch>=2.0.0
transformers>=4.30.0
datasets>=2.14.0
accelerate>=0.20.0
scikit-learn>=1.3.0
pandas>=2.0.0
numpy>=1.24.0
tqdm>=4.65.0
wandb>=0.15.0
deepspeed>=0.10.0  # Optional: for distributed training
bitsandbytes>=0.41.0  # Optional: for 8-bit optimization
EOF

# Create advanced training script
cat > "$PROJECT_NAME/train.py" << 'EOFPY'
"""
Full Fine-Tuning Script
Supports complete model parameter updates with memory optimization
"""

import argparse
import json
from pathlib import Path
import torch
from transformers import (
    AutoTokenizer,
    AutoModelForSequenceClassification,
    AutoModelForSeq2SeqLM,
    TrainingArguments,
    Trainer,
    EarlyStoppingCallback
)
from datasets import load_dataset
import numpy as np
from sklearn.metrics import accuracy_score, precision_recall_fscore_support


def setup_model_and_tokenizer(model_name, task_type, num_labels=2):
    """Initialize model and tokenizer"""
    tokenizer = AutoTokenizer.from_pretrained(model_name)

    if task_type == 'classification':
        model = AutoModelForSequenceClassification.from_pretrained(
            model_name,
            num_labels=num_labels
        )
    elif task_type == 'generation':
        model = AutoModelForSeq2SeqLM.from_pretrained(model_name)
    else:
        raise ValueError(f"Unknown task type: {task_type}")

    return model, tokenizer


def enable_gradient_checkpointing(model):
    """Enable gradient checkpointing for memory efficiency"""
    if hasattr(model, 'gradient_checkpointing_enable'):
        model.gradient_checkpointing_enable()
        print("✅ Gradient checkpointing enabled (saves ~30% memory)")
    return model


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
    parser = argparse.ArgumentParser(description='Full fine-tuning')
    parser.add_argument('--model_name', type=str, required=True)
    parser.add_argument('--task_type', type=str, default='classification')
    parser.add_argument('--train_file', type=str, required=True)
    parser.add_argument('--val_file', type=str, required=True)
    parser.add_argument('--num_labels', type=int, default=2)
    parser.add_argument('--epochs', type=int, default=3)
    parser.add_argument('--batch_size', type=int, default=8)
    parser.add_argument('--learning_rate', type=float, default=2e-5)
    parser.add_argument('--gradient_checkpointing', action='store_true',
                       help='Enable gradient checkpointing (saves memory)')
    parser.add_argument('--fp16', action='store_true',
                       help='Use mixed precision training')
    parser.add_argument('--gradient_accumulation_steps', type=int, default=1)
    parser.add_argument('--warmup_ratio', type=float, default=0.1)
    parser.add_argument('--output_dir', type=str, default='./outputs')

    args = parser.parse_args()

    # Check device
    device = 'cuda' if torch.cuda.is_available() else 'cpu'
    print(f"🖥️  Device: {device}")
    if device == 'cuda':
        gpu_name = torch.cuda.get_device_name(0)
        gpu_memory = torch.cuda.get_device_properties(0).total_memory / 1e9
        print(f"🎮 GPU: {gpu_name}")
        print(f"💾 GPU Memory: {gpu_memory:.1f} GB")

    # Load model and tokenizer
    print(f"\n📥 Loading model: {args.model_name}")
    model, tokenizer = setup_model_and_tokenizer(
        args.model_name,
        args.task_type,
        args.num_labels
    )

    # Enable gradient checkpointing if requested
    if args.gradient_checkpointing:
        model = enable_gradient_checkpointing(model)

    # Count parameters
    total_params = sum(p.numel() for p in model.parameters())
    trainable_params = sum(p.numel() for p in model.parameters() if p.requires_grad)
    print(f"🔢 Total parameters: {total_params:,}")
    print(f"🎯 Trainable parameters: {trainable_params:,} ({trainable_params/total_params*100:.1f}%)")

    # Load datasets
    print(f"\n📚 Loading datasets...")
    if args.train_file.endswith('.csv'):
        dataset = load_dataset('csv', data_files={
            'train': args.train_file,
            'validation': args.val_file
        })
    elif args.train_file.endswith('.json'):
        dataset = load_dataset('json', data_files={
            'train': args.train_file,
            'validation': args.val_file
        })
    else:
        raise ValueError("Unsupported file format. Use CSV or JSON.")

    print(f"✅ Train: {len(dataset['train'])} examples")
    print(f"✅ Validation: {len(dataset['validation'])} examples")

    # Tokenize
    def tokenize_function(examples):
        # Adjust column names as needed
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
        warmup_ratio=args.warmup_ratio,
        weight_decay=0.01,
        evaluation_strategy='epoch',
        save_strategy='epoch',
        logging_steps=100,
        load_best_model_at_end=True,
        metric_for_best_model='f1' if args.task_type == 'classification' else 'loss',
        fp16=args.fp16 and torch.cuda.is_available(),
        gradient_accumulation_steps=args.gradient_accumulation_steps,
        gradient_checkpointing=args.gradient_checkpointing,
        save_total_limit=3,
        report_to='none',
    )

    # Trainer
    trainer = Trainer(
        model=model,
        args=training_args,
        train_dataset=tokenized_datasets['train'],
        eval_dataset=tokenized_datasets['validation'],
        compute_metrics=compute_metrics if args.task_type == 'classification' else None,
        callbacks=[EarlyStoppingCallback(early_stopping_patience=3)]
    )

    # Train
    print("\n" + "="*60)
    print("🚀 Starting full fine-tuning...")
    print("="*60)
    trainer.train()

    # Save
    print("\n💾 Saving model...")
    trainer.save_model('./final_model')
    tokenizer.save_pretrained('./final_model')

    print("\n" + "="*60)
    print("✅ Fine-tuning completed!")
    print("="*60)
    print(f"📁 Model saved to: ./final_model")
    print(f"📊 Checkpoints saved to: {args.output_dir}")


if __name__ == '__main__':
    main()
EOFPY

chmod +x "$PROJECT_NAME/train.py"

# Create README
cat > "$PROJECT_NAME/README.md" << EOF
# $PROJECT_NAME

Full fine-tuning project for $MODEL_NAME.

## Overview

Full fine-tuning updates **all** model parameters. This requires:
- More compute (16GB+ GPU recommended)
- More training time (hours to days)
- More training data for best results

**Benefits:**
- Maximum adaptation to your domain/task
- Best performance when you have sufficient data
- Full control over model behavior

**Drawbacks:**
- High memory requirements
- Longer training time
- Risk of catastrophic forgetting

## Setup

\`\`\`bash
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
\`\`\`

## Training

### Basic Training

\`\`\`bash
python train.py \\
  --model_name $MODEL_NAME \\
  --task_type $TASK_TYPE \\
  --train_file data/train.csv \\
  --val_file data/val.csv \\
  --num_labels 2 \\
  --epochs 3
\`\`\`

### Memory-Optimized Training

For limited GPU memory:

\`\`\`bash
python train.py \\
  --model_name $MODEL_NAME \\
  --task_type $TASK_TYPE \\
  --train_file data/train.csv \\
  --val_file data/val.csv \\
  --batch_size 4 \\
  --gradient_accumulation_steps 4 \\
  --gradient_checkpointing \\
  --fp16
\`\`\`

**Memory optimization flags:**
- \`--gradient_checkpointing\`: Saves ~30% memory (slightly slower)
- \`--fp16\`: Mixed precision, 2x memory reduction
- \`--gradient_accumulation_steps 4\`: Simulates larger batch size

### Production Training

\`\`\`bash
python train.py \\
  --model_name $MODEL_NAME \\
  --task_type $TASK_TYPE \\
  --train_file data/train.csv \\
  --val_file data/val.csv \\
  --num_labels 3 \\
  --epochs 5 \\
  --batch_size 16 \\
  --learning_rate 2e-5 \\
  --warmup_ratio 0.1 \\
  --fp16 \\
  --output_dir ./checkpoints
\`\`\`

## GPU Requirements

**Minimum (with optimizations):**
- 8GB VRAM
- Use: \`--batch_size 4 --gradient_checkpointing --fp16\`

**Recommended:**
- 16GB VRAM (RTX 4060 Ti, RTX 3090, A4000)
- Use: \`--batch_size 16 --fp16\`

**Ideal:**
- 24GB+ VRAM (RTX 4090, A5000, A100)
- Use: \`--batch_size 32\`

## Hyperparameter Guidelines

**Learning Rate:**
- BERT-style models: 2e-5 to 5e-5
- Start with 2e-5 and adjust if needed

**Epochs:**
- Small datasets (<10k): 5-10 epochs
- Medium datasets (10k-100k): 3-5 epochs
- Large datasets (>100k): 1-3 epochs

**Batch Size:**
- As large as GPU memory allows
- Use gradient accumulation for effective larger batches

**Warmup:**
- Warmup ratio: 0.1 (10% of total steps)
- Helps stabilize training

## Monitoring

Watch for:
- **Training loss**: Should decrease steadily
- **Validation loss**: Should decrease (not increase = overfitting)
- **Metrics**: Should improve over epochs
- **GPU memory**: Monitor with \`nvidia-smi\`

## When to Use Full Fine-Tuning vs PEFT

**Use Full Fine-Tuning when:**
- You have sufficient GPU resources (16GB+)
- You have large training dataset (>10k examples)
- You need maximum task performance
- Domain shift is substantial

**Use PEFT/LoRA when:**
- Limited GPU memory (<16GB)
- Quick experimentation needed
- Small training dataset (<10k examples)
- Want to fine-tune large models (7B+)

## Next Steps

1. Prepare your dataset (CSV or JSON)
2. Determine optimal batch size for your GPU
3. Start with recommended hyperparameters
4. Monitor training metrics
5. Adjust hyperparameters based on results

Generated by ML Training Plugin
EOF

echo ""
echo "✅ Full fine-tuning project created: $PROJECT_NAME/"
echo ""
echo "⚠️  Full fine-tuning requires significant GPU resources!"
echo ""
echo "GPU Requirements:"
echo "  Minimum: 8GB VRAM (with optimizations)"
echo "  Recommended: 16GB VRAM"
echo "  Ideal: 24GB+ VRAM"
echo ""
echo "Next steps:"
echo "  1. cd $PROJECT_NAME"
echo "  2. python -m venv venv && source venv/bin/activate"
echo "  3. pip install -r requirements.txt"
echo "  4. Prepare your data"
echo "  5. See README.md for training examples"
echo ""
echo "💡 Tip: Consider using PEFT/LoRA instead if GPU memory is limited!"
echo "   Run: ./scripts/setup-peft.sh for memory-efficient alternative"
echo ""
