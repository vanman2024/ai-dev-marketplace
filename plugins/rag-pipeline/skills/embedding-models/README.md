# Embedding Models Skill

Comprehensive skill for embedding model selection, configuration, and cost optimization in RAG pipelines.

## Overview

This skill provides:
- **Model Selection Guide**: Compare OpenAI, Cohere, and HuggingFace models
- **Cost Calculator**: Functional Python script for embedding cost analysis
- **Setup Scripts**: Automated configuration for all major providers
- **Production Templates**: Ready-to-use Python classes with retry logic
- **Examples**: Batch processing and caching implementations

## Quick Start

### 1. Calculate Embedding Costs

```bash
# Compare all models for your use case
python scripts/calculate-embedding-costs.py \
  --documents 100000 \
  --avg-tokens 500 \
  --compare

# Analyze specific model
python scripts/calculate-embedding-costs.py \
  --documents 100000 \
  --avg-tokens 500 \
  --model text-embedding-3-small

# Include cache savings
python scripts/calculate-embedding-costs.py \
  --documents 100000 \
  --avg-tokens 500 \
  --model text-embedding-3-small \
  --cache-rate 0.3
```

### 2. Setup Embedding Provider

```bash
# OpenAI
bash scripts/setup-openai-embeddings.sh

# HuggingFace (local)
bash scripts/setup-huggingface-embeddings.sh

# Cohere
bash scripts/setup-cohere-embeddings.sh
```

### 3. Use Production Templates

```python
# OpenAI with retry logic
from templates.openai_embedding_config import OpenAIEmbeddings

embedder = OpenAIEmbeddings(model="text-embedding-3-small")
embeddings = embedder.embed(["text1", "text2"])

# HuggingFace with GPU support
from templates.huggingface_embedding_config import HuggingFaceEmbeddings

embedder = HuggingFaceEmbeddings(model_name="all-MiniLM-L6-v2")
embeddings = embedder.embed(["text1", "text2"])

# Unified interface for any provider
from templates.custom_embedding_model import EmbeddingFactory, EmbeddingProvider

embedder = EmbeddingFactory.create(
    provider=EmbeddingProvider.OPENAI,
    model_name="text-embedding-3-small"
)
```

## Features

### Cost Calculator

Fully functional Python script with:
- All major embedding models (OpenAI, Cohere, HuggingFace)
- Cost comparison across models
- Cache hit rate simulation
- Per-document cost analysis
- Cost savings calculations

**Example Output:**
```
EMBEDDING COST COMPARISON
Documents: 100,000 | Avg Tokens/Doc: 500 | Cache Rate: 30%

Model                          Provider             Cost
all-MiniLM-L6-v2               HuggingFace (Local)  $0.00
text-embedding-3-small         OpenAI               $0.70
text-embedding-3-large         OpenAI               $4.55
```

### Setup Scripts

Interactive setup scripts that:
- Install required dependencies
- Configure API keys securely
- Test API connections
- Download local models
- Provide usage examples

### Production Templates

**OpenAI Template** (`templates/openai-embedding-config.py`):
- Automatic retry with exponential backoff
- Batch processing with configurable size
- Rate limit handling
- Error recovery

**HuggingFace Template** (`templates/huggingface-embedding-config.py`):
- GPU/CPU auto-detection
- Batch processing optimization
- Normalized embeddings
- Similarity calculations
- Model presets (small, medium, large)

**Custom Model Template** (`templates/custom-embedding-model.py`):
- Unified interface for all providers
- Factory pattern for easy switching
- Configuration-based initialization
- Consistent API across providers

### Examples

**Batch Processing** (`examples/batch-embedding-generation.py`):
- Process large document collections
- Checkpoint/resume support
- Progress tracking
- Error recovery
- Multiple output formats (JSON, NPY, NPZ)

**Embedding Cache** (`examples/embedding-cache.py`):
- In-memory LRU cache
- Persistent disk cache
- Content-based hashing
- Cache statistics and monitoring
- TTL support
- Up to 90%+ API cost reduction

## Model Comparison

| Model | Provider | Dims | Cost/1M | Quality | Speed |
|-------|----------|------|---------|---------|-------|
| text-embedding-3-small | OpenAI | 1536 | $0.02 | Good | Fast |
| text-embedding-3-large | OpenAI | 3072 | $0.13 | Excellent | Medium |
| all-MiniLM-L6-v2 | HuggingFace | 384 | Free | Good | Very Fast |
| all-mpnet-base-v2 | HuggingFace | 768 | Free | Excellent | Fast |
| bge-large-en-v1.5 | HuggingFace | 1024 | Free | Excellent | Fast |
| embed-english-v3.0 | Cohere | 1024 | $0.10 | Excellent | Fast |

## Decision Guide

**Use OpenAI when:**
- Need highest quality embeddings
- Low to medium volume (<10M tokens/month)
- Prefer managed service
- Want latest models

**Use Cohere when:**
- Need multilingual support (100+ languages)
- Want specialized input types (search, clustering)
- Require production SLA
- Need both embedding and reranking

**Use HuggingFace/Local when:**
- High volume (>10M tokens/month)
- Data privacy requirements
- Have GPU infrastructure
- Cost optimization priority
- Offline/air-gapped deployment

## Directory Structure

```
embedding-models/
├── SKILL.md                          # Main skill definition
├── README.md                         # This file
├── scripts/
│   ├── calculate-embedding-costs.py  # Functional cost calculator
│   ├── setup-openai-embeddings.sh    # OpenAI setup script
│   ├── setup-huggingface-embeddings.sh
│   └── setup-cohere-embeddings.sh
├── templates/
│   ├── openai-embedding-config.py    # Production OpenAI template
│   ├── huggingface-embedding-config.py
│   └── custom-embedding-model.py     # Unified interface
└── examples/
    ├── batch-embedding-generation.py # Large-scale processing
    └── embedding-cache.py            # Caching implementation
```

## Testing

All components have been tested:

```bash
# Test cost calculator
python scripts/calculate-embedding-costs.py --list-models
python scripts/calculate-embedding-costs.py --documents 100000 --avg-tokens 500 --compare

# Test setup scripts
bash scripts/setup-openai-embeddings.sh
bash scripts/setup-huggingface-embeddings.sh
bash scripts/setup-cohere-embeddings.sh
```

## Documentation References

- OpenAI Embeddings: https://platform.openai.com/docs/guides/embeddings
- Sentence Transformers: https://www.sbert.net/
- Cohere Embeddings: https://docs.cohere.com/docs/embeddings
- HuggingFace Models: https://huggingface.co/models
- MTEB Leaderboard: https://huggingface.co/spaces/mteb/leaderboard

## License

Part of the rag-pipeline plugin in the ai-dev-marketplace.
