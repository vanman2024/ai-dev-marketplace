#!/bin/bash
set -e

# Classification Training Setup Script
# Creates a complete classification training project with Trainer API

PROJECT_NAME=$1
MODEL_NAME=${2:-"distilbert-base-uncased"}
NUM_CLASSES=${3:-2}

if [ -z "$PROJECT_NAME" ]; then
    echo "Usage: $0 <project-name> [model-name] [num-classes]"
    echo "Example: $0 sentiment-classifier distilbert-base-uncased 3"
    exit 1
fi

echo "Setting up classification training project: $PROJECT_NAME"
echo "Model: $MODEL_NAME"
echo "Number of classes: $NUM_CLASSES"

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
wandb>=0.15.0  # Optional: for experiment tracking
EOF

# Copy configuration template
SKILL_DIR="$(dirname "$0")/.."
cp "$SKILL_DIR/templates/classification-config.yaml" "$PROJECT_NAME/config.yaml"

# Update config with user parameters
sed -i "s/name: .*/name: $MODEL_NAME/" "$PROJECT_NAME/config.yaml"
sed -i "s/num_labels: .*/num_labels: $NUM_CLASSES/" "$PROJECT_NAME/config.yaml"

# Create training script
cat > "$PROJECT_NAME/train.py" << 'EOFPY'
"""
Text Classification Training Script
Supports binary and multi-class classification with HuggingFace Transformers
"""

import argparse
import yaml
from pathlib import Path
import pandas as pd
import numpy as np
from datasets import Dataset, DatasetDict
from transformers import (
    AutoTokenizer,
    AutoModelForSequenceClassification,
    TrainingArguments,
    Trainer,
    EarlyStoppingCallback
)
from sklearn.metrics import accuracy_score, precision_recall_fscore_support, confusion_matrix
import torch


def load_config(config_path='config.yaml'):
    """Load training configuration from YAML"""
    with open(config_path, 'r') as f:
        return yaml.safe_load(f)


def load_data(config):
    """Load and prepare dataset from CSV files"""
    print("Loading datasets...")

    # Load CSV files
    train_df = pd.read_csv(config['dataset']['train_file'])
    val_df = pd.read_csv(config['dataset']['validation_file'])
    test_df = pd.read_csv(config['dataset']['test_file']) if 'test_file' in config['dataset'] else None

    # Get column names
    text_col = config['dataset']['text_column']
    label_col = config['dataset']['label_column']

    # Create datasets
    datasets = {
        'train': Dataset.from_pandas(train_df[[text_col, label_col]]),
        'validation': Dataset.from_pandas(val_df[[text_col, label_col]])
    }

    if test_df is not None:
        datasets['test'] = Dataset.from_pandas(test_df[[text_col, label_col]])

    # Rename columns to standard names
    datasets = DatasetDict(datasets)
    datasets = datasets.rename_column(text_col, 'text')
    datasets = datasets.rename_column(label_col, 'label')

    print(f"Train size: {len(datasets['train'])}")
    print(f"Validation size: {len(datasets['validation'])}")
    if 'test' in datasets:
        print(f"Test size: {len(datasets['test'])}")

    # Print label distribution
    train_labels = datasets['train']['label']
    unique_labels = set(train_labels)
    print(f"\nLabel distribution (training):")
    for label in sorted(unique_labels):
        count = train_labels.count(label)
        print(f"  Label {label}: {count} ({count/len(train_labels)*100:.1f}%)")

    return datasets


def preprocess_data(datasets, tokenizer, config):
    """Tokenize and preprocess text data"""
    print("\nTokenizing datasets...")

    def tokenize_function(examples):
        return tokenizer(
            examples['text'],
            truncation=True,
            padding='max_length',
            max_length=512
        )

    tokenized_datasets = datasets.map(
        tokenize_function,
        batched=True,
        desc="Tokenizing"
    )

    return tokenized_datasets


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


def main(config_path='config.yaml', use_wandb=False):
    """Main training function"""
    # Load configuration
    config = load_config(config_path)

    # Setup device
    device = 'cuda' if torch.cuda.is_available() else 'cpu'
    print(f"Using device: {device}")
    if device == 'cuda':
        print(f"GPU: {torch.cuda.get_device_name(0)}")
        print(f"Memory: {torch.cuda.get_device_properties(0).total_memory / 1e9:.2f} GB")

    # Load tokenizer
    print(f"\nLoading tokenizer: {config['model']['name']}")
    tokenizer = AutoTokenizer.from_pretrained(config['model']['name'])

    # Load datasets
    datasets = load_data(config)

    # Preprocess
    tokenized_datasets = preprocess_data(datasets, tokenizer, config)

    # Create label mappings
    num_labels = config['model']['num_labels']
    id2label = {i: f"class_{i}" for i in range(num_labels)}
    label2id = {v: k for k, v in id2label.items()}

    # Load model
    print(f"\nLoading model: {config['model']['name']}")
    model = AutoModelForSequenceClassification.from_pretrained(
        config['model']['name'],
        num_labels=num_labels,
        id2label=id2label,
        label2id=label2id
    )

    # Training arguments
    training_config = config['training']
    training_args = TrainingArguments(
        output_dir=training_config['output_dir'],
        num_train_epochs=training_config['num_epochs'],
        per_device_train_batch_size=training_config['batch_size'],
        per_device_eval_batch_size=training_config['batch_size'] * 2,
        learning_rate=float(training_config['learning_rate']),
        warmup_steps=training_config.get('warmup_steps', 500),
        weight_decay=training_config.get('weight_decay', 0.01),
        evaluation_strategy=training_config.get('evaluation_strategy', 'epoch'),
        save_strategy=training_config.get('save_strategy', 'epoch'),
        logging_dir='./logs',
        logging_steps=training_config.get('logging_steps', 100),
        load_best_model_at_end=True,
        metric_for_best_model='f1',
        greater_is_better=True,
        fp16=training_config.get('fp16', False) and torch.cuda.is_available(),
        gradient_accumulation_steps=training_config.get('gradient_accumulation_steps', 1),
        save_total_limit=3,
        report_to='wandb' if use_wandb else 'none',
    )

    # Create trainer
    trainer = Trainer(
        model=model,
        args=training_args,
        train_dataset=tokenized_datasets['train'],
        eval_dataset=tokenized_datasets['validation'],
        compute_metrics=compute_metrics,
        callbacks=[EarlyStoppingCallback(early_stopping_patience=3)]
    )

    # Train
    print("\n" + "="*50)
    print("Starting training...")
    print("="*50)
    trainer.train()

    # Evaluate on test set if available
    if 'test' in tokenized_datasets:
        print("\n" + "="*50)
        print("Evaluating on test set...")
        print("="*50)
        test_results = trainer.evaluate(tokenized_datasets['test'])
        print("\nTest Results:")
        for key, value in test_results.items():
            print(f"  {key}: {value:.4f}")

    # Save final model
    print("\nSaving model...")
    trainer.save_model('./final_model')
    tokenizer.save_pretrained('./final_model')

    print("\n" + "="*50)
    print("Training completed!")
    print("="*50)
    print(f"Model saved to: ./final_model")
    print(f"Checkpoints saved to: {training_config['output_dir']}")


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Train text classification model')
    parser.add_argument('--config', type=str, default='config.yaml', help='Path to config file')
    parser.add_argument('--wandb', action='store_true', help='Use Weights & Biases for logging')

    args = parser.parse_args()
    main(args.config, args.wandb)
EOFPY

chmod +x "$PROJECT_NAME/train.py"

# Create inference script
cat > "$PROJECT_NAME/predict.py" << 'EOFPY'
"""
Classification Inference Script
Load trained model and make predictions
"""

import torch
from transformers import AutoTokenizer, AutoModelForSequenceClassification


class TextClassifier:
    """Text classifier wrapper for inference"""

    def __init__(self, model_path='./final_model'):
        """Load model and tokenizer"""
        self.device = 'cuda' if torch.cuda.is_available() else 'cpu'
        print(f"Loading model from {model_path} on {self.device}")

        self.tokenizer = AutoTokenizer.from_pretrained(model_path)
        self.model = AutoModelForSequenceClassification.from_pretrained(model_path)
        self.model.to(self.device)
        self.model.eval()

        self.id2label = self.model.config.id2label

    def predict(self, text, return_probabilities=False):
        """Predict class for text"""
        inputs = self.tokenizer(
            text,
            return_tensors='pt',
            truncation=True,
            max_length=512,
            padding=True
        ).to(self.device)

        with torch.no_grad():
            outputs = self.model(**inputs)
            predictions = torch.softmax(outputs.logits, dim=-1)

        predicted_class_id = predictions.argmax().item()
        predicted_label = self.id2label[predicted_class_id]
        confidence = predictions[0][predicted_class_id].item()

        if return_probabilities:
            probs = {self.id2label[i]: predictions[0][i].item() for i in range(len(self.id2label))}
            return predicted_label, confidence, probs

        return predicted_label, confidence

    def predict_batch(self, texts, batch_size=32):
        """Predict classes for multiple texts"""
        results = []
        for i in range(0, len(texts), batch_size):
            batch = texts[i:i+batch_size]
            inputs = self.tokenizer(
                batch,
                return_tensors='pt',
                truncation=True,
                max_length=512,
                padding=True
            ).to(self.device)

            with torch.no_grad():
                outputs = self.model(**inputs)
                predictions = torch.softmax(outputs.logits, dim=-1)

            for j in range(len(batch)):
                predicted_class_id = predictions[j].argmax().item()
                predicted_label = self.id2label[predicted_class_id]
                confidence = predictions[j][predicted_class_id].item()
                results.append((predicted_label, confidence))

        return results


def main():
    """Demo inference"""
    classifier = TextClassifier('./final_model')

    # Example predictions
    test_texts = [
        "This is a great product, highly recommended!",
        "Terrible service, very disappointed.",
        "It's okay, nothing special."
    ]

    print("Single predictions:")
    for text in test_texts:
        label, confidence, probs = classifier.predict(text, return_probabilities=True)
        print(f"\nText: {text}")
        print(f"Predicted: {label} (confidence: {confidence:.3f})")
        print(f"All probabilities: {probs}")

    print("\n" + "="*50)
    print("Batch predictions:")
    results = classifier.predict_batch(test_texts)
    for text, (label, conf) in zip(test_texts, results):
        print(f"{text[:50]:50s} -> {label} ({conf:.3f})")


if __name__ == '__main__':
    main()
EOFPY

chmod +x "$PROJECT_NAME/predict.py"

# Create example data
cat > "$PROJECT_NAME/data/train.csv" << 'EOF'
text,label
"This product is amazing!",1
"Terrible experience, very disappointed.",0
"It's okay, nothing special.",0
"Absolutely love it! Best purchase ever.",1
"Would not recommend to anyone.",0
"Great quality and fast shipping.",1
EOF

cat > "$PROJECT_NAME/data/val.csv" << 'EOF'
text,label
"Pretty good overall.",1
"Not worth the money.",0
EOF

cat > "$PROJECT_NAME/data/test.csv" << 'EOF'
text,label
"Excellent product!",1
"Complete waste of money.",0
EOF

# Create README
cat > "$PROJECT_NAME/README.md" << EOF
# $PROJECT_NAME

Text classification training project using HuggingFace Transformers.

## Model
- Base model: $MODEL_NAME
- Number of classes: $NUM_CLASSES
- Task: Text Classification

## Setup

\`\`\`bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\\Scripts\\activate

# Install dependencies
pip install -r requirements.txt
\`\`\`

## Dataset Format

Place your data in CSV format with columns:
- \`text\`: Input text
- \`label\`: Class label (0 to $((NUM_CLASSES - 1)))

Example:
\`\`\`csv
text,label
"This is positive",1
"This is negative",0
\`\`\`

## Configuration

Edit \`config.yaml\` to customize:
- Model architecture
- Training hyperparameters
- Dataset paths
- Output directories

## Training

\`\`\`bash
# Basic training
python train.py

# With Weights & Biases logging
python train.py --wandb

# Custom config
python train.py --config my_config.yaml
\`\`\`

## Inference

\`\`\`bash
# Run demo predictions
python predict.py
\`\`\`

Or use in your code:
\`\`\`python
from predict import TextClassifier

classifier = TextClassifier('./final_model')
label, confidence = classifier.predict("Your text here")
print(f"Predicted: {label} ({confidence:.3f})")
\`\`\`

## Directory Structure

\`\`\`
$PROJECT_NAME/
├── config.yaml          # Training configuration
├── train.py             # Training script
├── predict.py           # Inference script
├── requirements.txt     # Dependencies
├── data/                # Dataset files
│   ├── train.csv
│   ├── val.csv
│   └── test.csv
├── outputs/             # Training checkpoints
├── logs/                # Training logs
└── final_model/         # Saved model
\`\`\`

## GPU Requirements

- Minimum: 8GB VRAM (with fp16)
- Recommended: 16GB VRAM

For limited GPU memory, reduce batch_size in config.yaml or enable gradient_accumulation_steps.

## Next Steps

1. Prepare your dataset in CSV format
2. Update \`config.yaml\` with your data paths
3. Adjust hyperparameters (learning rate, epochs, batch size)
4. Run training with \`python train.py\`
5. Evaluate on test set
6. Use \`predict.py\` for inference

Generated by ML Training Plugin
EOF

echo ""
echo "✅ Classification training project created: $PROJECT_NAME/"
echo ""
echo "Next steps:"
echo "  1. cd $PROJECT_NAME"
echo "  2. python -m venv venv && source venv/bin/activate"
echo "  3. pip install -r requirements.txt"
echo "  4. Prepare your data in data/ directory"
echo "  5. Update config.yaml with your settings"
echo "  6. python train.py"
echo ""
echo "For more details, see $PROJECT_NAME/README.md"
