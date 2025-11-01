# Integration Helpers Skill

Production-ready integration templates for deploying ML models with FastAPI, Next.js, and Supabase.

## Overview

The `integration-helpers` skill provides complete templates and scripts for integrating trained machine learning models into full-stack applications. It covers all layers of ML deployment:

- **Backend**: FastAPI inference endpoints with proper error handling
- **Frontend**: Next.js prediction forms with shadcn/ui components
- **Database**: Supabase schemas for ML metadata and predictions

## Quick Start

### Generate FastAPI Endpoint

```bash
bash ./skills/integration-helpers/scripts/add-fastapi-endpoint.sh classification sentiment-analysis
```

Creates a complete FastAPI router with:
- Pydantic models for validation
- Model loading and caching
- Health check endpoint
- Batch prediction support
- Error handling

### Generate Next.js Component

```bash
bash ./skills/integration-helpers/scripts/add-nextjs-component.sh classification-form sentiment-form
```

Creates a React component with:
- Form validation (react-hook-form + zod)
- Loading states
- Result visualization
- Error handling

### Generate Supabase Schema

```bash
bash ./skills/integration-helpers/scripts/create-supabase-schema.sh ml-models
```

Creates database migrations for:
- Model registry
- Prediction logging
- Training run tracking
- Model version management

## Skill Structure

```
integration-helpers/
├── SKILL.md                           # Main skill documentation (561 lines)
├── README.md                          # This file
├── scripts/                           # Functional bash scripts
│   ├── add-fastapi-endpoint.sh       # Generate FastAPI ML router
│   ├── add-nextjs-component.sh       # Generate Next.js form component
│   └── create-supabase-schema.sh     # Generate Supabase migrations
├── templates/                         # Code templates
│   ├── fastapi-router.py             # FastAPI inference endpoint template
│   ├── nextjs-prediction-form.tsx    # Next.js prediction form template
│   └── supabase-schema.sql           # Supabase schema template
└── examples/                          # Complete examples
    ├── fastapi-inference-endpoint.md # End-to-end FastAPI example
    └── nextjs-ml-dashboard.md        # Full Next.js dashboard example
```

## Features

### FastAPI Endpoints

- **Model Types**: Classification, regression, text-generation, image-classification, embeddings
- **Request/Response Models**: Type-safe Pydantic models with validation
- **Model Loading**: Singleton pattern with efficient caching
- **Batch Predictions**: Process multiple inputs efficiently
- **Error Handling**: Proper HTTP status codes and error messages
- **Health Checks**: Model availability verification

### Next.js Components

- **Component Types**: Classification forms, regression forms, image upload, chat interfaces
- **UI Library**: shadcn/ui components with Tailwind CSS
- **Form Validation**: react-hook-form with zod schemas
- **State Management**: Loading, error, and success states
- **Result Visualization**: Progress bars, confidence scores, probability distributions

### Supabase Schemas

- **Schema Types**: ml-models, predictions, training-runs, model-versions, complete
- **Features**: UUID primary keys, JSONB for flexible storage, RLS policies
- **Indexes**: Performance-optimized indexes for common queries
- **Helper Functions**: Statistics, cleanup, version promotion
- **Triggers**: Auto-update timestamps

## Usage Examples

### Complete Sentiment Analysis System

```bash
# 1. Backend - Create FastAPI endpoint
cd fastapi-backend
bash ../plugins/ml-training/skills/integration-helpers/scripts/add-fastapi-endpoint.sh classification sentiment-analysis

# 2. Frontend - Create Next.js form
cd ../nextjs-frontend
bash ../plugins/ml-training/skills/integration-helpers/scripts/add-nextjs-component.sh classification-form sentiment-form

# 3. Database - Create Supabase schema
bash ../plugins/ml-training/skills/integration-helpers/scripts/create-supabase-schema.sh complete

# 4. Test the system
# Backend: http://localhost:8000/docs
# Frontend: http://localhost:3000/dashboard
```

### Image Classification Service

```bash
# FastAPI image endpoint
bash ./scripts/add-fastapi-endpoint.sh image-classification image-classifier

# Next.js upload component
bash ./scripts/add-nextjs-component.sh image-upload image-classifier-form

# Versioning schema
bash ./scripts/create-supabase-schema.sh model-versions
```

## Script Options

### add-fastapi-endpoint.sh

**Supported Model Types:**
- `classification` - Text/tabular classification with probabilities
- `regression` - Numeric prediction with feature importance
- `text-generation` - LLM text generation
- `image-classification` - Image recognition with multi-class output
- `embeddings` - Vector embeddings generation

**Output:** Creates router in `app/routers/ml_<endpoint-name>.py`

### add-nextjs-component.sh

**Supported Component Types:**
- `classification-form` - Text input with prediction display
- `regression-form` - Numeric input form
- `image-upload` - Image upload with preview
- `chat-interface` - Chat UI for LLM interaction

**Output:** Creates component in `components/ml/<component-name>.tsx`

### create-supabase-schema.sh

**Supported Schema Types:**
- `ml-models` - Model registry with metadata
- `predictions` - Prediction logs
- `training-runs` - Training job tracking
- `model-versions` - Version management
- `complete` - All schemas combined

**Output:** Creates migration in `supabase/migrations/<timestamp>_ml_<schema-type>.sql`

## Requirements

### FastAPI Backend
- FastAPI 0.100+
- Pydantic 2.0+
- Python 3.10+
- scikit-learn / PyTorch / TensorFlow (based on model)

### Next.js Frontend
- Next.js 14+
- React 18+
- TypeScript
- shadcn/ui
- react-hook-form + zod

### Supabase
- PostgreSQL 15+
- Row Level Security
- UUID extension

## Best Practices

### API Design
- Use proper HTTP status codes
- Implement request validation
- Add rate limiting for production
- Log all predictions
- Version your models

### Performance
- Cache models in memory
- Use async endpoints
- Implement batch prediction
- Consider model quantization
- Use background tasks for heavy operations

### Security
- Validate all inputs
- Implement authentication
- Use CORS properly
- Don't expose model internals
- Rate limit inference endpoints

### Monitoring
- Log inference times
- Track prediction distributions
- Monitor error rates
- Store predictions for retraining
- Set up alerts

## Integration with ML Training

This skill complements other ml-training skills:

- **training-accelerators**: Train models that get deployed here
- **model-optimization**: Optimize models before deployment
- **hyperparameter-tuning**: Tune hyperparameters for deployed models

## Skill Metadata

- **Plugin**: ml-training
- **Version**: 1.0.0
- **Category**: ML Integration
- **Skill Type**: Integration Templates
- **Line Count**: 561 lines (SKILL.md)
- **Scripts**: 3 functional bash scripts
- **Templates**: 3 code templates
- **Examples**: 2 complete examples

## Contributing

When extending this skill:

1. Keep SKILL.md focused and concise
2. Add detailed examples to examples/ directory
3. Ensure scripts have proper error handling
4. Test templates with real projects
5. Update README.md with new features

## License

Part of the ml-training plugin for Claude Code.
