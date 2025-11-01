# Text Generation Example

Fine-tune GPT-2 for custom text generation using LoRA (Low-Rank Adaptation).

## Overview

This example demonstrates:
- GPT-2 fine-tuning with PEFT/LoRA
- Parameter-efficient training (train <1% of parameters)
- Custom text generation
- Configuration management with YAML
- Interactive and batch generation

## Quick Start

### 1. Setup

```bash
pip install -r requirements.txt
```

### 2. Train Model

```bash
# Train with default config
python train.py

# Custom config
python train.py --config my_config.yaml

# Custom data
python train.py --data my_training_data.txt
```

**Training output:**
- LoRA adapters: `models/text-generator/`
- Training config: `models/text-generator/training_config.yaml`
- Validation metrics logged during training

**Expected results:**
- Training time: 15-30 minutes (with GPU)
- Reduced memory usage vs full fine-tuning
- Good quality generation after 3 epochs

### 3. Generate Text

```bash
# Single generation
python generate.py --prompt "The future of AI is"

# Interactive mode
python generate.py --interactive

# Demo mode
python generate.py

# Multiple sequences
python generate.py --prompt "Once upon a time" --num-sequences 3
```

## Configuration

All training parameters in `config.yaml`:

```yaml
model:
  name: gpt2                # Base model
  max_length: 512           # Max sequence length

training:
  epochs: 3                 # Training epochs
  batch_size: 4             # Batch size
  learning_rate: 2e-4       # Learning rate
  warmup_steps: 100         # LR warmup steps

lora:
  r: 8                      # LoRA rank (lower = fewer params)
  alpha: 16                 # LoRA scaling factor
  dropout: 0.1              # Dropout rate
  target_modules:           # Modules to apply LoRA
    - c_attn

generation:
  temperature: 0.8          # Sampling temperature
  top_p: 0.9                # Nucleus sampling
  top_k: 50                 # Top-k sampling
  max_length: 200           # Max generation length
```

## Training Data Format

### Text File (Recommended)

Separate examples with double newlines:

```
Example text 1 goes here.
This can be multiple sentences.

Example text 2 starts here.
Another paragraph of text.

Example text 3...
```

Save as `training_data.txt`

### JSON File

```json
[
  "First training example text",
  "Second training example text",
  "Third training example text"
]
```

Or with structure:

```json
[
  {"text": "Example 1"},
  {"text": "Example 2"}
]
```

### HuggingFace Dataset

Use dataset name directly:

```bash
python train.py --data "wikitext-2-raw-v1"
```

## LoRA Explained

**Problem:** Fine-tuning large models requires updating billions of parameters.

**Solution:** LoRA injects trainable low-rank matrices into model layers, training only 0.1-1% of parameters.

**Benefits:**
- 💾 **Lower memory:** ~1/10th of full fine-tuning
- ⚡ **Faster training:** Fewer parameters to update
- 💰 **Cheaper:** Run on smaller GPUs
- 🔄 **Modularity:** Swap LoRA adapters on same base model

**Trade-off:** Slightly lower quality than full fine-tuning for some tasks.

## Model Sizes

| Model | Parameters | Memory (FP16) | Speed | Quality |
|-------|-----------|---------------|-------|---------|
| GPT-2 | 124M | ~500MB | Fast | Good |
| GPT-2 Medium | 355M | ~1.5GB | Medium | Better |
| GPT-2 Large | 774M | ~3GB | Slower | Great |
| GPT-2 XL | 1.5B | ~6GB | Slow | Best |

**Change model in config.yaml:**
```yaml
model:
  name: gpt2-medium  # or gpt2-large, gpt2-xl
```

## Generation Parameters

### Temperature (0.0 - 2.0)

- **0.0:** Deterministic (always same output)
- **0.5:** Conservative, coherent
- **0.8:** Balanced (default)
- **1.2:** Creative, diverse
- **2.0:** Very random

### Top-p (Nucleus Sampling)

- **0.9:** Use top 90% probability mass (default)
- **0.95:** More diverse
- **0.8:** More focused

### Top-k

- **50:** Consider top 50 tokens (default)
- **40:** More focused
- **100:** More diverse

### Examples

```bash
# Conservative, coherent generation
python generate.py --prompt "..." --temperature 0.5 --top-p 0.8

# Creative, diverse generation
python generate.py --prompt "..." --temperature 1.2 --top-p 0.95

# Deterministic (same every time)
python generate.py --prompt "..." --temperature 0
```

## Custom Training Data

### Prepare Your Data

1. **Collect text examples** (100+ recommended)
2. **Format as text file** with double-newline separators
3. **Ensure consistent style** (same domain/tone)
4. **Save as .txt file**

Example:

```python
# create_training_data.py
examples = [
    "Your first text example here...",
    "Second example...",
    # ... more examples
]

with open("my_data.txt", "w") as f:
    f.write("\n\n".join(examples))
```

### Train on Custom Data

```bash
python train.py --data my_data.txt
```

## Advanced Usage

### Adjust LoRA Rank

Higher rank = more parameters = better quality but slower:

```yaml
lora:
  r: 16  # Increase from 8
  alpha: 32  # Generally 2x rank
```

### Multi-GPU Training

Automatically uses all available GPUs. Control with:

```bash
CUDA_VISIBLE_DEVICES=0,1 python train.py
```

### Mixed Precision Training

Enabled by default on GPU. Disable in config:

```yaml
training:
  fp16: false
```

### Gradient Checkpointing

Reduce memory usage:

```yaml
training:
  gradient_checkpointing: true
```

## Production Deployment

### Option 1: Modal (Serverless)

```python
# modal_deploy.py
import modal

stub = modal.Stub("text-generator")

@stub.function(
    gpu="T4",
    image=modal.Image.debian_slim().pip_install(
        "torch", "transformers", "peft"
    )
)
def generate(prompt: str):
    from transformers import AutoModelForCausalLM, AutoTokenizer
    from peft import PeftModel

    # Load model and generate
    # ... implementation

    return generated_text

@stub.local_entrypoint()
def main():
    result = generate.remote("The future of AI")
    print(result)
```

Deploy:
```bash
modal deploy modal_deploy.py
```

### Option 2: FastAPI Server

```python
# server.py
from fastapi import FastAPI
from generate import load_model, generate_text

app = FastAPI()
model, tokenizer, device = load_model("models/text-generator")

@app.post("/generate")
def api_generate(prompt: str, max_length: int = 200):
    return {
        "generated": generate_text(
            prompt, model, tokenizer, device,
            max_length=max_length
        )
    }
```

Run:
```bash
uvicorn server:app --host 0.0.0.0 --port 8000
```

## Performance Tips

### Faster Training

1. **Reduce batch size** if out of memory
2. **Enable gradient checkpointing** to save memory
3. **Use smaller max_length** (256 instead of 512)
4. **Fewer training examples** for quick experiments

### Better Quality

1. **More training data** (100+ examples minimum)
2. **Higher LoRA rank** (r=16 instead of 8)
3. **More epochs** (5-10 instead of 3)
4. **Larger base model** (gpt2-medium instead of gpt2)
5. **Lower learning rate** (1e-4 instead of 2e-4)

## Troubleshooting

### Out of Memory

```yaml
# Reduce these values
training:
  batch_size: 2  # Lower
  gradient_checkpointing: true  # Enable

model:
  max_length: 256  # Lower
```

### Poor Generation Quality

1. **More training data** - Need 100+ examples
2. **More epochs** - Try 5-10 epochs
3. **Better data quality** - Ensure consistent style
4. **Adjust temperature** - Try 0.7-1.0 range

### Slow Training

1. **Use GPU** - 10-50x faster than CPU
2. **Smaller model** - Use gpt2 instead of larger
3. **Reduce max_length** - 256 instead of 512
4. **Fewer examples** - For testing

### Import Errors

```bash
pip install -r requirements.txt --upgrade
```

## Example Use Cases

### 1. Story Generation

Train on stories, generate continuations:
```bash
python generate.py --prompt "Once upon a time in a magical forest"
```

### 2. Code Generation

Train on code snippets:
```bash
python generate.py --prompt "def fibonacci(n):"
```

### 3. Product Descriptions

Train on product copy:
```bash
python generate.py --prompt "This innovative product features"
```

### 4. Email Drafting

Train on email templates:
```bash
python generate.py --prompt "Dear valued customer,"
```

## Next Steps

1. **Collect domain-specific data** for your use case
2. **Experiment with hyperparameters** (LoRA rank, learning rate)
3. **Try different base models** (GPT-2 medium/large)
4. **Deploy to production** (Modal or FastAPI)
5. **Fine-tune generation params** for quality vs diversity

## Resources

- **PEFT Docs:** https://huggingface.co/docs/peft
- **LoRA Paper:** https://arxiv.org/abs/2106.09685
- **GPT-2 Paper:** https://d4mucfpksywv.cloudfront.net/better-language-models/language_models_are_unsupervised_multitask_learners.pdf
- **Transformers Docs:** https://huggingface.co/docs/transformers

## License

MIT - Free to use for any purpose
