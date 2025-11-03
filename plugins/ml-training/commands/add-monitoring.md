---
description: Add training monitoring and logging (TensorBoard/WandB)
argument-hint: [monitoring-tool] [metrics]
allowed-tools: Task, Read, Write, Edit, Bash, Grep, Glob, AskUserQuestion
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

Goal: Set up comprehensive training monitoring and logging infrastructure using TensorBoard or Weights & Biases (WandB) for ML training workflows

Core Principles:
- Support both TensorBoard and WandB monitoring tools
- Integrate seamlessly with existing training scripts
- Provide real-time metrics visualization
- Enable experiment tracking and comparison

Phase 1: Discovery
Goal: Understand monitoring requirements and current setup

Actions:
- Parse $ARGUMENTS to extract monitoring tool preference and metrics
- If $ARGUMENTS is unclear, use AskUserQuestion to gather:
  - Which monitoring tool? (tensorboard/wandb/both)
  - What metrics to track? (loss/accuracy/lr/custom)
  - Existing training script location?
  - Remote logging needed? (yes/no)
- Check current project structure: !{bash ls -la 2>/dev/null}
- Look for existing training scripts: !{bash find . -name "train*.py" -o -name "*training*.py" 2>/dev/null | head -5}

Phase 2: Environment Check
Goal: Verify dependencies and training framework

Actions:
- Detect ML framework in use
- Check for PyTorch: !{bash pip list | grep -i torch || echo "Not found"}
- Check for TensorFlow: !{bash pip list | grep -i tensorflow || echo "Not found"}
- Check existing monitoring tools: !{bash pip list | grep -E "tensorboard|wandb" || echo "None installed"}
- Load existing training script if found: @train.py (if exists)
- Check for existing monitoring configuration

Phase 3: Configuration Preparation
Goal: Prepare monitoring tool configuration

Actions:
- Based on selected tool, prepare configuration:
  - **TensorBoard**: Set up log directory structure
  - **WandB**: Prepare API key prompt and project settings
- Check for existing logs: !{bash ls -la logs/ runs/ wandb/ 2>/dev/null || echo "No log directories"}
- Verify write permissions: !{bash test -w . && echo "Writable" || echo "Permission issue"}
- Prepare metrics configuration based on user requirements

Phase 4: Monitoring Integration
Goal: Integrate monitoring using specialized agent

Actions:

Task(description="Set up training monitoring", subagent_type="training-monitor", prompt="You are the training-monitor agent. Set up monitoring and logging infrastructure for ML training with $ARGUMENTS.

Monitoring Configuration:
- Tool: [Extracted from arguments or user input]
- Metrics: [Extracted from arguments or user input]
- Training script: [Detected or provided path]
- Framework: [Detected ML framework]

Requirements:
- Install required monitoring libraries (tensorboard and/or wandb)
- Create monitoring configuration file (monitoring_config.json)
- Integrate logging callbacks into training script
- Set up log directory structure (logs/ or wandb/)
- Add metric tracking code for specified metrics
- Configure visualization dashboard settings
- For WandB: Add API key configuration instructions
- For TensorBoard: Create tensorboard launch script

Integration Tasks:
- Add monitoring imports to training script
- Initialize monitoring client (TensorBoard SummaryWriter or wandb.init)
- Add logging callbacks for metrics tracking
- Configure periodic checkpoint logging
- Add visualization for loss curves, accuracy, learning rate
- Set up custom metric tracking if specified
- Test monitoring integration with dummy data

Expected output:
- monitoring_config.json with tool settings
- Updated training script with monitoring integrated
- Launch script (start_tensorboard.sh or wandb_setup.md)
- Quick start guide for using the monitoring tools
- Example commands to view logs and dashboards")

Phase 5: Verification
Goal: Verify monitoring setup is complete

Actions:
- Check monitoring configuration was created: @monitoring_config.json
- Verify training script was updated
- Check for launch scripts: !{bash ls -la start_tensorboard.sh wandb_setup.md 2>/dev/null || echo "Check monitoring files"}
- Test monitoring imports: !{bash python -c "import tensorboard; print('TensorBoard OK')" 2>/dev/null || python -c "import wandb; print('WandB OK')" 2>/dev/null || echo "Verify installation"}
- Verify log directories exist: !{bash ls -la logs/ wandb/ 2>/dev/null || echo "Log directories not yet created"}

Phase 6: Summary
Goal: Report monitoring setup results

Actions:
- Display setup summary:
  - Monitoring tool(s) installed
  - Metrics being tracked
  - Log directory locations
  - Dashboard access instructions
  - Configuration file location
- Provide usage instructions:
  - How to launch monitoring dashboard
  - How to view real-time metrics
  - How to compare experiments
  - How to access remote dashboards (if WandB)
- Suggest next steps:
  - Run training to test monitoring: python train.py
  - View TensorBoard: tensorboard --logdir=logs
  - View WandB: wandb login && check dashboard URL
  - Review monitoring_config.json for customization
