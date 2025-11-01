# Weights & Biases (WandB) Integration Guide

Complete guide for integrating Weights & Biases into your ML training pipeline for team collaboration and experiment tracking.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Basic Integration](#basic-integration)
3. [Advanced Features](#advanced-features)
4. [Hyperparameter Sweeps](#hyperparameter-sweeps)
5. [Model Artifacts](#model-artifacts)
6. [Collaboration Features](#collaboration-features)
7. [Framework Integration](#framework-integration)
8. [Best Practices](#best-practices)
9. [Troubleshooting](#troubleshooting)

## Quick Start

### 1. Setup

```bash
pip install wandb
wandb login
```

### 2. Minimal Integration

```python
import wandb

# Initialize run
wandb.init(project="my-project", config={"lr": 0.001})

# Log metrics
for epoch in range(10):
    wandb.log({"loss": loss, "accuracy": acc})

# Finish run
wandb.finish()
```

### 3. View Dashboard

Open browser to: https://wandb.ai/your-username/your-project

## Basic Integration

### Complete Training Loop Example

```python
import wandb
import torch
import torch.nn as nn
from datetime import datetime

# Initialize WandB run
run = wandb.init(
    project="mnist-classification",
    name=f"run-{datetime.now().strftime('%Y%m%d-%H%M%S')}",
    config={
        "learning_rate": 0.001,
        "batch_size": 32,
        "epochs": 10,
        "optimizer": "adam",
        "model": "2-layer-mlp",
        "dataset": "mnist"
    },
    tags=["baseline", "mlp"],
    notes="Baseline experiment with 2-layer MLP"
)

# Access config
config = wandb.config

# Model, optimizer, loss
model = nn.Sequential(
    nn.Linear(784, 256),
    nn.ReLU(),
    nn.Dropout(0.2),
    nn.Linear(256, 10)
)
optimizer = torch.optim.Adam(model.parameters(), lr=config.learning_rate)
criterion = nn.CrossEntropyLoss()

# Watch model (track gradients and parameters)
wandb.watch(model, log="all", log_freq=100)

# Training loop
for epoch in range(config.epochs):
    model.train()
    train_loss = 0.0
    train_correct = 0
    train_total = 0

    for batch_idx, (data, target) in enumerate(train_loader):
        optimizer.zero_grad()
        output = model(data)
        loss = criterion(output, target)
        loss.backward()
        optimizer.step()

        train_loss += loss.item()
        _, predicted = output.max(1)
        train_total += target.size(0)
        train_correct += predicted.eq(target).sum().item()

        # Log batch-level metrics
        if batch_idx % 100 == 0:
            wandb.log({
                "batch_loss": loss.item(),
                "batch_idx": batch_idx,
                "epoch": epoch
            })

    # Calculate epoch metrics
    avg_train_loss = train_loss / len(train_loader)
    train_acc = 100. * train_correct / train_total

    # Validation
    model.eval()
    val_loss = 0.0
    val_correct = 0
    val_total = 0

    with torch.no_grad():
        for data, target in val_loader:
            output = model(data)
            loss = criterion(output, target)
            val_loss += loss.item()

            _, predicted = output.max(1)
            val_total += target.size(0)
            val_correct += predicted.eq(target).sum().item()

    avg_val_loss = val_loss / len(val_loader)
    val_acc = 100. * val_correct / val_total

    # Log epoch-level metrics
    wandb.log({
        "epoch": epoch,
        "train/loss": avg_train_loss,
        "train/accuracy": train_acc,
        "val/loss": avg_val_loss,
        "val/accuracy": val_acc,
        "learning_rate": optimizer.param_groups[0]['lr']
    })

    # Log sample predictions every 5 epochs
    if epoch % 5 == 0:
        log_predictions(model, val_loader, epoch)

    print(f'Epoch {epoch}: Train Loss={avg_train_loss:.4f}, Val Acc={val_acc:.2f}%')

# Save final model
torch.save(model.state_dict(), 'model.pth')

# Log model as artifact
artifact = wandb.Artifact('mnist-model', type='model')
artifact.add_file('model.pth')
wandb.log_artifact(artifact)

# Finish run
wandb.finish()
print(f'Training complete! View at: {run.url}')
```

## Advanced Features

### 1. Logging Media

#### Images

```python
import wandb
import numpy as np
from PIL import Image

# Single image
img = np.random.rand(224, 224, 3)
wandb.log({"image": wandb.Image(img, caption="Random image")})

# Multiple images
images = [wandb.Image(img, caption=f"Image {i}") for i, img in enumerate(image_list)]
wandb.log({"gallery": images})

# With bounding boxes (object detection)
class_labels = {0: "cat", 1: "dog"}
boxes = {
    "predictions": {
        "box_data": [
            {"position": {"minX": 10, "minY": 10, "maxX": 100, "maxY": 100},
             "class_id": 0, "box_caption": "cat", "scores": {"confidence": 0.95}}
        ],
        "class_labels": class_labels
    }
}
wandb.log({"predictions": wandb.Image(img, boxes=boxes)})
```

#### Tables

```python
# Create table
columns = ["epoch", "train_loss", "val_loss", "train_acc", "val_acc"]
data = [
    [1, 0.5, 0.6, 0.75, 0.70],
    [2, 0.4, 0.5, 0.80, 0.75],
    [3, 0.3, 0.4, 0.85, 0.80],
]
table = wandb.Table(columns=columns, data=data)
wandb.log({"results": table})

# Prediction table
pred_table = wandb.Table(columns=["image", "prediction", "ground_truth", "confidence"])
for img, pred, truth, conf in zip(images, predictions, labels, confidences):
    pred_table.add_data(wandb.Image(img), pred, truth, conf)
wandb.log({"predictions_table": pred_table})
```

#### Audio

```python
# Log audio
audio_array = np.random.randn(16000)  # 1 second at 16kHz
wandb.log({"audio": wandb.Audio(audio_array, sample_rate=16000)})

# With caption
wandb.log({
    "generated_speech": wandb.Audio(
        audio_array,
        caption="Generated speech",
        sample_rate=22050
    )
})
```

#### Video

```python
# Log video from file
wandb.log({"video": wandb.Video("output.mp4", fps=30)})

# Log from numpy array
video_array = np.random.randint(0, 256, (10, 224, 224, 3))  # 10 frames
wandb.log({"training_video": wandb.Video(video_array, fps=4)})
```

### 2. Custom Charts and Visualizations

```python
# Line plot
data = [[x, y] for (x, y) in zip(x_values, y_values)]
table = wandb.Table(data=data, columns=["x", "y"])
wandb.log({
    "custom_line_plot": wandb.plot.line(
        table, "x", "y",
        title="Custom Line Plot"
    )
})

# Scatter plot
data = [[x, y, label] for (x, y, label) in zip(x_values, y_values, labels)]
table = wandb.Table(data=data, columns=["x", "y", "label"])
wandb.log({
    "scatter": wandb.plot.scatter(
        table, "x", "y",
        title="Feature Space Visualization"
    )
})

# Confusion matrix
wandb.log({
    "confusion_matrix": wandb.plot.confusion_matrix(
        probs=predictions,
        y_true=ground_truth,
        class_names=class_names
    )
})

# PR curve
wandb.log({
    "pr_curve": wandb.plot.pr_curve(
        ground_truth, predictions,
        labels=class_names
    )
})

# ROC curve
wandb.log({
    "roc_curve": wandb.plot.roc_curve(
        ground_truth, predictions,
        labels=class_names
    )
})
```

### 3. Alerts

```python
# Alert on high accuracy
if val_acc > 0.95:
    wandb.alert(
        title="High Accuracy Achieved",
        text=f"Validation accuracy reached {val_acc:.2%} at epoch {epoch}",
        level=wandb.AlertLevel.INFO,
        wait_duration=300  # Don't send another alert for 5 minutes
    )

# Alert on high loss
if train_loss > 10.0:
    wandb.alert(
        title="Training Instability",
        text=f"Training loss spiked to {train_loss:.2f}",
        level=wandb.AlertLevel.WARN
    )

# Alert on error
try:
    result = risky_operation()
except Exception as e:
    wandb.alert(
        title="Training Error",
        text=f"Error occurred: {str(e)}",
        level=wandb.AlertLevel.ERROR
    )
    raise
```

## Hyperparameter Sweeps

### 1. Define Sweep Configuration

```python
sweep_config = {
    'method': 'bayes',  # grid, random, bayes
    'metric': {
        'name': 'val/loss',
        'goal': 'minimize'
    },
    'parameters': {
        'learning_rate': {
            'min': 0.0001,
            'max': 0.1,
            'distribution': 'log_uniform_values'
        },
        'batch_size': {
            'values': [16, 32, 64, 128]
        },
        'optimizer': {
            'values': ['adam', 'sgd', 'adamw', 'rmsprop']
        },
        'dropout': {
            'min': 0.0,
            'max': 0.5
        },
        'hidden_size': {
            'values': [128, 256, 512, 1024]
        },
        'num_layers': {
            'values': [2, 3, 4, 5]
        }
    },
    'early_terminate': {
        'type': 'hyperband',
        'min_iter': 3,
        'eta': 2,
        's': 3
    }
}
```

### 2. Create Training Function for Sweep

```python
def train_sweep():
    # Initialize run
    run = wandb.init()

    # Access sweep parameters
    config = wandb.config

    # Build model based on config
    model = build_model(
        hidden_size=config.hidden_size,
        num_layers=config.num_layers,
        dropout=config.dropout
    )

    # Optimizer based on config
    if config.optimizer == 'adam':
        optimizer = torch.optim.Adam(model.parameters(), lr=config.learning_rate)
    elif config.optimizer == 'sgd':
        optimizer = torch.optim.SGD(model.parameters(), lr=config.learning_rate)
    elif config.optimizer == 'adamw':
        optimizer = torch.optim.AdamW(model.parameters(), lr=config.learning_rate)

    # Training loop
    for epoch in range(config.epochs):
        train_loss, train_acc = train_epoch(model, train_loader, optimizer)
        val_loss, val_acc = validate(model, val_loader)

        # Log metrics
        wandb.log({
            'epoch': epoch,
            'train/loss': train_loss,
            'val/loss': val_loss,
            'train/accuracy': train_acc,
            'val/accuracy': val_acc
        })

    wandb.finish()
```

### 3. Run Sweep

```python
# Initialize sweep
sweep_id = wandb.sweep(sweep_config, project="hyperparameter-tuning")

# Run sweep agent
wandb.agent(sweep_id, function=train_sweep, count=50)  # Run 50 trials
```

### 4. Advanced Sweep Strategies

```python
# Grid search (exhaustive)
grid_sweep = {
    'method': 'grid',
    'parameters': {
        'learning_rate': {'values': [0.001, 0.01, 0.1]},
        'batch_size': {'values': [32, 64, 128]}
    }
}

# Random search
random_sweep = {
    'method': 'random',
    'parameters': {
        'learning_rate': {'distribution': 'log_uniform', 'min': -9.21, 'max': -4.61},
        'dropout': {'distribution': 'uniform', 'min': 0, 'max': 0.5}
    }
}

# Bayesian optimization (recommended)
bayes_sweep = {
    'method': 'bayes',
    'metric': {'name': 'val/loss', 'goal': 'minimize'},
    'parameters': {
        'learning_rate': {
            'distribution': 'log_uniform_values',
            'min': 0.0001,
            'max': 0.1
        }
    },
    'early_terminate': {
        'type': 'hyperband',
        'max_iter': 27,
        'eta': 3
    }
}
```

## Model Artifacts

### 1. Save Model Checkpoints

```python
# Save checkpoint
def save_checkpoint(model, optimizer, epoch, loss):
    checkpoint = {
        'epoch': epoch,
        'model_state_dict': model.state_dict(),
        'optimizer_state_dict': optimizer.state_dict(),
        'loss': loss,
    }
    path = f'checkpoint_epoch_{epoch}.pth'
    torch.save(checkpoint, path)

    # Log as artifact
    artifact = wandb.Artifact(
        name=f'model-checkpoint',
        type='model',
        metadata={
            'epoch': epoch,
            'loss': loss,
            'architecture': 'resnet50'
        }
    )
    artifact.add_file(path)
    wandb.log_artifact(artifact)

    # Clean up local file
    os.remove(path)
```

### 2. Load Model from Artifact

```python
# Download and load artifact
run = wandb.init(project="my-project")

# Use latest version
artifact = run.use_artifact('model-checkpoint:latest', type='model')
artifact_dir = artifact.download()

# Load checkpoint
checkpoint = torch.load(f'{artifact_dir}/checkpoint_epoch_10.pth')
model.load_state_dict(checkpoint['model_state_dict'])
optimizer.load_state_dict(checkpoint['optimizer_state_dict'])

# Use specific version
artifact = run.use_artifact('model-checkpoint:v5', type='model')
```

### 3. Artifact Versioning

```python
# Create versioned artifacts
for epoch in range(num_epochs):
    if epoch % 5 == 0:  # Save every 5 epochs
        artifact = wandb.Artifact(
            f'model-epoch-{epoch}',
            type='model',
            metadata={'epoch': epoch, 'val_loss': val_loss}
        )
        artifact.add_file(f'model_epoch_{epoch}.pth')
        wandb.log_artifact(artifact, aliases=['latest', f'epoch-{epoch}'])

# Link best model
if val_loss < best_val_loss:
    wandb.log_artifact(artifact, aliases=['best'])
```

## Collaboration Features

### 1. Team Projects

```python
# Initialize with team
wandb.init(
    project="team-project",
    entity="my-team",  # Your team name
    tags=["production", "v2"],
    notes="Production model training v2"
)
```

### 2. Reports

Create shareable reports in the WandB UI:
- Navigate to your project
- Click "Create Report"
- Add visualizations, tables, and text
- Share link with team

### 3. Run Comparison

```python
# Tag runs for easy comparison
wandb.init(
    project="model-comparison",
    tags=["resnet50", "baseline"]
)

# Compare in UI by filtering tags
```

### 4. Comments and Discussion

Add comments in the WandB UI:
- Click on any run
- Add comments on specific metrics
- Tag team members with @mentions
- Track discussions over time

## Framework Integration

### PyTorch Lightning

```python
import pytorch_lightning as pl
from pytorch_lightning.loggers import WandbLogger

class MyModel(pl.LightningModule):
    def training_step(self, batch, batch_idx):
        x, y = batch
        y_hat = self(x)
        loss = F.cross_entropy(y_hat, y)
        self.log('train/loss', loss)
        return loss

    def validation_step(self, batch, batch_idx):
        x, y = batch
        y_hat = self(x)
        loss = F.cross_entropy(y_hat, y)
        self.log('val/loss', loss)
        return loss

# Use WandB logger
wandb_logger = WandbLogger(
    project='lightning-project',
    log_model='all',  # Log all checkpoints
    save_dir='./wandb_logs'
)

trainer = pl.Trainer(
    logger=wandb_logger,
    max_epochs=10,
    log_every_n_steps=50
)

trainer.fit(model, train_loader, val_loader)
```

### Hugging Face Transformers

```python
from transformers import Trainer, TrainingArguments

training_args = TrainingArguments(
    output_dir='./results',
    report_to='wandb',  # Enable WandB logging
    run_name='bert-finetuning',
    logging_steps=100,
    evaluation_strategy='epoch',
    save_strategy='epoch',
)

# Set project name
os.environ['WANDB_PROJECT'] = 'bert-finetuning'

trainer = Trainer(
    model=model,
    args=training_args,
    train_dataset=train_dataset,
    eval_dataset=eval_dataset,
)

trainer.train()
```

### Keras

```python
import wandb
from wandb.keras import WandbCallback

# Initialize
wandb.init(project='keras-project', config={
    'learning_rate': 0.001,
    'epochs': 10,
    'batch_size': 32
})

# Add callback
model.fit(
    train_dataset,
    epochs=10,
    validation_data=val_dataset,
    callbacks=[WandbCallback(
        monitor='val_loss',
        save_model=True,
        log_weights=True,
        log_gradients=True
    )]
)
```

## Best Practices

### 1. Project Organization

```python
# Use consistent project naming
PROJECTS = {
    'dev': 'my-model-dev',
    'staging': 'my-model-staging',
    'prod': 'my-model-prod'
}

wandb.init(project=PROJECTS['dev'])
```

### 2. Tagging Strategy

```python
# Tag by model, dataset, purpose
wandb.init(
    project='image-classification',
    tags=[
        'resnet50',        # Model architecture
        'imagenet',        # Dataset
        'baseline',        # Experiment type
        'v1.0',            # Version
        'gpu-4x-v100'      # Hardware
    ]
)
```

### 3. Metric Naming

```python
# Use hierarchical naming
wandb.log({
    'train/loss': train_loss,
    'train/accuracy': train_acc,
    'val/loss': val_loss,
    'val/accuracy': val_acc,
    'metrics/precision': precision,
    'metrics/recall': recall,
    'metrics/f1': f1_score,
    'system/gpu_memory': gpu_mem,
    'system/learning_rate': lr
})
```

### 4. Offline Mode

```python
# Run offline and sync later
wandb.init(mode='offline', project='my-project')

# Train as normal...

# Sync later
# wandb sync ./wandb/offline-run-*
```

### 5. Resume Failed Runs

```python
# Resume run with same ID
wandb.init(
    project='my-project',
    id='abc123',  # Previous run ID
    resume='must'  # Must resume this run
)

# Or allow resume if exists
wandb.init(project='my-project', resume='allow')
```

## Troubleshooting

### Problem: Login Issues

```bash
# Re-login
wandb login --relogin

# Or set API key directly
export WANDB_API_KEY=your_api_key

# Or in Python
wandb.login(key='your_api_key')
```

### Problem: Slow Logging

```python
# Reduce logging frequency
if step % 100 == 0:  # Log every 100 steps
    wandb.log(metrics)

# Disable system metrics
wandb.init(settings=wandb.Settings(
    _disable_stats=True,
    _disable_meta=True
))
```

### Problem: Large Files

```python
# Use references instead of uploading
artifact.add_reference(
    's3://my-bucket/large-file.bin',
    name='large-file'
)

# Or compress before uploading
import gzip
with gzip.open('model.pth.gz', 'wb') as f:
    torch.save(model.state_dict(), f)
artifact.add_file('model.pth.gz')
```

### Problem: Network Issues

```python
# Increase timeout
wandb.init(
    project='my-project',
    settings=wandb.Settings(
        _network_timeout=600  # 10 minutes
    )
)
```

## Summary

WandB is excellent for:
- Team collaboration and sharing
- Hyperparameter optimization
- Experiment tracking and comparison
- Model versioning and artifacts
- Production deployment tracking

**Next Steps:**
- Try the [TensorBoard integration guide](tensorboard-integration.md) for local development
- Use unified logging with [logging-config.json](../templates/logging-config.json)
- Automate setup with [setup-wandb.sh](../scripts/setup-wandb.sh)

**Resources:**
- Official Docs: https://docs.wandb.ai
- Examples: https://github.com/wandb/examples
- Community: https://wandb.ai/community
- API Reference: https://docs.wandb.ai/ref/python
