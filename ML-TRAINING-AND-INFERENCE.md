# Machine Learning Training & Inference at Scale

> **Generated**: November 1, 2025
> **Purpose**: Complete ML pipeline for training custom models and deploying them in production applications at affordable prices
> **Integration**: Works with all existing AI Dev Marketplace plugins (FastAPI, Next.js, Supabase, Vercel AI SDK, etc.)

---

## 📚 **Table of Contents**

1. [Overview: RAG vs ML Training](#overview-rag-vs-ml-training)
2. [Training Frameworks](#training-frameworks)
3. [Affordable GPU Cloud Platforms](#affordable-gpu-cloud-platforms)
4. [Model Training Pipeline](#model-training-pipeline)
5. [Model Deployment & Inference](#model-deployment--inference)
6. [Integration with Existing Stack](#integration-with-existing-stack)
7. [ML Algorithms & Use Cases](#ml-algorithms--use-cases)
8. [Cost Optimization Strategies](#cost-optimization-strategies)
9. [Complete Code Examples](#complete-code-examples)

---

## 🎯 **Overview: RAG vs ML Training**

### What's the Difference?

| Feature           | RAG (Retrieval)                                    | ML Training                                                 |
| ----------------- | -------------------------------------------------- | ----------------------------------------------------------- |
| **Purpose**       | Retrieve relevant information from knowledge bases | Train custom models on your specific data                   |
| **Use Case**      | Q&A, chatbots, document search                     | Classification, prediction, generation with custom behavior |
| **Cost**          | Low ($0-$25/month)                                 | Variable ($0.31-$4.40/hr for training)                      |
| **Time**          | Instant queries                                    | Training time varies (minutes to hours)                     |
| **Customization** | Limited to retrieval                               | Full control over model behavior                            |
| **Integration**   | Read-only knowledge                                | Learns patterns from your data                              |

### When to Use What?

- **Use RAG**: Document search, Q&A on existing content, chatbots with knowledge bases
- **Use ML Training**:
  - Custom classification (sentiment analysis, categorization)
  - Custom generation (assessment creation, content generation)
  - Predictive models (recommendations, scoring)
  - Fine-tuning for domain-specific behavior
  - Model personalization

### Combined Approach

**RAG + ML Training** = Most Powerful

1. Train custom models on your domain data
2. Use RAG to retrieve relevant context
3. Feed both to your trained model for optimal results

---

## 🧠 **Training Frameworks**

### HuggingFace Ecosystem (⭐ RECOMMENDED)

#### Core Libraries

**🤗 Transformers** - `/huggingface/transformers` (Context7)

- **Purpose**: State-of-the-art pre-trained models for NLP, vision, audio
- **Docs**: https://huggingface.co/docs/transformers
- **Training Guide**: https://huggingface.co/docs/transformers/training
- **Fine-tuning Tutorial**: https://huggingface.co/docs/transformers/main_classes/trainer
- **GitHub**: https://github.com/huggingface/transformers
- **PyPI**: `pip install transformers`
- **Best For**: Text, vision, audio model training and inference

**🚀 Accelerate** - `/huggingface/accelerate` (Context7)

- **Purpose**: Distributed training across GPUs/TPUs without code changes
- **Docs**: https://huggingface.co/docs/accelerate
- **Features**: FSDP, DeepSpeed, mixed precision (fp16, bf16, fp8)
- **GitHub**: https://github.com/huggingface/accelerate
- **PyPI**: `pip install accelerate`
- **Best For**: Scaling training to multiple GPUs effortlessly

**⚡ PEFT (Parameter-Efficient Fine-Tuning)** - `/huggingface/peft` (Context7)

- **Purpose**: Fine-tune large models with 90% less memory/cost
- **Docs**: https://huggingface.co/docs/peft
- **Methods**: LoRA, QLoRA, Prefix Tuning, P-Tuning
- **GitHub**: https://github.com/huggingface/peft
- **PyPI**: `pip install peft`
- **Best For**: Fine-tuning LLMs on consumer GPUs
- **💰 Cost Savings**: Train 7B models on single GPU instead of 8x GPUs

**🎓 TRL (Transformer Reinforcement Learning)** - `/huggingface/trl` (Context7)

- **Purpose**: RLHF, reward modeling, preference tuning
- **Docs**: https://huggingface.co/docs/trl
- **GitHub**: https://github.com/huggingface/trl
- **PyPI**: `pip install trl`
- **Best For**: Training models with human feedback

### PyTorch Lightning - `/lightning-ai/pytorch-lightning` (Context7)

- **Purpose**: High-level PyTorch wrapper for production training
- **Docs**: https://lightning.ai/docs/pytorch/stable/
- **Features**: Multi-GPU, TPU, automatic optimization
- **GitHub**: https://github.com/lightning-ai/pytorch-lightning
- **PyPI**: `pip install lightning`
- **Best For**: Any PyTorch model with minimal boilerplate
- **Key Feature**: "Pretrain, finetune ANY model on multiple GPUs/TPUs with ZERO code changes"

### Ray - `/ray-project/ray` (Context7)

- **Purpose**: Distributed ML training and hyperparameter tuning
- **Docs**: https://docs.ray.io/en/latest/
- **Ray Train**: https://docs.ray.io/en/latest/train/train.html
- **Ray Tune**: https://docs.ray.io/en/latest/tune/index.html (hyperparameter optimization)
- **GitHub**: https://github.com/ray-project/ray
- **PyPI**: `pip install ray[train]`
- **Best For**: Large-scale distributed training, HPO

### Framework Comparison

| Framework              | Best For             | Learning Curve | GPU Scaling                 | Cost Efficiency |
| ---------------------- | -------------------- | -------------- | --------------------------- | --------------- |
| **HuggingFace + PEFT** | LLM fine-tuning      | Easy           | Excellent (with Accelerate) | ⭐⭐⭐⭐⭐      |
| **PyTorch Lightning**  | General ML           | Medium         | Excellent                   | ⭐⭐⭐⭐        |
| **Ray**                | Distributed training | Hard           | Excellent                   | ⭐⭐⭐⭐        |

---

## 💰 **Affordable GPU Cloud Platforms**

### Modal (⭐ BEST FOR STARTUPS)

**Serverless GPU Compute - Only Pay for What You Use**

- **Website**: https://modal.com
- **Docs**: https://modal.com/docs
- **Pricing**: https://modal.com/pricing
- **GitHub**: https://github.com/modal-labs/modal-examples

#### Pricing (Per Second + Per Hour)

| GPU           | Per Second | Per Hour  | Best For                  |
| ------------- | ---------- | --------- | ------------------------- |
| **T4**        | $0.000164  | **$0.59** | Development, small models |
| **L4**        | $0.000222  | $0.80     | Cost-effective training   |
| **A10**       | $0.000306  | $1.10     | Mid-range training        |
| **A100 40GB** | $0.000583  | $2.10     | Large model training      |
| **A100 80GB** | $0.000694  | $2.50     | Very large models         |
| **H100**      | $0.001097  | $3.95     | Cutting-edge training     |
| **H200**      | $0.001261  | $4.54     | Latest generation         |
| **B200**      | $0.001736  | $6.25     | Maximum performance       |

#### Plans & Free Credits

- **Starter**: $0/month + **$30 free credits/month**
- **Team**: $250/month + $100 free credits/month
- **🎁 Startup Credits**: Up to **$50,000 FREE** for early-stage startups
- **🎓 Academic Credits**: Up to **$10,000 FREE** for researchers

#### Key Features

- ✅ Auto-scaling (0 to thousands of GPUs)
- ✅ <200ms cold starts with containers
- ✅ Custom domains and deployment rollbacks
- ✅ Real-time metrics and logging
- ✅ Python-native (write Python, deploy anywhere)

#### Quick Start

```python
import modal

app = modal.App("ml-training")

@app.function(gpu="T4", timeout=3600)
def train_model():
    # Your training code here
    pass
```

**Integration**: Perfect for FastAPI backend (train on Modal, serve via FastAPI)

---

### Lambda Labs

**Pre-configured ML Instances - Best for Continuous Training**

- **Website**: https://lambdalabs.com/service/gpu-cloud
- **Docs**: https://docs.lambdalabs.com/
- **API**: https://docs.lambdalabs.com/cloud/api-reference

#### Pricing (On-Demand, 8x GPU Clusters)

| Configuration      | Per GPU/Hour | Total/Hour | Total/Day | Best For                  |
| ------------------ | ------------ | ---------- | --------- | ------------------------- |
| **8x V100 (16GB)** | $0.55        | **$4.40**  | **$106**  | Most affordable multi-GPU |
| **8x A100 40GB**   | $1.29        | $10.32     | $248      | Standard training         |
| **8x A100 80GB**   | $1.79        | $14.32     | $344      | Large model training      |
| **8x H100**        | $2.99        | $23.92     | $574      | High-performance training |
| **8x B200**        | $4.99        | $39.92     | $958      | Maximum performance       |

#### Single GPU Options

| GPU        | Per Hour  | Per Day   | Best For            |
| ---------- | --------- | --------- | ------------------- |
| **1x A10** | **$0.31** | **$7.34** | Cheapest single GPU |

#### Key Features

- ✅ **Pre-installed ML Stack**: PyTorch, TensorFlow, CUDA, cuDNN (Lambda Stack)
- ✅ **One-click Jupyter** access
- ✅ **No egress fees**
- ✅ **1-Click Clusters**: 16-512 interconnected GPUs
- ✅ **REST API** for programmatic control
- ✅ **Real-time monitoring**

#### Quick Start

```bash
# Launch instance via API
curl -X POST https://cloud.lambdalabs.com/api/v1/instance-operations/launch \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{"instance_type_name": "gpu_1x_a10"}'
```

**Integration**: Perfect for scheduled training jobs triggered from FastAPI

---

### RunPod

**Serverless + On-Demand - Trusted by 500,000+ Developers**

- **Website**: https://www.runpod.io/
- **Docs**: https://docs.runpod.io/
- **Serverless**: https://www.runpod.io/serverless-gpu

#### Key Features

- ✅ **FlashBoot**: <200ms cold-starts
- ✅ **Auto-scale**: 0 to 1000+ GPUs in seconds
- ✅ **Zero egress fees** on storage
- ✅ **S3-compatible storage**
- ✅ **30+ GPU SKUs** (B200 to RTX 4090)
- ✅ **99.9% uptime**, SOC 2 Type II compliant

#### Trusted By

- Cursor, HuggingFace, OpenAI, Perplexity, Replit, Zillow, Wix
- **500,000+ developers**
- **>500M serverless requests/month**

#### Cost Savings

- Customer reported: **90% infrastructure cost reduction**
- **57% average reduction** in setup time
- **Unlimited data** processed with zero ingress/egress

#### Pricing Model

- **Pay-per-minute** for on-demand
- **Serverless**: Pay only for actual compute time
- **No egress fees** on storage (unlike AWS/GCP)

**Integration**: Excellent for bursty training workloads from Next.js apps

---

### Platform Comparison

| Platform   | Best For             | Pricing Model | Free Credits          | Cold Start | Egress Fees |
| ---------- | -------------------- | ------------- | --------------------- | ---------- | ----------- |
| **Modal**  | Serverless, startups | Per-second    | $30/mo + $50K startup | <200ms     | ✅ None     |
| **Lambda** | Continuous training  | Per-hour      | None                  | Instant    | ✅ None     |
| **RunPod** | Bursty workloads     | Per-minute    | None                  | <200ms     | ✅ None     |

#### Cost Comparison Examples

**Training a 7B Model (4 hours)**

| Platform | GPU       | Cost               |
| -------- | --------- | ------------------ |
| Modal    | T4        | $2.36              |
| Lambda   | 1x A10    | $1.24 ⭐ Cheapest  |
| Modal    | A100 40GB | $8.40              |
| Lambda   | 8x V100   | $17.60 (multi-GPU) |

**Inference (1000 requests/day, 2 sec each)**

| Platform         | GPU    | Daily Cost | Monthly Cost          |
| ---------------- | ------ | ---------- | --------------------- |
| Modal Serverless | T4     | $0.09 ⭐   | $2.70                 |
| Lambda           | 1x A10 | $0.02      | $0.60 (if idle 99.9%) |

---

## 🔄 **Model Training Pipeline**

### Step 1: Data Preparation

```python
from datasets import load_dataset

# Load your custom dataset
dataset = load_dataset("json", data_files={
    "train": "train.json",
    "validation": "val.json"
})

# Or use HuggingFace datasets
dataset = load_dataset("imdb")  # Example: sentiment analysis
```

**Integration**: Store training data in **Supabase** (existing plugin)

---

### Step 2: Model Selection

#### For Text Classification/Generation

```python
from transformers import AutoModelForSequenceClassification, AutoTokenizer

# Small models (< 1GB)
model = AutoModelForSequenceClassification.from_pretrained(
    "distilbert-base-uncased",
    num_labels=5
)

# Medium models (1-3GB)
model = AutoModelForSequenceClassification.from_pretrained(
    "bert-base-uncased",
    num_labels=5
)

# Large models (7B+) - Use PEFT
from peft import LoraConfig, get_peft_model

base_model = AutoModelForCausalLM.from_pretrained("meta-llama/Llama-2-7b-hf")
lora_config = LoraConfig(
    r=16,  # Low rank
    lora_alpha=32,
    target_modules=["q_proj", "v_proj"],
    lora_dropout=0.1,
)
model = get_peft_model(base_model, lora_config)
```

---

### Step 3: Training Configuration

#### Basic Training (HuggingFace Trainer)

```python
from transformers import TrainingArguments, Trainer

training_args = TrainingArguments(
    output_dir="./results",
    num_train_epochs=3,
    per_device_train_batch_size=16,
    per_device_eval_batch_size=16,
    learning_rate=2e-5,
    weight_decay=0.01,
    evaluation_strategy="epoch",
    save_strategy="epoch",
    load_best_model_at_end=True,
    push_to_hub=False,
    logging_steps=100,
    fp16=True,  # Mixed precision for speed
)

trainer = Trainer(
    model=model,
    args=training_args,
    train_dataset=dataset["train"],
    eval_dataset=dataset["validation"],
    tokenizer=tokenizer,
)

# Train
trainer.train()
```

#### Distributed Training (Multi-GPU)

```python
# PyTorch Lightning
import lightning as L

trainer = L.Trainer(
    accelerator="gpu",
    devices=8,  # Use 8 GPUs
    strategy="ddp",  # Distributed Data Parallel
    precision="16-mixed",  # Mixed precision
    max_epochs=10,
)

trainer.fit(model, train_dataloader)
```

---

### Step 4: Deploy on GPU Cloud

#### Modal Deployment

```python
import modal

stub = modal.Stub("ml-training")

@stub.function(
    gpu="A100",
    timeout=3600,
    secrets=[modal.Secret.from_name("huggingface-secret")]
)
def train_model():
    from transformers import Trainer, TrainingArguments

    # Your training code
    trainer.train()

    # Save model
    trainer.save_model("./trained_model")

    # Upload to HuggingFace Hub
    trainer.push_to_hub("my-trained-model")

# Run locally
if __name__ == "__main__":
    with stub.run():
        train_model.remote()
```

#### Lambda Labs Deployment

```bash
# Launch instance
curl -X POST https://cloud.lambdalabs.com/api/v1/instance-operations/launch \
  -H "Authorization: Bearer $LAMBDA_API_KEY" \
  -d '{
    "instance_type_name": "gpu_8x_a100",
    "ssh_key_names": ["my-key"],
    "file_system_names": [],
    "quantity": 1
  }'

# SSH and train
ssh ubuntu@<instance-ip>
cd /workspace
python train.py
```

---

## 🚀 **Model Deployment & Inference**

### Deployment Options

| Option                    | Latency  | Cost        | Scalability | Best For            |
| ------------------------- | -------- | ----------- | ----------- | ------------------- |
| **Modal Serverless**      | 200ms    | Pay-per-use | ⭐⭐⭐⭐⭐  | Production APIs     |
| **FastAPI + GPU**         | <50ms    | Fixed       | ⭐⭐⭐      | Dedicated service   |
| **HuggingFace Inference** | 500ms-2s | Free tier   | ⭐⭐⭐⭐    | Testing             |
| **Vercel Edge**           | <100ms   | Pay-per-use | ⭐⭐⭐⭐⭐  | Global distribution |

---

### Option 1: Modal Serverless Inference (⭐ RECOMMENDED)

```python
import modal

stub = modal.Stub("ml-inference")

@stub.cls(
    gpu="T4",
    container_idle_timeout=300,
)
class ModelInference:
    def __enter__(self):
        from transformers import AutoModelForSequenceClassification, AutoTokenizer

        self.model = AutoModelForSequenceClassification.from_pretrained(
            "my-trained-model"
        )
        self.tokenizer = AutoTokenizer.from_pretrained("my-trained-model")

    @modal.method()
    def predict(self, text: str):
        inputs = self.tokenizer(text, return_tensors="pt")
        outputs = self.model(**inputs)
        return outputs.logits.argmax().item()

@stub.function()
@modal.web_endpoint(method="POST")
def api_predict(data: dict):
    model = ModelInference()
    result = model.predict.remote(data["text"])
    return {"prediction": result}
```

**Deploy**: `modal deploy inference.py`
**Endpoint**: `https://your-workspace--ml-inference-api-predict.modal.run`

---

### Option 2: FastAPI Backend (Existing Plugin Integration)

```python
# fastapi_backend/app/ml/inference.py
from fastapi import APIRouter
from transformers import pipeline
from pydantic import BaseModel

router = APIRouter(prefix="/ml", tags=["Machine Learning"])

# Load model once at startup
classifier = pipeline("text-classification", model="my-trained-model")

class PredictionRequest(BaseModel):
    text: str

class PredictionResponse(BaseModel):
    label: str
    score: float

@router.post("/predict", response_model=PredictionResponse)
async def predict(request: PredictionRequest):
    result = classifier(request.text)[0]
    return PredictionResponse(
        label=result["label"],
        score=result["score"]
    )
```

**Integration**: Add to existing **fastapi-backend** plugin

---

### Option 3: Vercel AI SDK Integration (Existing Plugin)

```typescript
// nextjs-frontend/lib/ml-api.ts
import { openai } from '@ai-sdk/openai';
import { generateText } from 'ai';

// Use your custom trained model via Modal endpoint
export async function predictWithCustomModel(text: string) {
  const response = await fetch('https://your-modal-endpoint.modal.run', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ text }),
  });

  return response.json();
}

// Or use with Vercel AI SDK streaming
export async function streamPrediction(text: string) {
  const { text: result } = await generateText({
    model: openai('gpt-4'),
    system: 'You are a trained model for...',
    prompt: text,
  });

  return result;
}
```

**Integration**: Add to existing **nextjs-frontend** and **vercel-ai-sdk** plugins

---

## 🔗 **Integration with Existing Stack**

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     AI Dev Marketplace Stack                 │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  Frontend (Next.js + Vercel AI SDK)                         │
│  ├── User Interface                                          │
│  ├── Streaming responses from ML models                      │
│  └── Real-time predictions                                   │
│                          │                                    │
│                          ▼                                    │
│  Backend (FastAPI)                                           │
│  ├── /ml/predict (custom models)                            │
│  ├── /ml/train (trigger training jobs)                      │
│  ├── /rag/query (RAG pipeline)                              │
│  └── Authentication                                          │
│                          │                                    │
│         ┌────────────────┴────────────────┐                 │
│         ▼                                  ▼                  │
│  ML Training (Modal/Lambda)        RAG Pipeline              │
│  ├── Train custom models           ├── Document ingestion   │
│  ├── Fine-tune LLMs                ├── Vector embeddings    │
│  ├── Deploy to serverless          └── Similarity search    │
│  └── Auto-scaling                                            │
│         │                                  │                  │
│         ▼                                  ▼                  │
│  Storage (Supabase)                                          │
│  ├── Training datasets                                       │
│  ├── Model metadata                                          │
│  ├── Vector embeddings (pgvector)                           │
│  └── User data                                               │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

### Plugin Integration Matrix

| Plugin              | ML Training Use      | ML Inference Use        | RAG Use             |
| ------------------- | -------------------- | ----------------------- | ------------------- |
| **fastapi-backend** | Trigger training API | Serve model predictions | Query endpoint      |
| **nextjs-frontend** | Training UI          | Display predictions     | Search interface    |
| **supabase**        | Store datasets       | Cache predictions       | Vector storage      |
| **vercel-ai-sdk**   | N/A                  | Stream responses        | Stream RAG results  |
| **mem0**            | N/A                  | Personalization         | Memory augmentation |
| **openrouter**      | N/A                  | Fallback inference      | LLM for RAG         |

---

### Complete Integration Example

#### 1. Store Training Data (Supabase)

```typescript
// supabase/schema.sql
CREATE TABLE training_datasets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    data JSONB NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE trained_models (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    model_path TEXT NOT NULL,
    metrics JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);
```

#### 2. Trigger Training (FastAPI)

```python
# fastapi_backend/app/routers/ml.py
from fastapi import APIRouter, BackgroundTasks
import modal

router = APIRouter()

@router.post("/ml/train")
async def trigger_training(
    dataset_id: str,
    background_tasks: BackgroundTasks
):
    # Fetch data from Supabase
    dataset = fetch_from_supabase(dataset_id)

    # Trigger Modal training job
    stub = modal.lookup("ml-training", "train_model")
    call = stub.spawn(dataset)

    return {
        "status": "training_started",
        "job_id": call.object_id
    }
```

#### 3. Display Results (Next.js)

```typescript
// nextjs-frontend/app/ml/train/page.tsx
'use client';

import { useState } from 'react';

export default function TrainModel() {
  const [status, setStatus] = useState('');

  async function startTraining() {
    const res = await fetch('/api/ml/train', {
      method: 'POST',
      body: JSON.stringify({ dataset_id: 'xxx' }),
    });

    const data = await res.json();
    setStatus(`Training started: ${data.job_id}`);
  }

  return (
    <div>
      <button onClick={startTraining}>Start Training</button>
      <p>{status}</p>
    </div>
  );
}
```

---

## 🎯 **ML Algorithms & Use Cases**

### Classification Algorithms

| Algorithm               | Library      | Best For                  | Training Time | Inference Speed |
| ----------------------- | ------------ | ------------------------- | ------------- | --------------- |
| **Logistic Regression** | scikit-learn | Simple binary/multi-class | <1 min        | ⚡⚡⚡⚡⚡      |
| **Random Forest**       | scikit-learn | Structured data           | 5-30 min      | ⚡⚡⚡⚡        |
| **XGBoost**             | xgboost      | Tabular data              | 10-60 min     | ⚡⚡⚡⚡        |
| **BERT**                | HuggingFace  | Text classification       | 1-4 hours     | ⚡⚡⚡          |
| **ResNet**              | PyTorch/HF   | Image classification      | 2-8 hours     | ⚡⚡⚡          |

### Generation Algorithms

| Algorithm            | Library     | Best For         | Training Time | Use Case                   |
| -------------------- | ----------- | ---------------- | ------------- | -------------------------- |
| **GPT-2/3**          | HuggingFace | Text generation  | 4-24 hours    | Content creation           |
| **T5**               | HuggingFace | Seq2seq tasks    | 4-24 hours    | Summarization, translation |
| **BART**             | HuggingFace | Summarization    | 2-12 hours    | Article summaries          |
| **Stable Diffusion** | HuggingFace | Image generation | 8-48 hours    | Image creation             |

### Recommendation Algorithms

| Algorithm                   | Library      | Best For                      | Training Time |
| --------------------------- | ------------ | ----------------------------- | ------------- |
| **Collaborative Filtering** | scikit-learn | User-item recommendations     | <30 min       |
| **Matrix Factorization**    | Surprise     | Large-scale recommendations   | 1-4 hours     |
| **Neural Collaborative**    | PyTorch      | Deep learning recommendations | 2-8 hours     |

### Time Series & Forecasting

| Algorithm       | Library        | Best For              | Training Time |
| --------------- | -------------- | --------------------- | ------------- |
| **ARIMA**       | statsmodels    | Simple forecasting    | <5 min        |
| **Prophet**     | Prophet (Meta) | Business forecasting  | 5-30 min      |
| **LSTM**        | PyTorch        | Complex sequences     | 1-6 hours     |
| **Transformer** | HuggingFace    | Long-term forecasting | 2-12 hours    |

---

## 💡 **Cost Optimization Strategies**

### 1. Use Parameter-Efficient Fine-Tuning (PEFT)

**Savings**: 90% reduction in GPU memory and cost

```python
from peft import LoraConfig, get_peft_model

# Instead of fine-tuning all 7B parameters...
# Fine-tune only 0.1% with LoRA
lora_config = LoraConfig(
    r=8,  # Rank
    lora_alpha=16,
    lora_dropout=0.1,
    target_modules=["q_proj", "v_proj"],
)

model = get_peft_model(base_model, lora_config)

# Train on single T4 instead of 8x A100
# Cost: $2.36 (4 hours) vs $67.20 (4 hours on 8x A100)
```

### 2. Use Modal for Serverless Training

**Savings**: Only pay for actual compute time

```python
# Traditional: Pay for entire hour even if training takes 20 minutes
# Cost: $2.10 (full hour A100)

# Modal: Pay only for 20 minutes
# Cost: $0.70 (20 minutes)
# Savings: 67%
```

### 3. Use Spot Instances on Lambda

**Savings**: Up to 70% off on-demand pricing

```bash
# Reserved instances: Long-term commitments
# Spot instances: Interruptible but cheap
```

### 4. Optimize Batch Size

```python
# Smaller batch = more iterations = longer training
per_device_train_batch_size=4  # Slow

# Larger batch = fewer iterations = faster training
per_device_train_batch_size=32  # 8x faster

# With gradient accumulation (if GPU memory limited)
per_device_train_batch_size=4
gradient_accumulation_steps=8  # Effective batch size: 32
```

### 5. Use Mixed Precision Training

```python
training_args = TrainingArguments(
    fp16=True,  # 16-bit precision
    # Or
    bf16=True,  # Brain float 16 (better for large models)
)

# Savings: 2x faster training, 50% less memory
# A100: 2 hours instead of 4 hours = $5 vs $10
```

### 6. Cache Preprocessing

```python
# Bad: Tokenize on every epoch
dataset.map(tokenize_function)  # Slow

# Good: Cache preprocessing
dataset = dataset.map(
    tokenize_function,
    batched=True,
    num_proc=4,
    load_from_cache_file=True  # Save 30% training time
)
```

---

## 📝 **Complete Code Examples**

### Example 1: Train Sentiment Classifier (Affordable)

```python
# train_sentiment.py
from datasets import load_dataset
from transformers import (
    AutoTokenizer,
    AutoModelForSequenceClassification,
    TrainingArguments,
    Trainer
)

# 1. Load data
dataset = load_dataset("imdb")

# 2. Tokenize
tokenizer = AutoTokenizer.from_pretrained("distilbert-base-uncased")

def tokenize(examples):
    return tokenizer(examples["text"], padding="max_length", truncation=True)

dataset = dataset.map(tokenize, batched=True)

# 3. Load model
model = AutoModelForSequenceClassification.from_pretrained(
    "distilbert-base-uncased",
    num_labels=2
)

# 4. Training config
training_args = TrainingArguments(
    output_dir="./sentiment-model",
    num_train_epochs=3,
    per_device_train_batch_size=16,
    learning_rate=2e-5,
    evaluation_strategy="epoch",
    save_strategy="epoch",
    fp16=True,
)

# 5. Train
trainer = Trainer(
    model=model,
    args=training_args,
    train_dataset=dataset["train"].shuffle().select(range(5000)),  # Small subset
    eval_dataset=dataset["test"].shuffle().select(range(1000)),
    tokenizer=tokenizer,
)

trainer.train()

# 6. Save
trainer.save_model("./sentiment-model-final")
```

**Cost**: ~$1.50 (T4, 1.5 hours on Modal)

---

### Example 2: Deploy Model to Modal

```python
# deploy.py
import modal

stub = modal.Stub("sentiment-classifier")

@stub.cls(
    gpu="T4",
    container_idle_timeout=300,
    secrets=[modal.Secret.from_name("huggingface")],
)
class SentimentClassifier:
    def __enter__(self):
        from transformers import pipeline

        self.classifier = pipeline(
            "sentiment-analysis",
            model="./sentiment-model-final",
            device=0  # GPU
        )

    @modal.method()
    def predict(self, text: str):
        result = self.classifier(text)[0]
        return {
            "label": result["label"],
            "score": result["score"]
        }

@stub.function()
@modal.web_endpoint(method="POST")
def api(data: dict):
    classifier = SentimentClassifier()
    return classifier.predict.remote(data["text"])
```

**Deploy**: `modal deploy deploy.py`
**Inference Cost**: $0.000164/sec = ~$0.0005 per request

---

### Example 3: FastAPI Integration

```python
# fastapi_backend/app/routers/ml.py
from fastapi import APIRouter
import httpx

router = APIRouter(prefix="/ml", tags=["ML"])

MODAL_ENDPOINT = "https://your-workspace--sentiment-classifier-api.modal.run"

@router.post("/predict")
async def predict(text: str):
    async with httpx.AsyncClient() as client:
        response = await client.post(
            MODAL_ENDPOINT,
            json={"text": text}
        )
        return response.json()
```

---

### Example 4: Next.js Frontend

```typescript
// nextjs-frontend/app/ml/page.tsx
'use client';

import { useState } from 'react';

export default function MLPrediction() {
  const [text, setText] = useState('');
  const [result, setResult] = useState(null);

  async function predict() {
    const res = await fetch('/api/ml/predict', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ text }),
    });

    const data = await res.json();
    setResult(data);
  }

  return (
    <div className="p-4">
      <textarea
        value={text}
        onChange={(e) => setText(e.target.value)}
        className="w-full p-2 border rounded"
        placeholder="Enter text to analyze..."
      />
      <button
        onClick={predict}
        className="mt-2 px-4 py-2 bg-blue-500 text-white rounded"
      >
        Predict
      </button>

      {result && (
        <div className="mt-4 p-4 bg-gray-100 rounded">
          <p>Label: {result.label}</p>
          <p>Confidence: {(result.score * 100).toFixed(2)}%</p>
        </div>
      )}
    </div>
  );
}
```

---

## 📚 **Additional Resources**

### HuggingFace Hub

- **Models**: https://huggingface.co/models
- **Datasets**: https://huggingface.co/datasets
- **Spaces**: https://huggingface.co/spaces (free inference endpoints)

### Learning Resources

- **HuggingFace Course**: https://huggingface.co/learn/nlp-course
- **FastAI Course**: https://course.fast.ai/ (free)
- **DeepLearning.AI**: https://www.deeplearning.ai/ (free courses)
- **PyTorch Tutorials**: https://pytorch.org/tutorials/

### Community

- **HuggingFace Discord**: https://discord.gg/hugging-face
- **Modal Community**: https://modal.com/community
- **r/MachineLearning**: https://reddit.com/r/MachineLearning

---

## ✅ **Quick Start Checklist**

### Training Setup

- [ ] Choose training framework (HuggingFace + PEFT recommended)
- [ ] Select GPU platform (Modal for serverless, Lambda for continuous)
- [ ] Prepare training data (store in Supabase)
- [ ] Set up training script with mixed precision
- [ ] Test locally on small dataset
- [ ] Deploy training job to cloud
- [ ] Monitor training metrics

### Deployment Setup

- [ ] Deploy model to Modal serverless
- [ ] Create FastAPI endpoint for inference
- [ ] Add Next.js frontend UI
- [ ] Set up error handling and logging
- [ ] Test end-to-end integration
- [ ] Monitor inference latency and costs
- [ ] Set up auto-scaling

### Cost Optimization

- [ ] Use PEFT for large models (90% savings)
- [ ] Enable mixed precision training (2x speedup)
- [ ] Cache preprocessing (30% time savings)
- [ ] Use serverless for inference (pay-per-use)
- [ ] Apply for startup credits (Modal: $50K free)
- [ ] Monitor and optimize batch sizes
- [ ] Use spot instances when available

---

**Last Updated**: November 1, 2025
**Maintainer**: GitHub Copilot (Grok AI + Sonnet)
**Cost Target**: $5-50/month for training + inference pipeline
**Integration**: Works with all AI Dev Marketplace plugins (FastAPI, Next.js, Supabase, Vercel AI SDK, Mem0, OpenRouter)
