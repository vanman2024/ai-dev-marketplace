---
description: Generate new Celery task with retries and validation
argument-hint: task-name
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, TodoWrite
---

**Arguments**: $ARGUMENTS

Goal: Generate a production-ready Celery task with proper error handling, retries, and validation

Core Principles:
- Parse task requirements from $ARGUMENTS
- Delegate specialized task generation to task-generator-agent
- Follow Celery best practices for task configuration
- Ensure proper file structure and imports

Phase 1: Discovery
Goal: Understand task requirements and project structure

Actions:
- Parse $ARGUMENTS to extract task name and any optional parameters
- Detect if Celery is already configured in the project
- Check for existing tasks directory structure
- Example: !{bash find . -name "celery.py" -o -name "tasks.py" 2>/dev/null | head -5}
- Load existing Celery configuration if present

Phase 2: Validation
Goal: Verify Celery setup and task name validity

Actions:
- Confirm Celery is installed and configured
- Validate task name follows Python naming conventions
- Check if task with same name already exists
- Verify tasks directory exists or can be created
- Example: !{bash python -c "import celery; print('Celery installed')" 2>/dev/null}

Phase 3: Context Loading
Goal: Understand existing task patterns

Actions:
- Find and load existing task files for pattern reference
- Example: !{bash find . -name "*tasks*.py" -type f 2>/dev/null | head -3}
- If existing tasks found, load one as reference: @tasks.py
- Note existing retry strategies, error handling patterns
- Identify project-specific task decorators or mixins

Phase 4: Task Generation
Goal: Create production-ready Celery task

Actions:

Task(description="Generate Celery task", subagent_type="celery:task-generator-agent", prompt="You are the task-generator-agent. Generate a production-ready Celery task for $ARGUMENTS.

Context:
- Task name: [parsed from $ARGUMENTS]
- Existing patterns: [identified from Phase 3]
- Project structure: [identified from Phase 1]

Requirements:
- Include proper task decorator with name and configuration
- Add retry logic with exponential backoff
- Implement input validation
- Add comprehensive error handling
- Include docstring with usage examples
- Follow existing project patterns
- Add logging for debugging
- Include type hints if project uses them

Deliverable:
- Complete task function with all imports
- Ready to write to appropriate file location
- Follows Celery best practices")

Phase 5: File Integration
Goal: Write task to correct location

Actions:
- Determine appropriate file location (existing tasks.py or new file)
- Write generated task code to file
- Update imports if needed
- Format code using project formatter if available
- Example: !{bash black tasks.py 2>/dev/null || echo "Skipping formatting"}

Phase 6: Verification
Goal: Validate the generated task

Actions:
- Check Python syntax is valid
- Example: !{bash python -m py_compile [task_file]}
- Verify imports are correct
- Confirm task is registered with Celery
- Run quick smoke test if possible

Phase 7: Summary
Goal: Document what was created

Actions:
- Display task file location
- Show task name and key features
- Explain retry configuration
- Provide usage example
- Suggest next steps:
  - Test the task: celery -A [app] worker --loglevel=info
  - Call the task: task_name.delay(args)
  - Monitor with Flower if available
