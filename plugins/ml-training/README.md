# ML Training Plugin

Machine learning training and inference pipeline using cloud GPUs (Modal, Lambda Labs, RunPod) with HuggingFace ecosystem - no local GPU required.

## Overview

This plugin enables ML model training and deployment without requiring local GPU hardware. All training runs on cloud GPU platforms with pay-per-use pricing, making it accessible and cost-effective for startups and individual developers.

## Key Features

- **Cloud GPU Training**: Modal ($0.59/hr), Lambda Labs ($0.31/hr), RunPod (pay-per-minute)
- **No Local GPU Required**: Run everything from any laptop with internet
- **HuggingFace Ecosystem**: Transformers, PEFT, Accelerate, TRL
- **Cost Optimization**: LoRA/QLoRA for 90% memory reduction
- **Serverless Inference**: Auto-scaling endpoints with Modal
- **Full Stack Integration**: FastAPI, Next.js, Supabase

## Quick Start

```bash
# Initialize ML project
/ml:init my-classifier

# Add cloud platform
/ml:add-platform modal

# Add training data from Supabase
/ml:add-dataset supabase training_data

# Configure training
/ml:add-training-config classification

# Deploy training to cloud GPU
/ml:deploy-training

# Deploy inference endpoint
/ml:deploy-inference
```

## Commands

### Core Initialization
- `/ml:init` - Initialize ML training project
- `/ml:add-platform` - Add Modal/Lambda/RunPod platform
- `/ml:setup-framework` - Configure HuggingFace/PyTorch/Ray

### Data Preparation
- `/ml:add-dataset` - Load training data from Supabase/local/HuggingFace
- `/ml:add-preprocessing` - Add tokenization and data transforms
- `/ml:validate-data` - Validate data quality

### Training Configuration
- `/ml:add-training-config` - Create training configuration
- `/ml:add-peft` - Add LoRA/QLoRA for cost savings
- `/ml:optimize-training` - Optimize batch size and mixed precision
- `/ml:add-monitoring` - Add TensorBoard/WandB monitoring

### Cloud GPU Deployment
- `/ml:deploy-training` - Deploy training job to cloud GPU
- `/ml:deploy-inference` - Deploy model for serverless inference
- `/ml:monitor-training` - Monitor active training jobs

### Integration
- `/ml:add-fastapi-endpoint` - Add inference endpoint to FastAPI
- `/ml:add-nextjs-ui` - Add ML UI components to Next.js
- `/ml:integrate-supabase` - Connect to Supabase for data storage

### Testing & Utilities
- `/ml:test` - Test ML pipeline components
- `/ml:estimate-cost` - Estimate training and inference costs

## Architecture

```
Local Machine (No GPU)
├── requirements-local.txt    # Lightweight CLI tools
├── venv/                     # Virtual environment
├── train.py                  # Training script
└── modal_image.py           # Cloud GPU dependencies

Cloud GPU Servers (Modal/Lambda/RunPod)
├── torch                     # Heavy ML framework
├── transformers             # HuggingFace models
├── accelerate               # Distributed training
└── peft                     # LoRA/QLoRA
```

## Cost Examples

### Training (4 hours)
- Modal T4: $2.36
- Lambda A10: $1.24 (cheapest)
- Modal A100: $8.40

### Inference (10K requests/month)
- Modal Serverless: $5/month
- Auto-scaling 0-1000+ GPUs

## Integration

Works with existing AI Dev Marketplace plugins:
- **fastapi-backend**: Serve inference endpoints
- **nextjs-frontend**: Display predictions and training UI
- **supabase**: Store training data and model metadata
- **vercel-ai-sdk**: Stream inference results
- **rag-pipeline**: Combine RAG retrieval with ML predictions

## Documentation

See `/home/gotime2022/.claude/plugins/marketplaces/ai-dev-marketplace/ML-TRAINING-AND-INFERENCE.md` for comprehensive guide.

## License

MIT License - see LICENSE file

## Version

1.0.0 (2025-11-01)
