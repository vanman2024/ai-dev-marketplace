---
description: Add evaluation criteria and testing workflows
argument-hint: <evaluation-type>
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, TodoWrite
---

**Arguments**: $ARGUMENTS

Goal: Add comprehensive evaluation criteria and testing workflows to measure agent performance and quality

Core Principles:
- Understand evaluation requirements before implementing
- Detect existing testing infrastructure
- Follow Google ADK best practices for evaluation
- Provide actionable metrics and reporting

Phase 1: Discovery
Goal: Gather context and requirements

Actions:
- Parse $ARGUMENTS to identify evaluation type (unit tests, integration tests, benchmarks, quality metrics)
- If $ARGUMENTS is unclear, use AskUserQuestion to gather:
  - What aspects need evaluation? (accuracy, latency, cost, safety)
  - What are success criteria?
  - What testing infrastructure exists?
  - Any specific compliance requirements?
- Detect project type and framework:

!{bash ls -la 2>/dev/null | grep -E "package.json|pyproject.toml|requirements.txt"}

- Load relevant configuration files for context:

!{bash find . -maxdepth 3 -name "*.config.*" -o -name "pytest.ini" -o -name "jest.config.*" 2>/dev/null | head -5}

Phase 2: Analysis
Goal: Understand existing codebase and evaluation patterns

Actions:
- Search for existing test files and evaluation code:

!{bash find . -type f \( -name "*test*.py" -o -name "*test*.ts" -o -name "*test*.js" -o -name "*eval*.py" \) 2>/dev/null | head -10}

- Identify agent implementations that need evaluation
- Check for existing evaluation frameworks or tools
- Understand current quality metrics and reporting

Phase 3: Planning
Goal: Design the evaluation approach

Actions:
- Determine evaluation strategy based on requirements:
  - Unit tests for individual components
  - Integration tests for agent workflows
  - Benchmark tests for performance metrics
  - Quality scoring for output evaluation
- Identify what metrics to track (accuracy, latency, cost, safety)
- Plan reporting and visualization approach
- Present evaluation plan to user for confirmation

Phase 4: Implementation
Goal: Execute evaluation setup with specialized agent

Actions:

Task(description="Add evaluation criteria and testing workflows", subagent_type="google-adk-evaluation-specialist", prompt="You are the google-adk-evaluation-specialist agent. Add evaluation criteria and testing workflows for $ARGUMENTS.

Context from Discovery:
- Evaluation type: [from Phase 1]
- Project framework: [detected framework]
- Existing tests: [found test files]
- Success criteria: [from user requirements]

Requirements:
- Implement comprehensive test suites (unit, integration, benchmark)
- Add quality metrics and scoring systems
- Create evaluation reports and visualizations
- Follow Google ADK evaluation best practices
- Ensure tests are maintainable and extensible
- Add CI/CD integration for automated testing

Expected deliverables:
- Test files with comprehensive coverage
- Evaluation scripts and configuration
- Metrics tracking and reporting setup
- Documentation for running evaluations
- CI/CD workflow files if needed")

Phase 5: Verification
Goal: Verify evaluation setup works correctly

Actions:
- Check that test files were created and are valid
- Verify evaluation scripts can run successfully:

!{bash if [ -f "pytest.ini" ]; then python -m pytest --collect-only 2>&1 | head -20; elif [ -f "package.json" ]; then npm test -- --listTests 2>&1 | head -20; fi}

- Confirm metrics are being tracked correctly
- Validate reporting output format
- Test CI/CD integration if applicable

Phase 6: Summary
Goal: Document what was accomplished

Actions:
- Summarize evaluation setup:
  - Test files created and their purpose
  - Metrics being tracked
  - How to run evaluations locally
  - CI/CD integration status
- Highlight key evaluation criteria and success thresholds
- Provide next steps:
  - Run initial evaluation baseline
  - Customize metrics for specific use cases
  - Set up monitoring and alerting
  - Schedule regular evaluation runs
