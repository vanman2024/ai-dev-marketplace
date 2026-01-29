---
description: Add a specific feature to an existing ML training project. Features include dataset, model, distributed, finetune, deploy, platform.
argument-hint: <feature> [options]
---

# Add ML Training Feature

**Requested Feature:** `$0`
**Additional Options:** `$1` `$2`

---

## Argument Routing

Based on the feature argument `$0`, route to the appropriate specialized agent:

### Data Features

**If `$0` = "dataset":**

```
Task(data-specialist) Add DATASET pipeline.

Requirements:
- Dataset type: $1 (image, text, tabular, custom - required)
- Format: $2 (huggingface, local, s3 - default: local)
- Create data loader
- Add preprocessing
- Configure augmentation
- Set up splits
```

**If `$0` = "preprocessing":**

```
Task(data-engineer) Add PREPROCESSING pipeline.

Requirements:
- Data type: $1 (image, text, tabular - required)
- Create preprocessing transforms
- Add normalization
- Configure batching
- Set up caching
```

### Model Features

**If `$0` = "model":**

```
Task(training-architect) Add MODEL architecture.

Requirements:
- Architecture: $1 (transformer, cnn, rnn, custom - required)
- Task: $2 (classification, generation, detection - default: classification)
- Create model class
- Configure layers
- Set up forward pass
- Add loss function
```

### Training Features

**If `$0` = "distributed":**

```
Task(distributed-training-specialist) Add DISTRIBUTED training.

Requirements:
- Type: $1 (ddp, fsdp, deepspeed - default: ddp)
- GPUs: $2 (number or auto - default: auto)
- Configure distributed backend
- Set up process groups
- Add gradient sync
- Configure checkpointing
```

**If `$0` = "finetune":**

```
Task(peft-specialist) Add FINE-TUNING.

Requirements:
- Method: $1 (lora, qlora, full, adapter - default: lora)
- Base model: $2 (model name or path)
- Set up PEFT config
- Configure trainable params
- Add efficient loading
```

### Platform Features

**If `$0` = "platform":**

```
Based on $1, route to appropriate specialist:

If $1 = "modal":
Task(modal-specialist) Set up MODAL training.

If $1 = "runpod":
Task(runpod-specialist) Set up RUNPOD training.

If $1 = "lambda":
Task(lambda-specialist) Set up LAMBDA LABS training.

If $1 = "vertex":
Task(google-vertex-specialist) Set up VERTEX AI training.

If $1 = "bigquery":
Task(google-bigquery-ml-specialist) Set up BIGQUERY ML.

Requirements:
- Configure platform credentials
- Set up compute resources
- Create training job
- Configure storage
```

### Deployment Features

**If `$0` = "deploy":**

```
Task(inference-deployer) Add DEPLOYMENT.

Requirements:
- Platform: $1 (api, modal, vertex, sagemaker - default: api)
- Export format: $2 (onnx, torchscript, huggingface - default: onnx)
- Export model
- Create inference endpoint
- Configure batching
- Add health checks
```

### Monitoring Features

**If `$0` = "monitoring":**

```
Task(training-monitor) Add MONITORING.

Requirements:
- Tool: $1 (wandb, tensorboard, mlflow - default: wandb)
- Set up experiment tracking
- Add metric logging
- Configure visualization
- Set up alerts
```

### Optimization Features

**If `$0` = "optimize":**

```
Task(cost-optimizer) Add COST OPTIMIZATION.

Requirements:
- Focus: $1 (memory, speed, cost - default: all)
- Add gradient checkpointing
- Configure mixed precision
- Optimize batch size
- Add spot instance support
```

---

## Usage Examples

```bash
# Data
/ml-training:add dataset image huggingface
/ml-training:add preprocessing text

# Models
/ml-training:add model transformer classification
/ml-training:add model cnn detection

# Training
/ml-training:add distributed ddp 4
/ml-training:add finetune lora meta-llama/Llama-2-7b

# Platforms
/ml-training:add platform modal
/ml-training:add platform vertex

# Deployment & Monitoring
/ml-training:add deploy api onnx
/ml-training:add monitoring wandb
/ml-training:add optimize memory
```

---

## Feature Reference

| Feature         | Agent                  | $1 Options                 | Description          |
| --------------- | ---------------------- | -------------------------- | -------------------- |
| `dataset`       | data-specialist        | image/text/tabular/custom  | Data pipeline        |
| `preprocessing` | data-engineer          | image/text/tabular         | Preprocessing        |
| `model`         | training-architect     | transformer/cnn/rnn/custom | Model architecture   |
| `distributed`   | distributed-specialist | ddp/fsdp/deepspeed         | Distributed training |
| `finetune`      | peft-specialist        | lora/qlora/full/adapter    | Fine-tuning          |
| `platform`      | various                | modal/runpod/lambda/vertex | Training platform    |
| `deploy`        | inference-deployer     | api/modal/vertex/sagemaker | Model deployment     |
| `monitoring`    | training-monitor       | wandb/tensorboard/mlflow   | Experiment tracking  |
| `optimize`      | cost-optimizer         | memory/speed/cost/all      | Cost optimization    |
