---
description: Add cloud GPU platform integration (Modal/Lambda/RunPod)
argument-hint: <modal|lambda|runpod>
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
---

**Arguments**: $ARGUMENTS

Goal: Add cloud GPU platform integration for ML training with authentication setup and test configuration

Core Principles:
- Parse platform choice from arguments
- Install platform-specific SDK
- Configure authentication
- Create GPU image definition
- Verify setup with test script

Phase 1: Parse Platform Choice
Goal: Determine which platform to integrate

Actions:
- Parse $ARGUMENTS to extract platform name (modal, lambda, or runpod)
- If no argument or invalid platform provided:
  - Use AskUserQuestion to ask: "Which cloud GPU platform? (modal/lambda/runpod)"
- Validate platform choice is one of: modal, lambda, runpod
- Convert to lowercase for consistency

Phase 2: Check Existing Setup
Goal: Understand current project structure

Actions:
- Check for existing requirements.txt: @requirements.txt
- Check for existing platform configs:
  - Modal: Look for modal_*.py files
  - Lambda: Look for lambda_config.json
  - RunPod: Look for runpod_config.json
- Detect Python version from runtime files
- Check if platform SDK already installed

Phase 3: Install Platform SDK
Goal: Install correct SDK for chosen platform

Actions:
Install SDK based on platform:
- Modal: !{bash pip install modal}
- Lambda: !{bash pip install lambda-cloud}
- RunPod: !{bash pip install runpod}

Update requirements.txt with SDK entry

Phase 4: Platform Setup and Authentication
Goal: Configure platform authentication

Actions:
Task(description="Setup platform authentication", subagent_type="ml-architect", prompt="You are the ml-architect agent configuring $ARGUMENTS cloud GPU platform.

Based on platform:

**Modal:**
- Run: python3 -m modal setup (interactive auth)
- Guide user through account creation/login
- Saves token to ~/.modal.toml

**Lambda Labs:**
- Create lambda_config.json with api_key, region, instance_type fields
- Instruct: Get API key from https://cloud.lambdalabs.com/api-keys

**RunPod:**
- Create runpod_config.json with api_key, gpu_type, container_disk_size_gb fields
- Instruct: Get API key from https://www.runpod.io/console/user/settings

Complete authentication setup for $ARGUMENTS platform.")

Phase 5: Create Platform Files
Goal: Create GPU image definition and test script

Actions:
Task(description="Create platform integration files", subagent_type="ml-architect", prompt="You are the ml-architect agent. Create GPU platform files for $ARGUMENTS:

**Modal:** Create modal_image.py with:
- modal.Image.debian_slim() with torch, transformers, accelerate
- @stub.function(gpu='A100') training function
- test_platform.py to verify GPU access

**Lambda Labs:** Create lambda_image.py with:
- launch_instance() function for GPU instances
- test_platform.py to verify API connection

**RunPod:** Create runpod_image.py with:
- create_pod() function for GPU pods
- test_platform.py to verify API connection

Include error handling and GPU verification.")

Phase 6: Summary and Next Steps
Goal: Provide user with setup confirmation and usage guide

Actions:
Display summary:
- Platform integrated: [platform name]
- SDK installed: [version]
- Configuration files created
- Image definition ready
- Authentication status: [configured/needs API key]

Next steps:
1. **For Modal**: Run `python test_platform.py` to verify GPU access
2. **For Lambda/RunPod**: Add API key to config file, then test
3. Use platform for training: See docs/[platform]-training.md
4. Estimate costs: Check platform pricing calculator
5. Set up W&B logging: Run `/ml-training:add-tracking wandb`

Important Notes:
- Modal has free tier with GPU credits
- Lambda Labs requires payment for GPU hours
- RunPod bills by the minute for GPU usage
- Always terminate instances after training to avoid charges
- Consider using spot instances for cost savings
