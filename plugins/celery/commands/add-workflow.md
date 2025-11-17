---
description: Create task workflows (chains, groups, chords)
argument-hint: [workflow-type or description]
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, TodoWrite
---

**Arguments**: $ARGUMENTS

Goal: Design and implement Celery task workflows using Canvas primitives (chains, groups, chords) for orchestrating distributed task execution.

Core Principles:
- Understand workflow requirements before implementing
- Use appropriate Canvas primitives (chain, group, chord)
- Implement proper error handling and retry strategies
- Follow Celery Canvas best practices
- Ask clarifying questions when workflow requirements are unclear

Phase 1: Discovery
Goal: Understand project structure and workflow requirements

Actions:
- Parse $ARGUMENTS for workflow type or description
- Detect existing Celery tasks in project
- Example: !{bash find . -name "*tasks.py" -o -name "celery.py" 2>/dev/null | head -10}
- Identify task definitions that will be used in workflow

If $ARGUMENTS is unclear or insufficient, use AskUserQuestion to gather:
- What is the workflow goal (ETL pipeline, map-reduce, batch processing)?
- Are tasks sequential (chain), parallel (group), or map-reduce (chord)?
- What tasks need to be orchestrated?
- What error handling strategy is needed?
- Should results be aggregated?

Phase 2: Task Analysis
Goal: Analyze existing tasks and determine workflow pattern

Actions:
- Search for task definitions in project
- Example: !{bash grep -r "@.*task" --include="*tasks.py" . | head -20}
- Load relevant task files for context
- Understand task signatures and parameters
- Determine workflow pattern based on requirements:
  - Chain: Sequential tasks where output flows to next task
  - Group: Independent parallel tasks
  - Chord: Parallel tasks with result aggregation (map-reduce)
  - Nested: Complex workflows combining multiple patterns

Phase 3: Workflow Design
Goal: Design workflow structure and Canvas composition

Actions:
- Outline workflow structure and task flow
- Identify data dependencies between tasks
- Plan error handling strategy (link_error, retries, fallbacks)
- Determine result backend requirements
- Present design to user with explanation of Canvas primitives chosen
- Confirm approach before implementation

Phase 4: Implementation
Goal: Generate workflow code using workflow-specialist agent

Actions:

Task(description="Implement Celery workflow", subagent_type="celery:workflow-specialist", prompt="You are the workflow-specialist agent. Create Celery workflow for $ARGUMENTS.

Workflow Requirements:
- Pattern: [chain/group/chord based on Phase 2 analysis]
- Tasks to orchestrate: [list from task analysis]
- Error handling: [strategy from user requirements]
- Result aggregation: [if applicable for chords]

Implementation Requirements:
- Use appropriate Canvas primitives (chain, group, chord)
- Implement immutable signatures
- Add error handling with link_error or retries
- Include result aggregation logic if chord pattern
- Add workflow testing code
- Follow Celery Canvas best practices
- Include comments explaining workflow structure

Expected Output:
- Complete workflow implementation file
- Error handling and retry logic
- Test workflow function
- Documentation of workflow behavior")

Phase 5: Verification
Goal: Validate workflow implementation

Actions:
- Review generated workflow code
- Verify Canvas primitive usage is correct
- Check error handling implementation
- Validate workflow syntax
- Example: !{bash python -m py_compile workflows.py 2>&1}
- Run basic workflow tests if available
- Example: !{bash python -m pytest tests/test_workflows.py -v 2>&1 || echo "No tests found"}

Phase 6: Summary
Goal: Document workflow creation and provide usage guidance

Actions:
- Summarize workflow created:
  - Workflow pattern used (chain/group/chord)
  - Tasks orchestrated
  - Error handling strategy
  - Files created/modified
- Provide workflow usage examples
- Suggest next steps:
  - Run workflow with sample data
  - Add monitoring and observability
  - Optimize task granularity if needed
  - Set up result backend if using chords
