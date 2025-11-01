#!/bin/bash
set -e

# Text Generation Training Setup Script
# Creates a complete seq2seq generation training project

PROJECT_NAME=$1
MODEL_NAME=${2:-"t5-small"}
GENERATION_TYPE=${3:-"question-answering"}

if [ -z "$PROJECT_NAME" ]; then
    echo "Usage: $0 <project-name> [model-name] [generation-type]"
    echo "Example: $0 qa-bot t5-small question-answering"
    echo "Generation types: question-answering, summarization, translation, general"
    exit 1
fi

echo "Setting up generation training project: $PROJECT_NAME"
echo "Model: $MODEL_NAME"
echo "Generation type: $GENERATION_TYPE"

# Create project directory structure
mkdir -p "$PROJECT_NAME"/{data,outputs,logs}

# Create requirements.txt
cat > "$PROJECT_NAME/requirements.txt" << 'EOF'
torch>=2.0.0
transformers>=4.30.0
datasets>=2.14.0
accelerate>=0.20.0
scikit-learn>=1.3.0
pandas>=2.0.0
numpy>=1.24.0
tqdm>=4.65.0
rouge-score>=0.1.2
nltk>=3.8
wandb>=0.15.0  # Optional: for experiment tracking
EOF

# Copy configuration template
SKILL_DIR="$(dirname "$0")/.."
cp "$SKILL_DIR/templates/generation-config.yaml" "$PROJECT_NAME/config.yaml"

# Update config with user parameters
sed -i "s/name: .*/name: $MODEL_NAME/" "$PROJECT_NAME/config.yaml"
sed -i "s/generation_type: .*/generation_type: $GENERATION_TYPE/" "$PROJECT_NAME/config.yaml"

# Create training script
cat > "$PROJECT_NAME/train.py" << 'EOFPY'
"""
Text Generation Training Script
Supports seq2seq tasks: QA, summarization, translation
"""

import argparse
import yaml
from pathlib import Path
import json
import pandas as pd
import numpy as np
from datasets import Dataset, DatasetDict
from transformers import (
    AutoTokenizer,
    AutoModelForSeq2SeqLM,
    Seq2SeqTrainingArguments,
    Seq2SeqTrainer,
    EarlyStoppingCallback,
    DataCollatorForSeq2Seq
)
import torch
import nltk
from rouge_score import rouge_scorer

# Download NLTK data
nltk.download('punkt', quiet=True)


def load_config(config_path='config.yaml'):
    """Load training configuration"""
    with open(config_path, 'r') as f:
        return yaml.safe_load(f)


def load_data(config):
    """Load generation dataset from JSON"""
    print("Loading datasets...")

    # Load JSON files
    with open(config['dataset']['train_file'], 'r') as f:
        train_data = json.load(f)

    with open(config['dataset']['validation_file'], 'r') as f:
        val_data = json.load(f)

    # Create datasets
    datasets = DatasetDict({
        'train': Dataset.from_list(train_data),
        'validation': Dataset.from_list(val_data)
    })

    print(f"Train size: {len(datasets['train'])}")
    print(f"Validation size: {len(datasets['validation'])}")

    # Print sample
    print("\nSample data point:")
    sample = datasets['train'][0]
    for key, value in sample.items():
        print(f"  {key}: {str(value)[:100]}...")

    return datasets


def preprocess_data(datasets, tokenizer, config):
    """Tokenize input-target pairs"""
    print("\nTokenizing datasets...")

    input_col = config['dataset']['input_column']
    target_col = config['dataset']['target_column']
    max_input_length = config['dataset'].get('max_input_length', 512)
    max_target_length = config['dataset'].get('max_target_length', 128)

    def preprocess_function(examples):
        # Tokenize inputs
        model_inputs = tokenizer(
            examples[input_col],
            max_length=max_input_length,
            truncation=True,
            padding='max_length'
        )

        # Tokenize targets
        with tokenizer.as_target_tokenizer():
            labels = tokenizer(
                examples[target_col],
                max_length=max_target_length,
                truncation=True,
                padding='max_length'
            )

        model_inputs['labels'] = labels['input_ids']
        return model_inputs

    tokenized_datasets = datasets.map(
        preprocess_function,
        batched=True,
        desc="Tokenizing"
    )

    return tokenized_datasets


def compute_metrics(eval_pred):
    """Compute ROUGE scores for generation"""
    predictions, labels = eval_pred

    # Decode predictions
    decoded_preds = tokenizer.batch_decode(predictions, skip_special_tokens=True)

    # Replace -100 in labels (used for padding)
    labels = np.where(labels != -100, labels, tokenizer.pad_token_id)
    decoded_labels = tokenizer.batch_decode(labels, skip_special_tokens=True)

    # Compute ROUGE scores
    scorer = rouge_scorer.RougeScorer(['rouge1', 'rouge2', 'rougeL'], use_stemmer=True)
    rouge_scores = {'rouge1': [], 'rouge2': [], 'rougeL': []}

    for pred, label in zip(decoded_preds, decoded_labels):
        scores = scorer.score(label, pred)
        rouge_scores['rouge1'].append(scores['rouge1'].fmeasure)
        rouge_scores['rouge2'].append(scores['rouge2'].fmeasure)
        rouge_scores['rougeL'].append(scores['rougeL'].fmeasure)

    return {
        'rouge1': np.mean(rouge_scores['rouge1']),
        'rouge2': np.mean(rouge_scores['rouge2']),
        'rougeL': np.mean(rouge_scores['rougeL'])
    }


def main(config_path='config.yaml', use_wandb=False):
    """Main training function"""
    global tokenizer  # Make available to compute_metrics

    config = load_config(config_path)

    # Setup device
    device = 'cuda' if torch.cuda.is_available() else 'cpu'
    print(f"Using device: {device}")
    if device == 'cuda':
        print(f"GPU: {torch.cuda.get_device_name(0)}")

    # Load tokenizer
    print(f"\nLoading tokenizer: {config['model']['name']}")
    tokenizer = AutoTokenizer.from_pretrained(config['model']['name'])

    # Load datasets
    datasets = load_data(config)

    # Preprocess
    tokenized_datasets = preprocess_data(datasets, tokenizer, config)

    # Load model
    print(f"\nLoading model: {config['model']['name']}")
    model = AutoModelForSeq2SeqLM.from_pretrained(config['model']['name'])

    # Data collator
    data_collator = DataCollatorForSeq2Seq(tokenizer, model=model)

    # Training arguments
    training_config = config['training']
    gen_config = config.get('generation', {})

    training_args = Seq2SeqTrainingArguments(
        output_dir=training_config['output_dir'],
        num_train_epochs=training_config['num_epochs'],
        per_device_train_batch_size=training_config['batch_size'],
        per_device_eval_batch_size=training_config['batch_size'] * 2,
        learning_rate=float(training_config['learning_rate']),
        warmup_steps=training_config.get('warmup_steps', 1000),
        weight_decay=training_config.get('weight_decay', 0.01),
        evaluation_strategy=training_config.get('evaluation_strategy', 'steps'),
        eval_steps=training_config.get('eval_steps', 500),
        save_steps=training_config.get('save_steps', 500),
        logging_steps=training_config.get('logging_steps', 100),
        load_best_model_at_end=True,
        metric_for_best_model='rougeL',
        greater_is_better=True,
        fp16=training_config.get('fp16', False) and torch.cuda.is_available(),
        gradient_accumulation_steps=training_config.get('gradient_accumulation_steps', 2),
        predict_with_generate=training_config.get('predict_with_generate', True),
        generation_max_length=gen_config.get('max_length', 128),
        generation_num_beams=gen_config.get('num_beams', 4),
        save_total_limit=3,
        report_to='wandb' if use_wandb else 'none',
    )

    # Create trainer
    trainer = Seq2SeqTrainer(
        model=model,
        args=training_args,
        train_dataset=tokenized_datasets['train'],
        eval_dataset=tokenized_datasets['validation'],
        data_collator=data_collator,
        tokenizer=tokenizer,
        compute_metrics=compute_metrics,
        callbacks=[EarlyStoppingCallback(early_stopping_patience=3)]
    )

    # Train
    print("\n" + "="*50)
    print("Starting training...")
    print("="*50)
    trainer.train()

    # Save final model
    print("\nSaving model...")
    trainer.save_model('./final_model')
    tokenizer.save_pretrained('./final_model')

    print("\n" + "="*50)
    print("Training completed!")
    print("="*50)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Train text generation model')
    parser.add_argument('--config', type=str, default='config.yaml')
    parser.add_argument('--wandb', action='store_true')

    args = parser.parse_args()
    main(args.config, args.wandb)
EOFPY

chmod +x "$PROJECT_NAME/train.py"

# Create inference script
cat > "$PROJECT_NAME/generate.py" << 'EOFPY'
"""
Generation Inference Script
"""

import torch
from transformers import AutoTokenizer, AutoModelForSeq2SeqLM


class TextGenerator:
    """Text generator wrapper"""

    def __init__(self, model_path='./final_model'):
        self.device = 'cuda' if torch.cuda.is_available() else 'cpu'
        print(f"Loading model from {model_path} on {self.device}")

        self.tokenizer = AutoTokenizer.from_pretrained(model_path)
        self.model = AutoModelForSeq2SeqLM.from_pretrained(model_path)
        self.model.to(self.device)
        self.model.eval()

    def generate(self, input_text, max_length=128, num_beams=4, **kwargs):
        """Generate text from input"""
        inputs = self.tokenizer(
            input_text,
            return_tensors='pt',
            max_length=512,
            truncation=True
        ).to(self.device)

        outputs = self.model.generate(
            **inputs,
            max_length=max_length,
            num_beams=num_beams,
            early_stopping=True,
            **kwargs
        )

        return self.tokenizer.decode(outputs[0], skip_special_tokens=True)

    def generate_batch(self, inputs, batch_size=8, **kwargs):
        """Generate for multiple inputs"""
        results = []
        for i in range(0, len(inputs), batch_size):
            batch = inputs[i:i+batch_size]
            batch_inputs = self.tokenizer(
                batch,
                return_tensors='pt',
                max_length=512,
                truncation=True,
                padding=True
            ).to(self.device)

            outputs = self.model.generate(**batch_inputs, **kwargs)

            for output in outputs:
                results.append(self.tokenizer.decode(output, skip_special_tokens=True))

        return results


def main():
    generator = TextGenerator('./final_model')

    # Example generation
    test_inputs = [
        "What is machine learning?",
        "Explain natural language processing",
        "How does a neural network work?"
    ]

    print("Generation examples:\n")
    for input_text in test_inputs:
        output = generator.generate(input_text, max_length=128, num_beams=4)
        print(f"Input: {input_text}")
        print(f"Output: {output}")
        print()


if __name__ == '__main__':
    main()
EOFPY

chmod +x "$PROJECT_NAME/generate.py"

# Create example data based on generation type
if [ "$GENERATION_TYPE" == "question-answering" ]; then
    cat > "$PROJECT_NAME/data/train.json" << 'EOF'
[
  {"question": "What is the capital of France?", "answer": "The capital of France is Paris."},
  {"question": "Who invented the telephone?", "answer": "Alexander Graham Bell invented the telephone."},
  {"question": "What is photosynthesis?", "answer": "Photosynthesis is the process where plants convert light energy into chemical energy."}
]
EOF

    cat > "$PROJECT_NAME/data/val.json" << 'EOF'
[
  {"question": "What is the largest planet?", "answer": "Jupiter is the largest planet in our solar system."}
]
EOF
else
    cat > "$PROJECT_NAME/data/train.json" << 'EOF'
[
  {"input": "Sample input text 1", "output": "Sample output text 1"},
  {"input": "Sample input text 2", "output": "Sample output text 2"}
]
EOF

    cat > "$PROJECT_NAME/data/val.json" << 'EOF'
[
  {"input": "Sample validation input", "output": "Sample validation output"}
]
EOF
fi

# Create README
cat > "$PROJECT_NAME/README.md" << EOF
# $PROJECT_NAME

Text generation training project (${GENERATION_TYPE}).

## Model
- Base model: $MODEL_NAME
- Task: $GENERATION_TYPE

## Setup

\`\`\`bash
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
\`\`\`

## Dataset Format

JSON format with input-output pairs:
\`\`\`json
[
  {"question": "Input text", "answer": "Target output"},
  ...
]
\`\`\`

## Training

\`\`\`bash
python train.py
python train.py --wandb  # With experiment tracking
\`\`\`

## Generation

\`\`\`bash
python generate.py
\`\`\`

Or in code:
\`\`\`python
from generate import TextGenerator

generator = TextGenerator('./final_model')
output = generator.generate("Your input here")
print(output)
\`\`\`

## Configuration

Edit \`config.yaml\`:
- Model architecture
- Generation parameters (beam size, length)
- Training hyperparameters

Generated by ML Training Plugin
EOF

echo ""
echo "✅ Generation training project created: $PROJECT_NAME/"
echo ""
echo "Next steps:"
echo "  1. cd $PROJECT_NAME"
echo "  2. python -m venv venv && source venv/bin/activate"
echo "  3. pip install -r requirements.txt"
echo "  4. Prepare your data in data/ directory (JSON format)"
echo "  5. Update config.yaml"
echo "  6. python train.py"
echo ""
