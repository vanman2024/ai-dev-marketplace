# Training Patterns Skill

Complete ML training templates and automation for classification, generation, fine-tuning, and PEFT/LoRA.

## Quick Start

```bash
cd /home/gotime2022/.claude/plugins/marketplaces/ai-dev-marketplace/plugins/ml-training/skills/training-patterns

# Classification
./scripts/setup-classification.sh my-classifier distilbert-base-uncased 3

# Generation
./scripts/setup-generation.sh my-generator t5-small question-answering

# Full Fine-Tuning
./scripts/setup-fine-tuning.sh domain-model bert-base-uncased classification

# PEFT/LoRA
./scripts/setup-peft.sh efficient-model roberta-base lora
```

## Files

### Scripts (Functional)
- `setup-classification.sh` - Classification training setup (15KB)
- `setup-generation.sh` - Generation training setup (13KB)
- `setup-fine-tuning.sh` - Full fine-tuning setup (12KB)
- `setup-peft.sh` - PEFT/LoRA setup (18KB)

### Templates
- `classification-config.yaml` - Classification hyperparameters
- `generation-config.yaml` - Generation hyperparameters
- `peft-config.json` - LoRA configuration

### Examples
- `sentiment-classifier.md` - Complete sentiment analysis example
- `text-generator.md` - Complete Q&A generation example

## What Each Script Creates

All scripts create complete, runnable training projects with:
- ✅ Full training script (not placeholder)
- ✅ Inference/prediction script
- ✅ Configuration files
- ✅ Example data
- ✅ requirements.txt
- ✅ README with instructions

## Training Scenarios

1. **Classification** - Text → Label (sentiment, intent, NER)
2. **Generation** - Text → Text (QA, summarization, translation)
3. **Fine-Tuning** - Update all parameters (requires GPU with 16GB+)
4. **PEFT/LoRA** - Update 0.1-1% of parameters (works on 8GB GPU)

## Key Features

- 🚀 **Production-ready** training code
- 💾 **Memory optimized** (fp16, gradient checkpointing)
- 📊 **Metrics tracking** (accuracy, F1, ROUGE)
- ⚡ **Fast setup** (1 command → complete project)
- 🎯 **Best practices** built-in
- 📝 **Comprehensive documentation**

Total skill size: ~60KB of functional code
