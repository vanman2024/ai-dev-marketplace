---
description: Initialize ML training project with cloud GPU setup
argument-hint: [project-name]
allowed-tools: Task, Read, Write, Bash, Glob, Grep, AskUserQuestion, SlashCommand, Skill
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

Goal: Set up complete ML training project with Python environment, cloud GPU configuration, and proper directory structure optimized for Modal/cloud execution

Core Principles:
- Verify foundation tools first (Python, pip) using /foundation commands
- Lightweight local dependencies (Modal CLI, datasets, supabase)
- Heavy ML dependencies (torch, transformers) run on cloud GPU only
- Clear separation between local and cloud environments

## Phase 1: Foundation Verification

Goal: Ensure Python and required tools are available

Actions:
- Parse $ARGUMENTS for project name (default: current directory name)
- Run /foundation:detect to identify Python in project
- Run /foundation:env-check to validate Python 3.9+ installed
- If Python missing, report installation instructions and exit
- Detect OS for environment activation: !{bash uname -s}

## Phase 2: Environment Setup

Goal: Create .env file and virtual environment

Actions:
- Run /foundation:env-vars generate to create .env with:
  - MODAL_TOKEN_ID, MODAL_TOKEN_SECRET
  - ANTHROPIC_API_KEY, SUPABASE_URL, SUPABASE_ANON_KEY
  - HUGGINGFACE_TOKEN, WANDB_API_KEY
- Check if venv exists: !{bash test -d venv && echo "exists" || echo "none"}
- If exists, ask user: Use existing, Delete and recreate, or Skip
- Create venv: !{bash python3 -m venv venv}
- Upgrade pip: !{bash ./venv/bin/pip install --upgrade pip}
- Report activation command: Windows vs Linux/Mac

## Phase 3: Dependencies

Goal: Install lightweight local tools (NO heavy ML libraries)

Actions:
- Create requirements-local.txt with Modal CLI, datasets, supabase, wandb, python-dotenv, tqdm
- Install: !{bash ./venv/bin/pip install -r requirements-local.txt}
- Create requirements-gpu.txt with torch, transformers, accelerate, bitsandbytes, peft, trl (cloud only)
- Report: "Local tools installed. GPU libraries install on Modal cloud."

## Phase 4: Project Structure

Goal: Create ML-specific directories and configuration

Actions:
- Create directories:
  - !{bash mkdir -p data/raw data/processed data/cache}
  - !{bash mkdir -p models/checkpoints models/final}
  - !{bash mkdir -p logs/training logs/evaluation}
  - !{bash mkdir -p scripts notebooks}
- Create .gitignore with patterns for: venv/, .env, data/*, models/*, logs/*, __pycache__/, .ipynb_checkpoints/, .modal_cache/, wandb/
- Create README.md with:
  - Setup instructions (activate venv, configure .env, authenticate Modal)
  - Directory structure explanation
  - Running training: modal run scripts/train.py
  - Local vs Cloud dependencies distinction

## Phase 5: Summary

Goal: Display setup completion and next steps

Actions:
- Show summary:
  - Project: $ARGUMENTS initialized for ML training
  - Python: {version} detected
  - Virtual environment: Created at ./venv
  - Local dependencies: Modal CLI, datasets, supabase installed
  - GPU dependencies: Ready for cloud execution
  - Directories: data/, models/, logs/, scripts/, notebooks/
  - Environment: .env generated (fill in API keys)
- Next steps:
  1. Activate venv: source venv/bin/activate (Linux/Mac) or venv\Scripts\activate (Windows)
  2. Fill in .env file with API keys
  3. Authenticate Modal: modal token new
  4. Test setup: modal app list
  5. Create training script in scripts/train.py
  6. Run on cloud GPU: modal run scripts/train.py
- Warnings:
  - Do NOT install torch/transformers locally
  - Add large data files to .gitignore
  - Never commit .env file
