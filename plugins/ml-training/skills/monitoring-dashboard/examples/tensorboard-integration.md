# TensorBoard Integration Guide

Complete guide for integrating TensorBoard into your ML training pipeline.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Basic Integration](#basic-integration)
3. [Advanced Features](#advanced-features)
4. [PyTorch Integration](#pytorch-integration)
5. [TensorFlow Integration](#tensorflow-integration)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)

## Quick Start

### 1. Install TensorBoard

```bash
pip install tensorboard torch
```

### 2. Minimal Integration

```python
from torch.utils.tensorboard import SummaryWriter

# Create writer
writer = SummaryWriter('runs/experiment_1')

# Log metrics
for epoch in range(10):
    writer.add_scalar('Loss/train', loss, epoch)

# Close writer
writer.close()
```

### 3. Launch Dashboard

```bash
tensorboard --logdir runs
# Open http://localhost:6006
```

## Basic Integration

### Complete Training Loop Example

```python
import torch
import torch.nn as nn
from torch.utils.tensorboard import SummaryWriter
from datetime import datetime

# Initialize TensorBoard writer
timestamp = datetime.now().strftime('%Y%m%d-%H%M%S')
writer = SummaryWriter(f'runs/experiment_{timestamp}')

# Model, optimizer, loss
model = nn.Sequential(
    nn.Linear(784, 256),
    nn.ReLU(),
    nn.Linear(256, 10)
)
optimizer = torch.optim.Adam(model.parameters(), lr=0.001)
criterion = nn.CrossEntropyLoss()

# Log hyperparameters
writer.add_text('hyperparameters', f"""
Learning Rate: {0.001}
Batch Size: {32}
Optimizer: Adam
Model: 2-layer MLP
""", 0)

# Training loop
num_epochs = 10
global_step = 0

for epoch in range(num_epochs):
    model.train()
    train_loss = 0.0
    train_correct = 0
    train_total = 0

    for batch_idx, (data, target) in enumerate(train_loader):
        # Forward pass
        optimizer.zero_grad()
        output = model(data)
        loss = criterion(output, target)

        # Backward pass
        loss.backward()
        optimizer.step()

        # Track metrics
        train_loss += loss.item()
        _, predicted = output.max(1)
        train_total += target.size(0)
        train_correct += predicted.eq(target).sum().item()

        # Log batch-level metrics every 100 batches
        if batch_idx % 100 == 0:
            writer.add_scalar('Loss/train_batch', loss.item(), global_step)
            global_step += 1

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
    writer.add_scalar('Loss/train', avg_train_loss, epoch)
    writer.add_scalar('Loss/validation', avg_val_loss, epoch)
    writer.add_scalar('Accuracy/train', train_acc, epoch)
    writer.add_scalar('Accuracy/validation', val_acc, epoch)
    writer.add_scalar('Learning_Rate', optimizer.param_groups[0]['lr'], epoch)

    # Log weight histograms every epoch
    for name, param in model.named_parameters():
        writer.add_histogram(f'weights/{name}', param, epoch)
        if param.grad is not None:
            writer.add_histogram(f'gradients/{name}', param.grad, epoch)

    print(f'Epoch {epoch}: Train Loss={avg_train_loss:.4f}, Val Loss={avg_val_loss:.4f}')

# Log final model graph
dummy_input = torch.randn(1, 784)
writer.add_graph(model, dummy_input)

# Close writer
writer.close()
print('Training complete! View results at http://localhost:6006')
```

## Advanced Features

### 1. Image Logging

```python
import torchvision.utils as vutils
import numpy as np

# Log single image
img = np.random.rand(3, 224, 224)
writer.add_image('sample_image', img, epoch)

# Log batch of images
img_batch = torch.randn(8, 3, 224, 224)
img_grid = vutils.make_grid(img_batch, normalize=True)
writer.add_image('image_batch', img_grid, epoch)

# Log predictions vs ground truth
def log_predictions(model, data_loader, epoch, num_images=8):
    model.eval()
    images, labels = next(iter(data_loader))

    with torch.no_grad():
        outputs = model(images[:num_images])
        _, predicted = outputs.max(1)

    # Create grid with labels
    img_grid = vutils.make_grid(images[:num_images], normalize=True)

    # Add text overlay (labels)
    label_text = ' | '.join([
        f'True: {labels[i].item()}, Pred: {predicted[i].item()}'
        for i in range(num_images)
    ])

    writer.add_image('predictions', img_grid, epoch)
    writer.add_text('prediction_labels', label_text, epoch)

# Log every 5 epochs
if epoch % 5 == 0:
    log_predictions(model, val_loader, epoch)
```

### 2. Embedding Visualization (t-SNE)

```python
# Extract embeddings
def get_embeddings(model, data_loader, num_samples=1000):
    model.eval()
    embeddings = []
    labels = []
    images = []

    with torch.no_grad():
        for data, target in data_loader:
            # Get embeddings from penultimate layer
            embed = model.features(data)  # Adjust to your model
            embeddings.append(embed)
            labels.append(target)
            images.append(data)

            if len(embeddings) * data.size(0) >= num_samples:
                break

    embeddings = torch.cat(embeddings)[:num_samples]
    labels = torch.cat(labels)[:num_samples]
    images = torch.cat(images)[:num_samples]

    return embeddings, labels, images

# Log embeddings
embeddings, labels, images = get_embeddings(model, val_loader)
writer.add_embedding(
    embeddings,
    metadata=labels,
    label_img=images,
    tag='validation_embeddings'
)
```

### 3. Custom Scalars and Layouts

```python
# Define custom layout
layout = {
    'Training Metrics': {
        'loss': ['Multiline', ['Loss/train', 'Loss/validation']],
        'accuracy': ['Multiline', ['Accuracy/train', 'Accuracy/validation']],
    },
    'Hyperparameters': {
        'learning_rate': ['Multiline', ['Learning_Rate']],
    },
}
writer.add_custom_scalars(layout)

# Log multiple related metrics
writer.add_scalars('Loss', {
    'train': train_loss,
    'validation': val_loss
}, epoch)

writer.add_scalars('Accuracy', {
    'train': train_acc,
    'validation': val_acc
}, epoch)
```

### 4. PR Curves (Precision-Recall)

```python
from torch.utils.tensorboard import SummaryWriter
from sklearn.metrics import precision_recall_curve

# Get predictions and true labels
def get_pr_curve_data(model, data_loader):
    model.eval()
    all_probs = []
    all_labels = []

    with torch.no_grad():
        for data, target in data_loader:
            output = model(data)
            probs = torch.softmax(output, dim=1)
            all_probs.append(probs)
            all_labels.append(target)

    return torch.cat(all_probs), torch.cat(all_labels)

# Log PR curve for each class
probs, labels = get_pr_curve_data(model, val_loader)
for class_idx in range(num_classes):
    class_probs = probs[:, class_idx]
    class_labels = (labels == class_idx).float()

    writer.add_pr_curve(
        f'pr_curve/class_{class_idx}',
        class_labels,
        class_probs,
        epoch
    )
```

### 5. Audio Logging

```python
import torch
import torchaudio

# Log audio sample
audio_sample, sample_rate = torchaudio.load('audio.wav')
writer.add_audio('audio_sample', audio_sample, epoch, sample_rate=sample_rate)

# Log generated audio (e.g., from TTS model)
generated_audio = model.generate_audio(text)
writer.add_audio('generated_audio', generated_audio, epoch, sample_rate=22050)
```

## PyTorch Integration

### With PyTorch Lightning

```python
import pytorch_lightning as pl
from pytorch_lightning.loggers import TensorBoardLogger

class MyModel(pl.LightningModule):
    def training_step(self, batch, batch_idx):
        x, y = batch
        y_hat = self(x)
        loss = F.cross_entropy(y_hat, y)

        # Log automatically
        self.log('train_loss', loss)
        return loss

    def validation_step(self, batch, batch_idx):
        x, y = batch
        y_hat = self(x)
        loss = F.cross_entropy(y_hat, y)

        # Log automatically
        self.log('val_loss', loss)
        return loss

# Use TensorBoard logger
logger = TensorBoardLogger('runs', name='my_model')
trainer = pl.Trainer(logger=logger, max_epochs=10)
trainer.fit(model, train_loader, val_loader)
```

### With Hugging Face Transformers

```python
from transformers import Trainer, TrainingArguments

training_args = TrainingArguments(
    output_dir='./results',
    logging_dir='./runs',  # TensorBoard log directory
    logging_steps=100,
    evaluation_strategy='epoch',
    save_strategy='epoch',
    report_to='tensorboard',  # Enable TensorBoard logging
)

trainer = Trainer(
    model=model,
    args=training_args,
    train_dataset=train_dataset,
    eval_dataset=eval_dataset,
)

trainer.train()
```

## TensorFlow Integration

```python
import tensorflow as tf
from datetime import datetime

# Create callback
log_dir = f"runs/experiment_{datetime.now().strftime('%Y%m%d-%H%M%S')}"
tensorboard_callback = tf.keras.callbacks.TensorBoard(
    log_dir=log_dir,
    histogram_freq=1,
    write_graph=True,
    write_images=True,
    update_freq='epoch',
    profile_batch='500,520',
)

# Train model
model.fit(
    train_dataset,
    epochs=10,
    validation_data=val_dataset,
    callbacks=[tensorboard_callback]
)
```

## Best Practices

### 1. Organize Logs by Experiment

```python
import os
from datetime import datetime

def create_experiment_dir(base_dir='runs', experiment_name=None):
    timestamp = datetime.now().strftime('%Y%m%d-%H%M%S')

    if experiment_name:
        exp_dir = f'{base_dir}/{experiment_name}_{timestamp}'
    else:
        exp_dir = f'{base_dir}/experiment_{timestamp}'

    os.makedirs(exp_dir, exist_ok=True)
    return exp_dir

# Usage
log_dir = create_experiment_dir(experiment_name='resnet50_lr0.001')
writer = SummaryWriter(log_dir)
```

### 2. Hierarchical Metric Naming

```python
# Good: Organized by category
writer.add_scalar('Loss/train', train_loss, epoch)
writer.add_scalar('Loss/validation', val_loss, epoch)
writer.add_scalar('Accuracy/train', train_acc, epoch)
writer.add_scalar('Accuracy/validation', val_acc, epoch)
writer.add_scalar('Metrics/precision', precision, epoch)
writer.add_scalar('Metrics/recall', recall, epoch)

# Bad: Flat naming
writer.add_scalar('train_loss', train_loss, epoch)
writer.add_scalar('val_loss', val_loss, epoch)
```

### 3. Efficient Logging

```python
# Log batch metrics less frequently
if batch_idx % 100 == 0:
    writer.add_scalar('Loss/train_batch', loss.item(), global_step)

# Log epoch metrics every epoch
writer.add_scalar('Loss/train_epoch', avg_loss, epoch)

# Log expensive operations (histograms, images) even less frequently
if epoch % 5 == 0:
    for name, param in model.named_parameters():
        writer.add_histogram(f'weights/{name}', param, epoch)

    log_sample_images(writer, model, val_loader, epoch)
```

### 4. Compare Multiple Experiments

```bash
# Method 1: Multiple log directories
tensorboard --logdir_spec \
  baseline:runs/experiment_baseline,\
  resnet50:runs/experiment_resnet50,\
  vit:runs/experiment_vit

# Method 2: Hierarchical structure
# Organize as: runs/model_name/experiment_id
tensorboard --logdir runs
```

### 5. Clean Up Old Logs

```bash
# Archive old experiments
mkdir -p runs/archive
mv runs/experiment_old runs/archive/

# Compress archived experiments
tar -czf runs/archive_$(date +%Y%m%d).tar.gz runs/archive/
rm -rf runs/archive/

# Delete very old logs
find runs/ -type d -mtime +90 -exec rm -rf {} +
```

## Troubleshooting

### Problem: Dashboard Not Updating

**Solution:**
```bash
# Force reload
tensorboard --logdir runs --reload_interval 1

# Clear cache
rm -rf /tmp/.tensorboard-info/
```

### Problem: Port Already in Use

**Solution:**
```bash
# Use different port
tensorboard --logdir runs --port 6007

# Kill existing process
pkill -f tensorboard
```

### Problem: Slow Loading

**Solution:**
```bash
# Limit samples loaded
tensorboard --logdir runs --samples_per_plugin scalars=1000

# Disable specific plugins
tensorboard --logdir runs --reload_multifile=false
```

### Problem: Memory Issues

**Solution:**
```python
# Reduce flush frequency
writer = SummaryWriter(log_dir=log_dir, flush_secs=300)

# Close writer periodically
if epoch % 10 == 0:
    writer.close()
    writer = SummaryWriter(log_dir=log_dir)
```

### Problem: Graph Not Showing

**Solution:**
```python
# Ensure input tensor has correct shape
dummy_input = torch.randn(1, *input_shape)  # Batch size of 1
writer.add_graph(model, dummy_input)

# Put model in eval mode
model.eval()
with torch.no_grad():
    writer.add_graph(model, dummy_input)
```

## Summary

TensorBoard is excellent for:
- Local development and debugging
- Real-time training visualization
- Model architecture inspection
- Quick experiment comparison

**Next Steps:**
- Try the [WandB integration guide](wandb-integration.md) for team collaboration
- Use unified logging with [logging-config.json](../templates/logging-config.json)
- Automate setup with [setup-tensorboard.sh](../scripts/setup-tensorboard.sh)

**Resources:**
- Official Docs: https://www.tensorflow.org/tensorboard
- PyTorch Guide: https://pytorch.org/docs/stable/tensorboard.html
- Examples: https://github.com/tensorflow/tensorboard/tree/master/docs
