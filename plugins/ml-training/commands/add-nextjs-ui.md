---
description: Add ML UI components to Next.js frontend
argument-hint: [feature]
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, Skill
---
## Available Skills

This commands has access to the following skills from the ml-training plugin:

- **cloud-gpu-configs**: Platform-specific configuration templates for Modal, Lambda Labs, and RunPod with GPU selection guides
- **cost-calculator**: Cost estimation scripts and tools for calculating GPU hours, training costs, and inference pricing across Modal, Lambda Labs, and RunPod platforms. Use when estimating ML training costs, comparing platform pricing, calculating GPU hours, budgeting for ML projects, or when user mentions cost estimation, pricing comparison, GPU budgeting, training cost analysis, or inference cost optimization.
- **example-projects**: Provides three production-ready ML training examples (sentiment classification, text generation, RedAI trade classifier) with complete training scripts, deployment configs, and datasets. Use when user needs example projects, reference implementations, starter templates, or wants to see working code for sentiment analysis, text generation, or financial trade classification.
- **integration-helpers**: Integration templates for FastAPI endpoints, Next.js UI components, and Supabase schemas for ML model deployment. Use when deploying ML models, creating inference APIs, building ML prediction UIs, designing ML database schemas, integrating trained models with applications, or when user mentions FastAPI ML endpoints, prediction forms, model serving, ML API deployment, inference integration, or production ML deployment.
- **monitoring-dashboard**: Training monitoring dashboard setup with TensorBoard and Weights & Biases (WandB) including real-time metrics tracking, experiment comparison, hyperparameter visualization, and integration patterns. Use when setting up training monitoring, tracking experiments, visualizing metrics, comparing model runs, or when user mentions TensorBoard, WandB, training metrics, experiment tracking, or monitoring dashboard.
- **training-patterns**: Templates and patterns for common ML training scenarios including text classification, text generation, fine-tuning, and PEFT/LoRA. Provides ready-to-use training configurations, dataset preparation scripts, and complete training pipelines. Use when building ML training pipelines, fine-tuning models, implementing classification or generation tasks, setting up PEFT/LoRA training, or when user mentions model training, fine-tuning, classification, generation, or parameter-efficient tuning.
- **validation-scripts**: Data validation and pipeline testing utilities for ML training projects. Validates datasets, model checkpoints, training pipelines, and dependencies. Use when validating training data, checking model outputs, testing ML pipelines, verifying dependencies, debugging training failures, or ensuring data quality before training.

**To use a skill:**
```
!{skill skill-name}
```

Use skills when you need:
- Domain-specific templates and examples
- Validation scripts and automation
- Best practices and patterns
- Configuration generators

Skills provide pre-built resources to accelerate your work.

---



## Security Requirements

**CRITICAL:** All generated files must follow security rules:

@docs/security/SECURITY-RULES.md

**Key requirements:**
- Never hardcode API keys or secrets
- Use placeholders: `your_service_key_here`
- Protect `.env` files with `.gitignore`
- Create `.env.example` with placeholders only
- Document key acquisition for users

**Arguments**: $ARGUMENTS

Goal: Add production-ready ML UI components to Next.js frontend for model predictions, results visualization, and user interaction

Core Principles:
- Detect Next.js project structure before creating components
- Create reusable React components with TypeScript support
- Integrate with ML backend APIs (Modal, FastAPI, or serverless endpoints)
- Handle loading states, errors, and real-time updates
- Follow Next.js App Router patterns

Phase 1: Discovery
Goal: Understand Next.js project structure and feature requirements

Actions:
- Parse $ARGUMENTS for feature type (default: "prediction-form")
- Validate Next.js project: !{bash test -f next.config.js -o -f next.config.mjs -o -f next.config.ts && echo "Next.js detected" || echo "Error: No Next.js project found"}
- Detect structure and TypeScript: !{bash test -d app && echo "App Router" || test -d pages && echo "Pages Router"} | !{bash test -f tsconfig.json && echo "TypeScript" || echo "JavaScript"}
- List existing components: !{bash find . -path ./node_modules -prune -o -path ./components -type f -name "*.tsx" -o -name "*.jsx" 2>/dev/null | grep -v node_modules | head -10}
- Check UI framework: !{bash grep -E "(tailwindcss|shadcn|chakra-ui|mui)" package.json 2>/dev/null}

Phase 2: Backend Detection
Goal: Identify ML inference endpoints to integrate with

Actions:
- Look for API configuration:
  - !{bash grep -r "API_URL\|INFERENCE_URL\|MODEL_ENDPOINT" .env .env.local 2>/dev/null | head -5}
- Check for API client files:
  - !{bash find . -path ./node_modules -prune -o -name "*api*.ts" -o -name "*client*.ts" 2>/dev/null | grep -v node_modules | head -5}
- Detect inference platform:
  - !{bash find . -name "inference_*.py" -o -name "*.modal.py" -o -name "*fastapi*.py" 2>/dev/null | head -3}
- Report detected backend or prompt for endpoint URL

Phase 3: Component Generation
Goal: Create ML UI components with integration-specialist agent

Actions:

Task(description="Generate Next.js ML UI components", subagent_type="integration-specialist", prompt="You are the integration-specialist agent. Generate Next.js ML UI components for $ARGUMENTS.

Feature Type: $ARGUMENTS

Component Requirements:
1. Create ML prediction form component:
   - Input fields for model parameters
   - File upload support (images, text files)
   - Real-time validation
   - Loading states with progress indicators
   - Error handling and user feedback

2. Create results display component:
   - Visualize model predictions
   - Show confidence scores
   - Display generated content (text, images)
   - Support multiple result formats (JSON, tables, charts)
   - Copy/download functionality

3. Create API integration:
   - Client-side API calls using fetch/axios
   - Server actions for App Router (if detected)
   - Request/response type definitions
   - Error handling and retries
   - Loading and error states management

4. Add UI enhancements:
   - Responsive design (mobile, tablet, desktop)
   - Dark mode support
   - Accessibility (ARIA labels, keyboard navigation)
   - Animation and transitions
   - Toast notifications for feedback

5. Integration points:
   - Connect to ML inference endpoints
   - Handle authentication if required
   - Support real-time updates (WebSocket/SSE if applicable)
   - Cache results with React Query or SWR
   - Rate limiting and quota display

Component Structure:
- components/ml/PredictionForm.tsx
- components/ml/ResultsDisplay.tsx
- components/ml/ModelSelector.tsx (if multiple models)
- lib/api/ml-client.ts (API integration)
- types/ml.ts (TypeScript types)
- hooks/usePrediction.ts (custom hook)

Deliverable:
- All component files created in proper directories
- API client with typed endpoints
- Example usage in app/ml/page.tsx or pages/ml.tsx
- README section with component documentation")

Phase 4: Dependencies
Goal: Install required npm packages for ML UI

Actions:
- Check package manager: !{bash test -f pnpm-lock.yaml && echo "pnpm" || test -f yarn.lock && echo "yarn" || echo "npm"}
- Install dependencies: !{bash npm install react-query axios recharts lucide-react --save 2>&1 | tail -5}
- Install dev dependencies: !{bash npm install @types/react-query --save-dev 2>&1 | tail -3}

Phase 5: Configuration
Goal: Set up environment variables and configuration

Actions:
- Create or update .env.local with NEXT_PUBLIC_ML_API_URL, ML_API_KEY, and feature flags
- Update next.config with image domains, API rewrite rules, and environment allowlist
- Create .env.example for documentation

Phase 6: Summary
Goal: Display component creation results and usage instructions

Actions:
- List created files:
  - !{bash find components/ml lib/api types hooks -type f 2>/dev/null | sort}
- Show file sizes:
  - !{bash du -sh components/ml lib/api 2>/dev/null}
- Display summary:
  - Feature: $ARGUMENTS ML UI components
  - Components created: PredictionForm, ResultsDisplay, API client
  - Framework: Next.js [App Router/Pages Router]
  - TypeScript: [Yes/No]
  - Dependencies installed: react-query, axios, recharts
  - Environment: .env.local configured
- Show usage example:
  - "Import: import { PredictionForm } from '@/components/ml/PredictionForm'"
  - "Use in page: <PredictionForm modelEndpoint={ML_API_URL} />"
  - "Access page: http://localhost:3000/ml"
- Next steps:
  - "Configure ML_API_URL in .env.local"
  - "Test components: npm run dev"
  - "Customize styling to match your design system"
  - "Add authentication if ML endpoints require it"
  - "Monitor API usage and add rate limiting UI"
