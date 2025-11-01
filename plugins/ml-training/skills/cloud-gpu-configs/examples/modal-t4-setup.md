# Modal T4 GPU Setup Example

Budget-friendly ML training setup using Modal's T4 GPUs. Perfect for experimentation, small models, and light inference workloads.

## Overview

**GPU**: NVIDIA T4
**VRAM**: 16GB
**Cost**: ~$0.20-0.40/hr
**Best For**:
- Small model training (BERT, GPT-2)
- Light inference
- Development and experimentation
- Budget-conscious projects

## Prerequisites

1. Modal account: https://modal.com
2. Modal CLI installed: `pip install modal`
3. Modal token: https://modal.com/settings

## Setup Steps

### 1. Install Modal

```bash
pip install modal
```

### 2. Authenticate

```bash
modal token new
```

### 3. Create Training Script

Create `train_bert_t4.py`:

```python
import modal

app = modal.App("bert-training-t4")

# Lightweight image for T4
image = (
    modal.Image.debian_slim(python_version="3.11")
    .pip_install(
        "torch",
        "transformers",
        "datasets",
        "wandb",
    )
)

# Volume for checkpoints
volume = modal.Volume.from_name("bert-checkpoints", create_if_missing=True)

@app.function(
    gpu="T4",
    image=image,
    timeout=3600,  # 1 hour
    memory=8192,   # 8GB RAM
    volumes={"/checkpoints": volume},
)
def train_bert():
    """Train BERT-base on IMDB dataset using T4 GPU"""
    import torch
    from transformers import (
        AutoModelForSequenceClassification,
        AutoTokenizer,
        Trainer,
        TrainingArguments,
    )
    from datasets import load_dataset

    print(f"GPU: {torch.cuda.get_device_name(0)}")
    print(f"VRAM: {torch.cuda.get_device_properties(0).total_memory / 1e9:.2f} GB")

    # Load dataset
    dataset = load_dataset("imdb")

    # Load model (small model for T4)
    model_name = "bert-base-uncased"
    tokenizer = AutoTokenizer.from_pretrained(model_name)
    model = AutoModelForSequenceClassification.from_pretrained(
        model_name,
        num_labels=2,
    )

    # Tokenize
    def tokenize(examples):
        return tokenizer(
            examples["text"],
            padding="max_length",
            truncation=True,
            max_length=256,  # Reduced for T4
        )

    tokenized = dataset.map(tokenize, batched=True)

    # Training args optimized for T4
    training_args = TrainingArguments(
        output_dir="/checkpoints",
        num_train_epochs=3,
        per_device_train_batch_size=16,  # Conservative batch size
        per_device_eval_batch_size=32,
        learning_rate=2e-5,
        warmup_steps=500,
        weight_decay=0.01,
        logging_steps=100,
        evaluation_strategy="epoch",
        save_strategy="epoch",
        fp16=True,  # Mixed precision for T4
        gradient_checkpointing=True,  # Reduce memory usage
    )

    # Train
    trainer = Trainer(
        model=model,
        args=training_args,
        train_dataset=tokenized["train"].select(range(5000)),  # Subset for demo
        eval_dataset=tokenized["test"].select(range(1000)),
    )

    print("Starting training...")
    trainer.train()

    # Save
    model.save_pretrained("/checkpoints/final_model")
    tokenizer.save_pretrained("/checkpoints/final_model")
    volume.commit()

    print("Training complete!")
    return {"status": "success"}

@app.local_entrypoint()
def main():
    result = train_bert.remote()
    print(f"Result: {result}")
```

### 4. Run Training

```bash
# Test run
modal run train_bert_t4.py

# Deploy as persistent app
modal deploy train_bert_t4.py
```

## T4 Optimization Tips

### 1. Batch Size
- Start with batch size 16-32
- Use gradient accumulation for larger effective batch sizes
- Monitor memory usage with `nvidia-smi`

### 2. Model Size
**Good fit for T4** (16GB VRAM):
- BERT-base (110M params)
- GPT-2 small (117M params)
- DistilBERT (66M params)
- RoBERTa-base (125M params)

**Tight squeeze**:
- BERT-large (340M params) - use gradient checkpointing
- T5-base (220M params)

**Too large**:
- GPT-2 large (774M params)
- T5-large (770M params)
- LLaMA models

### 3. Memory Optimization

```python
training_args = TrainingArguments(
    # ... other args ...
    fp16=True,                    # Mixed precision (2x memory savings)
    gradient_checkpointing=True,  # Trade compute for memory
    gradient_accumulation_steps=4, # Simulate larger batch size
    per_device_train_batch_size=8, # Reduce if OOM
)
```

### 4. Sequence Length
- Max 256 tokens for BERT-base (comfortable)
- Max 512 tokens with gradient checkpointing
- Truncate longer sequences

### 5. GPU Fallback

Use fallback for faster scheduling:

```python
@app.function(
    gpu=["T4", "L4"],  # Fallback to L4 if T4 unavailable
    # ... other params ...
)
```

## Cost Estimation

**Training Time**: ~1-2 hours for BERT-base on IMDB (25k examples)
**Cost**: $0.20-0.40/hr × 1.5hr = **$0.30-0.60 per training run**

**Monthly Budget Example**:
- 50 experiments/month
- $0.50 average per run
- **Total: $25/month**

## Monitoring

Add monitoring to your script:

```python
import wandb

wandb.init(
    project="modal-t4-training",
    config={
        "gpu": "T4",
        "model": model_name,
        "batch_size": 16,
    }
)

training_args = TrainingArguments(
    # ... other args ...
    report_to="wandb",
)
```

## Troubleshooting

### Out of Memory

**Error**: `CUDA out of memory`

**Solutions**:
1. Reduce batch size: `per_device_train_batch_size=8`
2. Enable gradient checkpointing: `gradient_checkpointing=True`
3. Reduce sequence length: `max_length=128`
4. Use gradient accumulation instead of larger batch

### Slow Training

**Issue**: Training takes too long

**Solutions**:
1. Enable mixed precision: `fp16=True`
2. Use smaller dataset subset for experimentation
3. Reduce logging frequency: `logging_steps=500`
4. Consider upgrading to L4 or A10

### GPU Not Detected

**Error**: `torch.cuda.is_available() = False`

**Solutions**:
1. Verify GPU parameter: `gpu="T4"`
2. Check Modal quota limits
3. Install correct PyTorch version with CUDA support

## When to Upgrade from T4

Consider upgrading to **L4** ($0.40-0.60/hr) or **A10** ($0.60-0.80/hr) if:
- Training takes >4 hours (cost-inefficient)
- Models don't fit in 16GB VRAM
- Need faster iteration for experimentation
- Working with larger models (>500M parameters)

## Example Output

```
GPU: Tesla T4
VRAM: 15.75 GB
Loading dataset: imdb
Loading model: bert-base-uncased
Tokenizing dataset...
Starting training...

Epoch 1/3
Train Loss: 0.342
Eval Loss: 0.287
Eval Accuracy: 0.891

Epoch 2/3
Train Loss: 0.198
Eval Loss: 0.251
Eval Accuracy: 0.912

Epoch 3/3
Train Loss: 0.134
Eval Loss: 0.243
Eval Accuracy: 0.918

Training complete!
Model saved to /checkpoints/final_model
```

## Resources

- Modal GPU docs: https://modal.com/docs/guide/gpu
- T4 specs: https://www.nvidia.com/en-us/data-center/tesla-t4/
- Modal pricing: https://modal.com/pricing
- Example code: https://github.com/modal-labs/modal-examples

## Next Steps

1. **Experiment**: Try different models and hyperparameters
2. **Scale**: Move to A10 or A100 for larger models
3. **Deploy**: Use Modal for inference serving
4. **Monitor**: Track experiments with Weights & Biases
