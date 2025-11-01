# Lambda Labs A100 GPU Setup Example

Standard production-grade ML training setup using Lambda Labs A100 GPUs. Ideal for serious model training, fine-tuning, and research.

## Overview

**GPU**: NVIDIA A100 (80GB)
**VRAM**: 80GB
**Cost**: ~$1.29/hr (single GPU), ~$10.32/hr (8x GPU)
**Best For**:
- Large model training (LLaMA, GPT, T5)
- Fine-tuning billion-parameter models
- Production training pipelines
- Research and development

## Prerequisites

1. Lambda Labs account: https://cloud.lambdalabs.com
2. SSH key generated: `ssh-keygen -t rsa -b 4096`
3. Lambda API key: https://cloud.lambdalabs.com/api-keys

## Setup Steps

### 1. Install Lambda CLI

```bash
pip install lambda-cloud
```

### 2. Configure API Key

```bash
mkdir -p ~/.lambda_cloud
echo "YOUR_API_KEY" > ~/.lambda_cloud/lambda_keys
```

### 3. Check Instance Availability

```bash
lambda instance-types
```

Look for `gpu_1x_a100` (80GB) availability.

### 4. Upload SSH Key

```bash
lambda ssh-key add my-training-key ~/.ssh/id_rsa.pub
```

### 5. Launch Instance

```bash
lambda instance launch \
  --instance-type gpu_1x_a100 \
  --ssh-key-name my-training-key \
  --file-system-size 1024 \
  --name llama-training
```

**Response**:
```
Instance launched: i-abc123xyz
IP Address: 104.123.45.67
Status: booting
```

Wait 2-3 minutes for instance to be ready.

### 6. Connect to Instance

```bash
ssh ubuntu@104.123.45.67
```

### 7. Setup Environment

Create `setup.sh` on the instance:

```bash
#!/bin/bash
set -e

echo "=== Lambda Labs A100 Setup ==="

# Verify GPU
nvidia-smi

# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Install dependencies
sudo apt-get install -y git wget curl vim htop tmux

# Setup Python environment
python3 -m venv ~/venv
source ~/venv/bin/activate

# Install PyTorch with CUDA 12.1
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# Install ML frameworks
pip install transformers accelerate datasets evaluate peft bitsandbytes

# Install training utilities
pip install wandb tensorboard deepspeed

# Install development tools
pip install jupyter ipython ipywidgets

echo "Setup complete!"
```

Run setup:

```bash
bash setup.sh
source ~/venv/bin/activate
```

### 8. Create Training Script

Create `train_llama.py`:

```python
"""
Fine-tune LLaMA on Lambda Labs A100
Demonstrates full A100 80GB capabilities
"""

import torch
from transformers import (
    AutoModelForCausalLM,
    AutoTokenizer,
    TrainingArguments,
    Trainer,
    DataCollatorForLanguageModeling,
)
from datasets import load_dataset
from peft import LoraConfig, get_peft_model, prepare_model_for_kbit_training
import wandb

def main():
    # Initialize W&B
    wandb.init(
        project="lambda-a100-llama",
        config={
            "model": "meta-llama/Llama-2-7b-hf",
            "gpu": "A100-80GB",
            "method": "LoRA",
        }
    )

    print("=== Lambda Labs A100 Training ===")
    print(f"GPU: {torch.cuda.get_device_name(0)}")
    print(f"VRAM: {torch.cuda.get_device_properties(0).total_memory / 1e9:.2f} GB")

    # Load model (full precision on A100)
    model_name = "meta-llama/Llama-2-7b-hf"
    print(f"Loading {model_name}...")

    model = AutoModelForCausalLM.from_pretrained(
        model_name,
        torch_dtype=torch.bfloat16,  # A100 supports BF16
        device_map="auto",
        use_cache=False,
    )

    tokenizer = AutoTokenizer.from_pretrained(model_name)
    tokenizer.pad_token = tokenizer.eos_token

    # Configure LoRA
    lora_config = LoraConfig(
        r=16,
        lora_alpha=32,
        target_modules=["q_proj", "v_proj"],
        lora_dropout=0.05,
        bias="none",
        task_type="CAUSAL_LM",
    )

    model = get_peft_model(model, lora_config)
    model.print_trainable_parameters()

    # Load dataset
    print("Loading dataset...")
    dataset = load_dataset("tatsu-lab/alpaca", split="train[:10000]")

    # Tokenize
    def tokenize_function(examples):
        return tokenizer(
            examples["text"],
            truncation=True,
            max_length=512,
            padding="max_length",
        )

    tokenized_dataset = dataset.map(
        tokenize_function,
        batched=True,
        remove_columns=dataset.column_names,
    )

    # Data collator
    data_collator = DataCollatorForLanguageModeling(
        tokenizer=tokenizer,
        mlm=False,
    )

    # Training arguments optimized for A100
    training_args = TrainingArguments(
        output_dir="./checkpoints",
        num_train_epochs=3,
        per_device_train_batch_size=4,  # A100 can handle larger
        gradient_accumulation_steps=4,   # Effective batch size: 16
        learning_rate=2e-4,
        warmup_steps=100,
        logging_steps=10,
        save_steps=500,
        save_total_limit=3,
        fp16=False,                      # Use BF16 on A100
        bf16=True,
        optim="adamw_torch",
        gradient_checkpointing=True,
        report_to="wandb",
        load_best_model_at_end=True,
        evaluation_strategy="steps",
        eval_steps=500,
    )

    # Create trainer
    trainer = Trainer(
        model=model,
        args=training_args,
        train_dataset=tokenized_dataset,
        data_collator=data_collator,
    )

    # Train
    print("Starting training...")
    trainer.train()

    # Save
    print("Saving model...")
    model.save_pretrained("./final_model")
    tokenizer.save_pretrained("./final_model")

    print("Training complete!")

if __name__ == "__main__":
    main()
```

### 9. Run Training

```bash
python train_llama.py
```

## A100 Optimization Tips

### 1. Use BFloat16 (BF16)

A100 has native BF16 support (faster than FP16):

```python
training_args = TrainingArguments(
    # ... other args ...
    fp16=False,
    bf16=True,  # Use BF16 on A100
)
```

### 2. Optimal Batch Sizes

**80GB A100 can handle**:
- LLaMA-7B: Batch size 8-16 (with LoRA)
- LLaMA-13B: Batch size 4-8 (with LoRA)
- LLaMA-30B: Batch size 1-2 (with LoRA + gradient checkpointing)
- BERT-large: Batch size 64-128
- T5-3B: Batch size 8-16

### 3. Memory Optimization

```python
# For very large models
model = AutoModelForCausalLM.from_pretrained(
    model_name,
    load_in_8bit=True,           # 8-bit quantization
    device_map="auto",
    torch_dtype=torch.bfloat16,
)

model = prepare_model_for_kbit_training(model)  # Prepare for LoRA
```

### 4. Distributed Training (8x A100)

For multi-GPU training, use DeepSpeed:

```python
# deepspeed_config.json
{
  "train_batch_size": 64,
  "gradient_accumulation_steps": 4,
  "fp16": {
    "enabled": false
  },
  "bf16": {
    "enabled": true
  },
  "zero_optimization": {
    "stage": 2
  }
}
```

Launch with:

```bash
deepspeed --num_gpus=8 train_llama.py \
  --deepspeed deepspeed_config.json
```

## Cost Management

### Instance Costs

**Single A100-80GB**: $1.29/hr
- 1 hour: $1.29
- 8 hours: $10.32
- 24 hours: $30.96

**8x A100-80GB**: $10.32/hr
- 1 hour: $10.32
- 8 hours: $82.56
- 24 hours: $247.68

### Cost Optimization

1. **Use persistent storage** ($0.20/GB/month)
   - Store datasets and checkpoints
   - Avoid re-downloading on each run

2. **Terminate when idle**
   ```bash
   # Add to training script
   lambda instance terminate $(lambda instance list --format json | jq -r '.[0].id')
   ```

3. **Use smaller models for development**
   - Test on T4/A10 first
   - Scale to A100 for final training

4. **Monitor utilization**
   ```bash
   watch -n 1 nvidia-smi
   ```
   Aim for >80% GPU utilization

## Persistent Storage Setup

Create and mount persistent storage:

```bash
# Create volume (one-time)
lambda instance attach-volume \
  --instance-id i-abc123xyz \
  --volume-size 1024 \
  --mount-path /mnt/persistent
```

Store datasets and checkpoints:

```python
training_args = TrainingArguments(
    output_dir="/mnt/persistent/checkpoints",
    logging_dir="/mnt/persistent/logs",
    # ... other args ...
)
```

## Monitoring

### GPU Monitoring

```bash
# Real-time monitoring
watch -n 1 nvidia-smi

# Log to file
nvidia-smi dmon -s pucvmet -c 1000 > gpu_stats.log
```

### Training Monitoring

Use Weights & Biases:

```python
import wandb

wandb.init(project="lambda-a100")
```

View at: https://wandb.ai

### Cost Tracking

```bash
# Check current costs
lambda instance list --format json | jq '.[] | {id, status, cost_per_hour}'
```

## Troubleshooting

### Out of Memory (Even on 80GB)

**Solutions**:
1. Enable gradient checkpointing
2. Reduce batch size
3. Use 8-bit quantization
4. Use LoRA instead of full fine-tuning
5. Reduce sequence length

### Connection Timeout

**Issue**: SSH connection lost

**Solutions**:
1. Use `tmux` or `screen` for persistent sessions
   ```bash
   tmux new -s training
   python train_llama.py
   # Detach: Ctrl+b, then d
   # Reattach: tmux attach -t training
   ```

2. Enable SSH keepalive:
   ```bash
   # ~/.ssh/config
   Host *.lambdalabs.com
       ServerAliveInterval 60
       ServerAliveCountMax 3
   ```

### Slow Data Loading

**Issue**: GPU underutilized due to slow data loading

**Solutions**:
1. Increase data loader workers:
   ```python
   training_args = TrainingArguments(
       dataloader_num_workers=8,
       # ... other args ...
   )
   ```

2. Pre-process and cache dataset:
   ```python
   dataset = dataset.map(tokenize, batched=True)
   dataset.save_to_disk("/mnt/persistent/processed_dataset")
   ```

## Example Training Run

```
=== Lambda Labs A100 Training ===
GPU: NVIDIA A100-SXM4-80GB
VRAM: 80.00 GB

Loading meta-llama/Llama-2-7b-hf...
trainable params: 4,194,304 || all params: 6,742,609,920 || trainable%: 0.0622

Loading dataset...
Dataset loaded: 10,000 samples

Starting training...

Epoch 1/3 | Step 100 | Loss: 2.345 | GPU: 85% | VRAM: 45/80 GB
Epoch 1/3 | Step 200 | Loss: 1.987 | GPU: 87% | VRAM: 45/80 GB
...

Training complete!
Total time: 2h 15m
Total cost: $2.90
```

## When to Use 8x A100

Consider 8x A100 instances for:
- Models >30B parameters
- Distributed training experiments
- Large batch size requirements
- Time-critical training (faster completion)

**Cost comparison**:
- 1x A100 for 24 hours: $30.96
- 8x A100 for 3 hours: $30.96 (8x faster)

If 8x speedup achieved, cost is same but time is 8x less.

## Cleanup

Don't forget to terminate instance:

```bash
# List instances
lambda instance list

# Terminate
lambda instance terminate i-abc123xyz
```

## Resources

- Lambda Labs docs: https://docs.lambda.ai/cloud
- A100 specs: https://www.nvidia.com/en-us/data-center/a100/
- DeepSpeed: https://www.deepspeed.ai/
- PEFT/LoRA: https://github.com/huggingface/peft

## Next Steps

1. **Experiment**: Try different models and techniques
2. **Scale**: Use 8x A100 for larger models
3. **Optimize**: Profile and optimize training pipeline
4. **Deploy**: Export model for inference
