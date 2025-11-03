---
description: Optimize training settings for cost and speed
argument-hint: [config-path]
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep
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

Goal: Optimize ML training configuration for cost efficiency and training speed by tuning batch size, mixed precision, gradient accumulation, and other performance settings.

Core Principles:
- Analyze before optimizing: Understand current configuration
- Balance cost and performance: Find optimal trade-offs
- Preserve model quality: Don't sacrifice accuracy for speed
- Validate changes: Ensure configurations are valid

Phase 1: Discovery
Goal: Locate and validate training configuration

Actions:
- Parse $ARGUMENTS for config file path
- If no path provided, search for common config files:
  !{bash find . -maxdepth 3 -type f \( -name "train*.py" -o -name "train*.yaml" -o -name "train*.json" -o -name "config*.yaml" \) 2>/dev/null | head -10}
- Verify config file exists
- Load current configuration: @$ARGUMENTS

Phase 2: Analysis
Goal: Understand current training setup and identify optimization opportunities

Actions:
- Extract key training parameters from config:
  - Batch size
  - Learning rate
  - Precision settings (fp32, fp16, bf16)
  - Gradient accumulation steps
  - Number of GPUs/devices
  - Model architecture details
- Identify GPU/accelerator type if specified
- Calculate current estimated training time and cost

Phase 3: Optimization Planning
Goal: Determine optimal settings based on hardware and model

Actions:

Task(description="Optimize training configuration", subagent_type="cost-optimizer", prompt="You are the cost-optimizer agent. Analyze and optimize the training configuration at: $ARGUMENTS

Current Configuration Context:
- Review the existing training configuration
- Identify batch size, precision, gradient accumulation settings
- Understand hardware constraints and model size

Optimization Tasks:
1. **Batch Size Optimization**:
   - Calculate optimal batch size for available GPU memory
   - Consider gradient accumulation for larger effective batch sizes
   - Balance throughput vs memory usage

2. **Mixed Precision Optimization**:
   - Recommend fp16, bf16, or fp32 based on model and hardware
   - Enable automatic mixed precision (AMP) if beneficial
   - Consider gradient scaling for numerical stability

3. **Gradient Accumulation**:
   - Calculate optimal accumulation steps
   - Balance effective batch size with training speed
   - Recommend micro-batch strategies

4. **Additional Optimizations**:
   - Enable gradient checkpointing if memory-constrained
   - Optimize data loading (num_workers, pin_memory, prefetch)
   - Suggest compile optimizations (torch.compile, CUDA graphs)
   - Recommend distributed training strategies if multi-GPU

5. **Cost-Speed Trade-offs**:
   - Estimate training time with new settings
   - Calculate cost savings vs baseline
   - Provide multiple configuration tiers (balanced, fast, economical)

Expected Output:
- Updated configuration file with optimized settings
- Detailed optimization report showing:
  - Changes made to each parameter
  - Expected speedup and cost savings
  - Trade-offs and recommendations
  - Validation steps to verify improvements")

Phase 4: Validation
Goal: Verify optimized configuration is valid and ready to use

Actions:
- Check that updated config file exists
- Verify syntax is correct (YAML/JSON/Python parsing)
- Confirm all required parameters are present
- Run basic validation if training script has a --validate flag:
  !{bash python $ARGUMENTS --validate 2>&1 || echo "No validation mode available"}

Phase 5: Summary
Goal: Report optimization results and next steps

Actions:
- Display optimization summary:
  - Configuration file location
  - Key changes made (batch size, precision, etc.)
  - Expected performance improvements
  - Estimated cost savings
- Recommend next steps:
  - Test with small dataset to validate settings
  - Monitor GPU memory usage during initial runs
  - Adjust if needed based on actual performance
  - Consider A/B testing configurations
- Provide command to start training with optimized config
