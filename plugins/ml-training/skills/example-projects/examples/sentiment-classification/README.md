# Sentiment Classification Example

Binary sentiment analysis using fine-tuned DistilBERT.

## Overview

This example demonstrates how to:
- Fine-tune DistilBERT for sentiment classification
- Train on custom JSON data
- Evaluate with validation metrics
- Run inference locally and via API
- Deploy to production

## Quick Start

### 1. Setup

```bash
# Install dependencies
pip install -r requirements.txt
```

### 2. Train Model

```bash
# Basic training
python train.py

# Custom configuration
python train.py --epochs 5 --batch-size 16 --learning-rate 3e-5
```

**Training output:**
- Model checkpoints: `models/sentiment-classifier/`
- Validation metrics: accuracy, precision, recall, F1

**Expected results:**
- Training time: 5-10 minutes (with GPU)
- Validation accuracy: >90% on provided data

### 3. Run Inference

```bash
# Single prediction
python inference.py --text "This is amazing!"

# Interactive mode
python inference.py --interactive

# Demo mode (default)
python inference.py

# API server
python inference.py --server --port 8000
```

## Dataset Format

Training data is in `data.json`:

```json
[
  {"text": "This movie was amazing!", "label": 1},
  {"text": "Terrible waste of time", "label": 0}
]
```

**Labels:**
- `0` = Negative sentiment
- `1` = Positive sentiment

**Provided dataset:**
- 50 labeled examples
- Balanced classes (25 positive, 25 negative)
- Diverse domains (movies, products, services, books, hotels)

## Custom Data

### Prepare Your Data

1. Create JSON file with same format:

```python
import json

data = [
    {"text": "Your text here", "label": 1},
    {"text": "Another example", "label": 0},
    # ... more examples
]

with open("my_data.json", "w") as f:
    json.dump(data, f, indent=2)
```

2. Train with custom data:

```bash
python train.py --data my_data.json
```

### Data Requirements

- **Minimum:** 100+ examples (more is better)
- **Balance:** Similar number of positive/negative samples
- **Quality:** Clear, consistent labeling
- **Length:** Works best with 10-500 words per text

## Model Architecture

**Base Model:** DistilBERT (distilbert-base-uncased)
- Parameters: 66M
- Speed: 2x faster than BERT
- Accuracy: ~97% of BERT performance

**Fine-tuning:**
- Classification head: 2 classes (negative/positive)
- Optimizer: AdamW
- Scheduler: Linear warmup
- Regularization: Gradient clipping

## Training Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--epochs` | 3 | Number of training epochs |
| `--batch-size` | 8 | Training batch size |
| `--learning-rate` | 2e-5 | Learning rate |
| `--device` | auto | Device (cuda/cpu) |
| `--data` | data.json | Training data path |
| `--output-dir` | models/sentiment-classifier | Output directory |

## Inference Options

### Command Line

```bash
# Single text
python inference.py --text "Your text here"

# Custom model path
python inference.py --model-path path/to/model --text "Text"
```

### Interactive Mode

```bash
python inference.py --interactive
```

Allows continuous predictions without reloading model.

### API Server

```bash
python inference.py --server --port 8000
```

**Endpoints:**
- `POST /predict` - Classify text
- `GET /health` - Health check

**Example request:**
```bash
curl -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -d '{"text": "This is great!"}'
```

**Response:**
```json
{
  "sentiment": "Positive",
  "confidence": 0.9847,
  "probabilities": {
    "negative": 0.0153,
    "positive": 0.9847
  }
}
```

## Production Deployment

### Option 1: Modal (Recommended)

```bash
# Install Modal
pip install modal

# Deploy
modal deploy modal_deploy.py
```

Creates serverless API endpoint with:
- Auto-scaling
- GPU support
- Pay-per-use pricing

### Option 2: Docker

```bash
# Build image
docker build -t sentiment-classifier .

# Run container
docker run -p 8000:8000 sentiment-classifier
```

### Option 3: Local FastAPI

```bash
# Production server
uvicorn inference:app --host 0.0.0.0 --port 8000 --workers 4
```

## Performance

**Training:**
- Time: ~5-10 minutes (GPU) / ~30-60 minutes (CPU)
- Memory: ~2GB GPU / ~4GB RAM
- Dataset: 50 samples → 90%+ accuracy

**Inference:**
- Latency: ~10-50ms (GPU) / ~100-300ms (CPU)
- Throughput: ~100-500 predictions/sec
- Memory: ~500MB

## Troubleshooting

### Out of Memory

Reduce batch size:
```bash
python train.py --batch-size 4
```

### Low Accuracy

1. **More data:** Add more training examples
2. **More epochs:** Train longer (--epochs 5)
3. **Better data:** Improve label quality
4. **Different model:** Try bert-base-uncased

### CUDA Errors

Force CPU:
```bash
python train.py --device cpu
```

### Import Errors

Reinstall dependencies:
```bash
pip install -r requirements.txt --upgrade
```

## Customization

### Change Model

```python
# In train.py, change model_name
python train.py --model-name bert-base-uncased
# or: roberta-base, albert-base-v2, etc.
```

### Multi-class Classification

Modify for 3+ classes:

```python
# Update data.json
{"text": "...", "label": 0}  # Class 0
{"text": "...", "label": 1}  # Class 1
{"text": "...", "label": 2}  # Class 2

# In train.py, update num_labels
model = AutoModelForSequenceClassification.from_pretrained(
    model_name,
    num_labels=3  # Change this
)
```

### Add Validation Split

Already implemented! Training automatically:
- Splits data 80/20 (train/val)
- Stratified split (preserves class balance)
- Evaluates every epoch

## Next Steps

1. **Collect more data** - Improve accuracy with larger dataset
2. **Try different models** - Experiment with BERT, RoBERTa, etc.
3. **Deploy to production** - Use Modal or Docker
4. **Add monitoring** - Track prediction distribution
5. **A/B testing** - Compare model versions

## Resources

- **Transformers Docs:** https://huggingface.co/docs/transformers
- **DistilBERT Paper:** https://arxiv.org/abs/1910.01108
- **Fine-tuning Guide:** https://huggingface.co/course/chapter3

## License

MIT - Feel free to use for any purpose
