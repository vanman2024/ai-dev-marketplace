"""
RedAI Trade Classifier Training
Multi-class classification for trading signals (BUY/HOLD/SELL)
"""

import os
import json
import argparse
import time
from pathlib import Path

import numpy as np
import pandas as pd
import torch
from torch.utils.data import Dataset, DataLoader
from transformers import (
    AutoTokenizer,
    AutoModelForSequenceClassification,
    TrainingArguments,
    Trainer
)
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, confusion_matrix
from sklearn.preprocessing import StandardScaler


class TradeDataset(Dataset):
    """Dataset for trading signal classification"""

    def __init__(self, features, labels, tokenizer=None, max_length=128):
        self.features = torch.FloatTensor(features)
        self.labels = torch.LongTensor(labels)
        self.tokenizer = tokenizer
        self.max_length = max_length

    def __len__(self):
        return len(self.labels)

    def __getitem__(self, idx):
        return {
            'features': self.features[idx],
            'labels': self.labels[idx]
        }


class TradeClassifierModel(torch.nn.Module):
    """Custom classifier for trading signals"""

    def __init__(self, input_dim, hidden_dim=128, num_classes=3, dropout=0.3):
        super().__init__()

        self.network = torch.nn.Sequential(
            torch.nn.Linear(input_dim, hidden_dim),
            torch.nn.ReLU(),
            torch.nn.Dropout(dropout),
            torch.nn.Linear(hidden_dim, hidden_dim),
            torch.nn.ReLU(),
            torch.nn.Dropout(dropout),
            torch.nn.Linear(hidden_dim, num_classes)
        )

    def forward(self, features, labels=None):
        logits = self.network(features)

        loss = None
        if labels is not None:
            # Class weights for imbalanced data
            class_weights = torch.FloatTensor([1.0, 1.5, 1.0]).to(logits.device)
            loss_fct = torch.nn.CrossEntropyLoss(weight=class_weights)
            loss = loss_fct(logits, labels)

        return {'loss': loss, 'logits': logits} if loss is not None else {'logits': logits}


def load_and_preprocess_data(data_path):
    """Load and preprocess trading data"""
    print("Loading data...")

    # Load data
    if data_path.endswith('.csv'):
        df = pd.read_csv(data_path)
    elif data_path.endswith('.json'):
        df = pd.read_json(data_path)
    else:
        raise ValueError("Data must be CSV or JSON")

    print(f"  Loaded {len(df)} samples")

    # Feature engineering
    features = []
    labels = []

    for _, row in df.iterrows():
        # Extract features
        feature_vector = [
            row.get('price_change', 0),
            row.get('volume_change', 0),
            row.get('rsi', 50),
            row.get('macd', 0),
            row.get('ma_5', 0),
            row.get('ma_20', 0),
            row.get('volatility', 0),
            row.get('sentiment_score', 0),
        ]

        features.append(feature_vector)

        # Extract label
        label = row.get('signal', row.get('label', 1))  # Default to HOLD
        labels.append(label)

    features = np.array(features)
    labels = np.array(labels)

    print(f"  Features shape: {features.shape}")
    print(f"  Classes: {np.unique(labels)}")
    print(f"  Distribution: {dict(zip(*np.unique(labels, return_counts=True)))}")

    return features, labels


def main():
    parser = argparse.ArgumentParser(description='Train trade classifier')
    parser.add_argument('--data', type=str, default='sample_data.csv',
                        help='Path to training data (CSV or JSON)')
    parser.add_argument('--epochs', type=int, default=10,
                        help='Number of training epochs')
    parser.add_argument('--batch-size', type=int, default=32,
                        help='Training batch size')
    parser.add_argument('--learning-rate', type=float, default=1e-3,
                        help='Learning rate')
    parser.add_argument('--hidden-dim', type=int, default=128,
                        help='Hidden layer dimension')
    parser.add_argument('--dropout', type=float, default=0.3,
                        help='Dropout rate')
    parser.add_argument('--device', type=str, default='cuda' if torch.cuda.is_available() else 'cpu',
                        help='Device (cuda/cpu)')
    parser.add_argument('--output-dir', type=str, default='models/trade-classifier',
                        help='Output directory')

    args = parser.parse_args()

    print("=" * 50)
    print("RedAI Trade Classifier Training")
    print("=" * 50)
    print(f"\nConfiguration:")
    print(f"  Epochs: {args.epochs}")
    print(f"  Batch size: {args.batch_size}")
    print(f"  Learning rate: {args.learning_rate}")
    print(f"  Hidden dim: {args.hidden_dim}")
    print(f"  Dropout: {args.dropout}")
    print(f"  Device: {args.device}")
    print()

    # Load and preprocess data
    features, labels = load_and_preprocess_data(args.data)

    # Normalize features
    scaler = StandardScaler()
    features = scaler.fit_transform(features)

    # Split data
    X_train, X_test, y_train, y_test = train_test_split(
        features, labels, test_size=0.2, random_state=42, stratify=labels
    )

    print(f"  Training samples: {len(X_train)}")
    print(f"  Test samples: {len(X_test)}")
    print()

    # Create datasets
    train_dataset = TradeDataset(X_train, y_train)
    test_dataset = TradeDataset(X_test, y_test)

    # Create model
    input_dim = features.shape[1]
    model = TradeClassifierModel(
        input_dim=input_dim,
        hidden_dim=args.hidden_dim,
        num_classes=3,
        dropout=args.dropout
    )

    print(f"Model architecture:")
    print(f"  Input dim: {input_dim}")
    print(f"  Hidden dim: {args.hidden_dim}")
    print(f"  Output classes: 3 (SELL=0, HOLD=1, BUY=2)")
    print(f"  Parameters: {sum(p.numel() for p in model.parameters()):,}")
    print()

    # Training arguments
    training_args = TrainingArguments(
        output_dir=args.output_dir,
        num_train_epochs=args.epochs,
        per_device_train_batch_size=args.batch_size,
        per_device_eval_batch_size=args.batch_size,
        learning_rate=args.learning_rate,
        logging_steps=10,
        evaluation_strategy="epoch",
        save_strategy="epoch",
        load_best_model_at_end=True,
        metric_for_best_model="eval_loss",
    )

    # Custom data collator
    def collate_fn(batch):
        features = torch.stack([item['features'] for item in batch])
        labels = torch.stack([item['labels'] for item in batch])
        return {'features': features, 'labels': labels}

    # Create trainer
    trainer = Trainer(
        model=model,
        args=training_args,
        train_dataset=train_dataset,
        eval_dataset=test_dataset,
        data_collator=collate_fn,
    )

    # Train
    print("Starting training...")
    print()

    start_time = time.time()
    trainer.train()
    training_time = time.time() - start_time

    # Evaluate
    print()
    print("Evaluating on test set...")

    model.eval()
    predictions = []
    true_labels = []

    test_loader = DataLoader(test_dataset, batch_size=args.batch_size, collate_fn=collate_fn)

    with torch.no_grad():
        for batch in test_loader:
            features = batch['features'].to(args.device)
            labels = batch['labels'].to(args.device)

            outputs = model(features)
            preds = torch.argmax(outputs['logits'], dim=1)

            predictions.extend(preds.cpu().numpy())
            true_labels.extend(labels.cpu().numpy())

    # Classification report
    class_names = ['SELL', 'HOLD', 'BUY']
    print()
    print("Classification Report:")
    print(classification_report(true_labels, predictions, target_names=class_names))

    print("Confusion Matrix:")
    cm = confusion_matrix(true_labels, predictions)
    print(cm)

    # Save model
    output_path = Path(args.output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    # Save model state
    torch.save({
        'model_state_dict': model.state_dict(),
        'scaler': scaler,
        'input_dim': input_dim,
        'hidden_dim': args.hidden_dim,
        'config': vars(args)
    }, output_path / 'model.pt')

    print(f"\n✓ Model saved to: {output_path}")

    print()
    print("=" * 50)
    print("Training Complete!")
    print("=" * 50)
    print(f"Training time: {training_time:.2f} seconds ({training_time/60:.2f} minutes)")
    print(f"Model saved to: {args.output_dir}")
    print()
    print("Next steps:")
    print("  1. Test inference: python inference.py")
    print("  2. Deploy to Modal: modal deploy modal_deploy.py")


if __name__ == "__main__":
    main()
