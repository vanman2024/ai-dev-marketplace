---
description: Create new skill(s) using skills-builder agent - analyzes plugin structure or accepts direct specifications (supports parallel creation)
argument-hint: [--analyze <plugin-name>] | [<skill-name> "<description>"] | [<skill-1> "<desc-1>" <skill-2> "<desc-2>" ...]
allowed-tools: Task(*)
---

**Arguments**: $ARGUMENTS

Goal: Create properly structured skill(s) by launching the skills-builder agent

Phase 1: Parse Arguments & Determine Mode

Actions:
- Check if $ARGUMENTS starts with --analyze:
  - If yes: Extract plugin name, set mode to "analyze"
  - If no: Parse arguments to detect multiple skill requests
    - Single skill: <skill-name> "<description>"
    - Multiple skills: <skill-1> "<desc-1>" <skill-2> "<desc-2>" ... (creates in parallel)

Phase 2: Launch Skills Builder Agent(s)

Actions:

**For Single Skill:**
Launch the skills-builder agent to create the skill.

Provide the agent with:
- Full arguments: $ARGUMENTS
- The agent will handle all template loading, analysis, and creation

**For Multiple Skills (3 or more skills):**
Launch multiple skills-builder agents IN PARALLEL (all at once):
- Launch skills-builder agent for skill 1 with: <skill-1> "<desc-1>"
- Launch skills-builder agent for skill 2 with: <skill-2> "<desc-2>"
- Launch skills-builder agent for skill 3 with: <skill-3> "<desc-3>"
- (Continue for all requested skills)

Wait for ALL agents to complete before proceeding.

Phase 3: Summary

Actions:
- Display results from all agents (skill names, locations, validation status)
- Show next steps for using the skills
- If multiple skills created, list all successfully created skills
