"""
ML Training Template
Customize this template for your specific use case
"""

import argparse
import time
from pathlib import Path

import torch
from torch.utils.data import Dataset, DataLoader
from transformers import AutoTokenizer, AutoModel
from sklearn.model_selection import train_test_split
import numpy as np


class CustomDataset(Dataset):
    """Custom dataset - modify for your data format"""

    def __init__(self, data, labels, tokenizer=None):
        self.data = data
        self.labels = labels
        self.tokenizer = tokenizer

    def __len__(self):
        return len(self.labels)

    def __getitem__(self, idx):
        # TODO: Customize based on your data type
        item = self.data[idx]
        label = self.labels[idx]

        if self.tokenizer:
            # For text data
            encoding = self.tokenizer(
                item,
                truncation=True,
                max_length=512,
                padding='max_length',
                return_tensors='pt'
            )
            return {
                'input_ids': encoding['input_ids'].flatten(),
                'attention_mask': encoding['attention_mask'].flatten(),
                'labels': torch.tensor(label, dtype=torch.long)
            }
        else:
            # For numerical data
            return {
                'features': torch.tensor(item, dtype=torch.float),
                'labels': torch.tensor(label, dtype=torch.long)
            }


def load_data(data_path):
    """
    Load your training data

    TODO: Implement data loading logic
    """
    # Example: Load from CSV, JSON, database, etc.
    data = []  # Your input data
    labels = []  # Your labels

    return data, labels


def create_model(num_classes, model_type='classifier'):
    """
    Create model architecture

    TODO: Customize model for your task
    """
    if model_type == 'transformer':
        # Use pretrained transformer
        from transformers import AutoModelForSequenceClassification
        model = AutoModelForSequenceClassification.from_pretrained(
            'bert-base-uncased',
            num_labels=num_classes
        )
    else:
        # Custom neural network
        class CustomModel(torch.nn.Module):
            def __init__(self, input_dim, num_classes):
                super().__init__()
                self.network = torch.nn.Sequential(
                    torch.nn.Linear(input_dim, 128),
                    torch.nn.ReLU(),
                    torch.nn.Dropout(0.3),
                    torch.nn.Linear(128, num_classes)
                )

            def forward(self, features, labels=None):
                logits = self.network(features)
                loss = None
                if labels is not None:
                    loss_fct = torch.nn.CrossEntropyLoss()
                    loss = loss_fct(logits, labels)
                return {'loss': loss, 'logits': logits}

        model = CustomModel(input_dim=10, num_classes=num_classes)

    return model


def train_epoch(model, dataloader, optimizer, device):
    """Train for one epoch"""
    model.train()
    total_loss = 0
    correct = 0
    total = 0

    for batch in dataloader:
        optimizer.zero_grad()

        # TODO: Adjust based on your data format
        if 'input_ids' in batch:
            # Transformer model
            outputs = model(
                input_ids=batch['input_ids'].to(device),
                attention_mask=batch['attention_mask'].to(device),
                labels=batch['labels'].to(device)
            )
        else:
            # Custom model
            outputs = model(
                features=batch['features'].to(device),
                labels=batch['labels'].to(device)
            )

        loss = outputs['loss']
        total_loss += loss.item()

        loss.backward()
        optimizer.step()

        # Calculate accuracy
        preds = torch.argmax(outputs['logits'], dim=1)
        correct += (preds == batch['labels'].to(device)).sum().item()
        total += batch['labels'].size(0)

    avg_loss = total_loss / len(dataloader)
    accuracy = correct / total

    return avg_loss, accuracy


def evaluate(model, dataloader, device):
    """Evaluate model"""
    model.eval()
    total_loss = 0
    correct = 0
    total = 0

    with torch.no_grad():
        for batch in dataloader:
            # TODO: Adjust based on your data format
            if 'input_ids' in batch:
                outputs = model(
                    input_ids=batch['input_ids'].to(device),
                    attention_mask=batch['attention_mask'].to(device),
                    labels=batch['labels'].to(device)
                )
            else:
                outputs = model(
                    features=batch['features'].to(device),
                    labels=batch['labels'].to(device)
                )

            total_loss += outputs['loss'].item()

            preds = torch.argmax(outputs['logits'], dim=1)
            correct += (preds == batch['labels'].to(device)).sum().item()
            total += batch['labels'].size(0)

    avg_loss = total_loss / len(dataloader)
    accuracy = correct / total

    return avg_loss, accuracy


def main():
    parser = argparse.ArgumentParser(description='Train ML model')
    parser.add_argument('--data', type=str, required=True,
                        help='Path to training data')
    parser.add_argument('--epochs', type=int, default=10,
                        help='Number of training epochs')
    parser.add_argument('--batch-size', type=int, default=32,
                        help='Training batch size')
    parser.add_argument('--learning-rate', type=float, default=1e-3,
                        help='Learning rate')
    parser.add_argument('--device', type=str,
                        default='cuda' if torch.cuda.is_available() else 'cpu',
                        help='Device (cuda/cpu)')
    parser.add_argument('--output-dir', type=str, default='models/my-model',
                        help='Output directory')

    args = parser.parse_args()

    print("=" * 50)
    print("ML Training")
    print("=" * 50)
    print(f"\nConfiguration:")
    print(f"  Data: {args.data}")
    print(f"  Epochs: {args.epochs}")
    print(f"  Batch size: {args.batch_size}")
    print(f"  Learning rate: {args.learning_rate}")
    print(f"  Device: {args.device}")
    print()

    # Load data
    print("Loading data...")
    data, labels = load_data(args.data)
    print(f"  Total samples: {len(data)}")

    # Split data
    train_data, val_data, train_labels, val_labels = train_test_split(
        data, labels, test_size=0.2, random_state=42
    )

    # Create datasets
    # TODO: Set tokenizer if using transformers
    tokenizer = None  # Or AutoTokenizer.from_pretrained('bert-base-uncased')

    train_dataset = CustomDataset(train_data, train_labels, tokenizer)
    val_dataset = CustomDataset(val_data, val_labels, tokenizer)

    train_loader = DataLoader(train_dataset, batch_size=args.batch_size, shuffle=True)
    val_loader = DataLoader(val_dataset, batch_size=args.batch_size)

    # Create model
    num_classes = len(set(labels))
    model = create_model(num_classes)
    model.to(args.device)

    print(f"  Model parameters: {sum(p.numel() for p in model.parameters()):,}")
    print()

    # Optimizer
    optimizer = torch.optim.Adam(model.parameters(), lr=args.learning_rate)

    # Training loop
    print("Starting training...")
    print()

    best_val_acc = 0
    start_time = time.time()

    for epoch in range(args.epochs):
        print(f"Epoch {epoch + 1}/{args.epochs}")

        train_loss, train_acc = train_epoch(model, train_loader, optimizer, args.device)
        val_loss, val_acc = evaluate(model, val_loader, args.device)

        print(f"  Train Loss: {train_loss:.4f} | Train Acc: {train_acc:.4f}")
        print(f"  Val Loss:   {val_loss:.4f} | Val Acc:   {val_acc:.4f}")

        # Save best model
        if val_acc > best_val_acc:
            best_val_acc = val_acc
            output_path = Path(args.output_dir)
            output_path.mkdir(parents=True, exist_ok=True)

            torch.save({
                'model_state_dict': model.state_dict(),
                'config': vars(args),
                'epoch': epoch,
                'val_acc': val_acc
            }, output_path / 'model.pt')

            print(f"  ✓ Model saved")

        print()

    training_time = time.time() - start_time

    print("=" * 50)
    print("Training Complete!")
    print("=" * 50)
    print(f"Training time: {training_time:.2f} seconds")
    print(f"Best validation accuracy: {best_val_acc:.4f}")
    print(f"Model saved to: {args.output_dir}")


if __name__ == "__main__":
    main()
