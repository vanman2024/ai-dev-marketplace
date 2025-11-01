"""
Sentiment Classification Training Script
Fine-tune DistilBERT for binary sentiment analysis
"""

import json
import os
import time
from pathlib import Path
import argparse

import torch
from torch.utils.data import Dataset, DataLoader
from transformers import (
    AutoTokenizer,
    AutoModelForSequenceClassification,
    AdamW,
    get_linear_schedule_with_warmup
)
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, precision_recall_fscore_support
import numpy as np


class SentimentDataset(Dataset):
    """Custom dataset for sentiment classification"""

    def __init__(self, texts, labels, tokenizer, max_length=512):
        self.texts = texts
        self.labels = labels
        self.tokenizer = tokenizer
        self.max_length = max_length

    def __len__(self):
        return len(self.texts)

    def __getitem__(self, idx):
        text = str(self.texts[idx])
        label = self.labels[idx]

        encoding = self.tokenizer(
            text,
            add_special_tokens=True,
            max_length=self.max_length,
            padding='max_length',
            truncation=True,
            return_tensors='pt'
        )

        return {
            'input_ids': encoding['input_ids'].flatten(),
            'attention_mask': encoding['attention_mask'].flatten(),
            'labels': torch.tensor(label, dtype=torch.long)
        }


def load_data(data_path):
    """Load training data from JSON file"""
    with open(data_path, 'r') as f:
        data = json.load(f)

    texts = [item['text'] for item in data]
    labels = [item['label'] for item in data]

    return texts, labels


def train_epoch(model, dataloader, optimizer, scheduler, device):
    """Train for one epoch"""
    model.train()
    total_loss = 0
    predictions = []
    true_labels = []

    for batch in dataloader:
        optimizer.zero_grad()

        input_ids = batch['input_ids'].to(device)
        attention_mask = batch['attention_mask'].to(device)
        labels = batch['labels'].to(device)

        outputs = model(
            input_ids=input_ids,
            attention_mask=attention_mask,
            labels=labels
        )

        loss = outputs.loss
        total_loss += loss.item()

        loss.backward()
        torch.nn.utils.clip_grad_norm_(model.parameters(), 1.0)

        optimizer.step()
        scheduler.step()

        # Track predictions
        preds = torch.argmax(outputs.logits, dim=1)
        predictions.extend(preds.cpu().numpy())
        true_labels.extend(labels.cpu().numpy())

    avg_loss = total_loss / len(dataloader)
    accuracy = accuracy_score(true_labels, predictions)

    return avg_loss, accuracy


def evaluate(model, dataloader, device):
    """Evaluate model on validation set"""
    model.eval()
    total_loss = 0
    predictions = []
    true_labels = []

    with torch.no_grad():
        for batch in dataloader:
            input_ids = batch['input_ids'].to(device)
            attention_mask = batch['attention_mask'].to(device)
            labels = batch['labels'].to(device)

            outputs = model(
                input_ids=input_ids,
                attention_mask=attention_mask,
                labels=labels
            )

            total_loss += outputs.loss.item()

            preds = torch.argmax(outputs.logits, dim=1)
            predictions.extend(preds.cpu().numpy())
            true_labels.extend(labels.cpu().numpy())

    avg_loss = total_loss / len(dataloader)
    accuracy = accuracy_score(true_labels, predictions)
    precision, recall, f1, _ = precision_recall_fscore_support(
        true_labels, predictions, average='binary'
    )

    return avg_loss, accuracy, precision, recall, f1


def main():
    parser = argparse.ArgumentParser(description='Train sentiment classifier')
    parser.add_argument('--data', type=str, default='data.json',
                        help='Path to training data JSON file')
    parser.add_argument('--model-name', type=str, default='distilbert-base-uncased',
                        help='Pretrained model name')
    parser.add_argument('--epochs', type=int, default=3,
                        help='Number of training epochs')
    parser.add_argument('--batch-size', type=int, default=8,
                        help='Training batch size')
    parser.add_argument('--learning-rate', type=float, default=2e-5,
                        help='Learning rate')
    parser.add_argument('--device', type=str, default='cuda' if torch.cuda.is_available() else 'cpu',
                        help='Device (cuda/cpu)')
    parser.add_argument('--output-dir', type=str, default='models/sentiment-classifier',
                        help='Output directory for saved model')

    args = parser.parse_args()

    print("=" * 50)
    print("Sentiment Classification Training")
    print("=" * 50)
    print(f"\nConfiguration:")
    print(f"  Model: {args.model_name}")
    print(f"  Epochs: {args.epochs}")
    print(f"  Batch size: {args.batch_size}")
    print(f"  Learning rate: {args.learning_rate}")
    print(f"  Device: {args.device}")
    print(f"  Data: {args.data}")
    print()

    # Load data
    print("Loading data...")
    texts, labels = load_data(args.data)
    print(f"  Total samples: {len(texts)}")
    print(f"  Positive samples: {sum(labels)}")
    print(f"  Negative samples: {len(labels) - sum(labels)}")

    # Split data
    train_texts, val_texts, train_labels, val_labels = train_test_split(
        texts, labels, test_size=0.2, random_state=42, stratify=labels
    )
    print(f"  Training samples: {len(train_texts)}")
    print(f"  Validation samples: {len(val_texts)}")
    print()

    # Load tokenizer and model
    print("Loading model and tokenizer...")
    tokenizer = AutoTokenizer.from_pretrained(args.model_name)
    model = AutoModelForSequenceClassification.from_pretrained(
        args.model_name,
        num_labels=2
    )
    model.to(args.device)
    print(f"  Model loaded: {args.model_name}")
    print(f"  Parameters: {sum(p.numel() for p in model.parameters()):,}")
    print()

    # Create datasets
    train_dataset = SentimentDataset(train_texts, train_labels, tokenizer)
    val_dataset = SentimentDataset(val_texts, val_labels, tokenizer)

    train_loader = DataLoader(train_dataset, batch_size=args.batch_size, shuffle=True)
    val_loader = DataLoader(val_dataset, batch_size=args.batch_size)

    # Setup optimizer and scheduler
    optimizer = AdamW(model.parameters(), lr=args.learning_rate)
    total_steps = len(train_loader) * args.epochs
    scheduler = get_linear_schedule_with_warmup(
        optimizer,
        num_warmup_steps=0,
        num_training_steps=total_steps
    )

    # Training loop
    print("Starting training...")
    print()

    best_val_accuracy = 0
    start_time = time.time()

    for epoch in range(args.epochs):
        print(f"Epoch {epoch + 1}/{args.epochs}")
        print("-" * 50)

        # Train
        train_loss, train_acc = train_epoch(
            model, train_loader, optimizer, scheduler, args.device
        )

        # Validate
        val_loss, val_acc, val_prec, val_rec, val_f1 = evaluate(
            model, val_loader, args.device
        )

        print(f"  Train Loss: {train_loss:.4f} | Train Acc: {train_acc:.4f}")
        print(f"  Val Loss:   {val_loss:.4f} | Val Acc:   {val_acc:.4f}")
        print(f"  Precision:  {val_prec:.4f} | Recall:    {val_rec:.4f} | F1: {val_f1:.4f}")

        # Save best model
        if val_acc > best_val_accuracy:
            best_val_accuracy = val_acc
            output_path = Path(args.output_dir)
            output_path.mkdir(parents=True, exist_ok=True)

            model.save_pretrained(output_path)
            tokenizer.save_pretrained(output_path)

            print(f"  ✓ Model saved to {output_path}")

        print()

    training_time = time.time() - start_time

    print("=" * 50)
    print("Training Complete!")
    print("=" * 50)
    print(f"Training time: {training_time:.2f} seconds ({training_time/60:.2f} minutes)")
    print(f"Best validation accuracy: {best_val_accuracy:.4f}")
    print(f"Final loss: {val_loss:.4f}")
    print(f"Model saved to: {args.output_dir}")
    print()
    print("Next steps:")
    print("  1. Test inference: python inference.py")
    print("  2. Deploy model: python modal_deploy.py")


if __name__ == "__main__":
    main()
