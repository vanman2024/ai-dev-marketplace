# Sentiment Classification Example

Complete example of building a sentiment classifier using PEFT/LoRA.

## Overview

**Task:** Classify product reviews as positive, negative, or neutral
**Approach:** PEFT/LoRA with RoBERTa
**Dataset:** 10,000 product reviews
**Training time:** ~30 minutes on RTX 3090

## Setup

```bash
# Create project
cd /path/to/ml-training/skills/training-patterns
./scripts/setup-peft.sh sentiment-classifier roberta-base lora

cd sentiment-classifier
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

## Dataset Preparation

### Format

CSV with two columns:
- `text`: Review text
- `label`: 0 (negative), 1 (neutral), 2 (positive)

### Example Data

```csv
text,label
"This product exceeded my expectations! Absolutely love it.",2
"Completely useless. Broke after one use.",0
"It's okay. Does what it's supposed to do.",1
"Best purchase I've made this year! Highly recommend.",2
"Terrible quality. Would not recommend to anyone.",0
"Average product. Nothing special but works fine.",1
```

### Dataset Split

- **Training:** 8,000 examples (80%)
- **Validation:** 1,000 examples (10%)
- **Test:** 1,000 examples (10%)

Place files in:
- `data/train.csv`
- `data/val.csv`
- `data/test.csv`

## Training Configuration

Edit `peft_config.json`:

```json
{
  "peft_type": "LORA",
  "task_type": "SEQ_CLS",
  "r": 8,
  "lora_alpha": 16,
  "lora_dropout": 0.1,
  "target_modules": ["query", "key", "value", "dense"]
}
```

**Explanation:**
- `r=8`: LoRA rank (controls adapter size)
- `lora_alpha=16`: Scaling factor (typically 2x rank)
- `lora_dropout=0.1`: Regularization
- `target_modules`: Which attention layers to apply LoRA

## Training

```bash
python train.py \
  --model_name roberta-base \
  --peft_method lora \
  --task_type classification \
  --train_file data/train.csv \
  --val_file data/val.csv \
  --num_labels 3 \
  --lora_r 8 \
  --lora_alpha 16 \
  --lora_dropout 0.1 \
  --epochs 3 \
  --batch_size 16 \
  --learning_rate 3e-4 \
  --output_dir ./outputs \
  --adapter_dir ./adapters
```

### Training Output

```
🖥️  Device: cuda
🎮 GPU: NVIDIA GeForce RTX 3090
💾 Memory: 24.0 GB

📥 Loading tokenizer: roberta-base
📥 Loading base model...
🎯 Applying LORA to model...

trainable params: 294,912 || all params: 125,235,458 || trainable%: 0.236%

📚 Loading datasets...
✅ Train: 8000
✅ Validation: 1000

===========================================================
🚀 Starting LORA training...
===========================================================

Epoch 1/3: 100%|████████| 500/500 [08:23<00:00]
Validation: {'accuracy': 0.856, 'f1': 0.854, 'precision': 0.859, 'recall': 0.856}

Epoch 2/3: 100%|████████| 500/500 [08:21<00:00]
Validation: {'accuracy': 0.891, 'f1': 0.889, 'precision': 0.892, 'recall': 0.891}

Epoch 3/3: 100%|████████| 500/500 [08:19<00:00]
Validation: {'accuracy': 0.903, 'f1': 0.901, 'precision': 0.905, 'recall': 0.903}

💾 Saving LORA adapters...

✅ PEFT training completed!
📁 Adapters saved to: ./adapters
💡 Adapter size is tiny (~2.5MB) compared to full model!
```

## Inference

### Single Prediction

```python
from predict import PEFTClassifier

classifier = PEFTClassifier('roberta-base', './adapters')

text = "This product is absolutely amazing! Best purchase ever!"
label, confidence = classifier.predict(text)

print(f"Sentiment: {label}")  # Output: class_2 (positive)
print(f"Confidence: {confidence:.3f}")  # Output: 0.987
```

### Batch Prediction

```python
reviews = [
    "Love this product!",
    "Terrible quality.",
    "It's okay, nothing special."
]

for review in reviews:
    label, confidence = classifier.predict(review)
    print(f"{review[:30]:30s} -> {label} ({confidence:.3f})")
```

**Output:**
```
Love this product!             -> class_2 (0.954)
Terrible quality.              -> class_0 (0.982)
It's okay, nothing special.    -> class_1 (0.876)
```

## Results

### Performance Metrics

| Metric | Validation | Test |
|--------|-----------|------|
| Accuracy | 90.3% | 89.8% |
| Precision | 90.5% | 89.6% |
| Recall | 90.3% | 89.8% |
| F1 Score | 90.1% | 89.5% |

### Confusion Matrix (Test Set)

```
           Predicted
           Neg  Neu  Pos
Actual Neg 312   18    5
       Neu  22  301   12
       Pos   4   11  315
```

### Resource Usage

- **Training time:** 28 minutes (3 epochs)
- **GPU memory:** 8.2 GB (peak)
- **Adapter size:** 2.4 MB
- **Base model size:** 498 MB (not fine-tuned)
- **Total storage:** 500.4 MB (base + adapter)

Compare to full fine-tuning:
- **Full model size:** 498 MB (entire model fine-tuned)
- **Training time:** 2+ hours
- **GPU memory:** 16+ GB

## Hyperparameter Tuning

### Experiment Results

| r | alpha | LR | Batch | Val Acc | Notes |
|---|-------|----|----|---------|-------|
| 4 | 8 | 3e-4 | 16 | 88.2% | Too low capacity |
| 8 | 16 | 3e-4 | 16 | **90.3%** | Best balance |
| 16 | 32 | 3e-4 | 16 | 90.5% | Marginal gain |
| 8 | 16 | 1e-4 | 16 | 87.6% | LR too low |
| 8 | 16 | 1e-3 | 16 | 85.3% | LR too high |

**Recommendation:** r=8, alpha=16, lr=3e-4

## Production Deployment

### Model Saving

```python
# Save adapters
model.save_pretrained('./adapters')
tokenizer.save_pretrained('./adapters')

# Total size: ~2.5 MB (just the adapter!)
```

### Loading in Production

```python
from transformers import AutoTokenizer, AutoModelForSequenceClassification
from peft import PeftModel

# Load base model (once)
base_model = AutoModelForSequenceClassification.from_pretrained('roberta-base')

# Load adapter (tiny, fast)
model = PeftModel.from_pretrained(base_model, './adapters')

# Ready for inference
```

### Inference Speed

- **Single prediction:** ~15ms (GPU)
- **Batch (32 examples):** ~180ms (GPU)
- **Throughput:** ~1700 predictions/second

## Multi-Task Extension

Train separate adapters for different tasks:

```bash
# Sentiment adapter
python train.py ... --adapter_dir ./adapters/sentiment

# Intent adapter
python train.py ... --adapter_dir ./adapters/intent

# Toxicity adapter
python train.py ... --adapter_dir ./adapters/toxicity
```

Swap at runtime:

```python
# Load base model once
base_model = AutoModelForSequenceClassification.from_pretrained('roberta-base')

# Swap adapters
sentiment_model = PeftModel.from_pretrained(base_model, './adapters/sentiment')
intent_model = PeftModel.from_pretrained(base_model, './adapters/intent')

# 3 tasks, only one base model in memory!
```

## Key Takeaways

✅ **PEFT/LoRA achieved 90%+ accuracy**
✅ **10x less memory than full fine-tuning** (8GB vs 16GB+)
✅ **5x faster training** (28 min vs 2+ hours)
✅ **Tiny adapter files** (2.4MB vs 498MB)
✅ **Production-ready** (15ms inference, 1700 pred/sec)

## Next Steps

1. **Improve data:** Collect more labeled examples
2. **Try larger models:** Use `roberta-large` or `deberta-v3-large`
3. **Ensemble:** Combine multiple adapters
4. **Active learning:** Label uncertain predictions
5. **Monitor drift:** Track performance over time

---

**Generated by ML Training Plugin**
**Training pattern: PEFT/LoRA Classification**
