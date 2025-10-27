---
description: Create new skill using skills-builder agent - analyzes plugin structure or accepts direct specifications
argument-hint: [--analyze <plugin-name>] | [<skill-name> "<description>"]
allowed-tools: Task(*)
---

**Arguments**: $ARGUMENTS

Goal: Create a properly structured skill by delegating to the skills-builder agent

Phase 1: Parse Arguments & Determine Mode

Actions:
- Check if $ARGUMENTS starts with --analyze:
  - If yes: Extract plugin name, set mode to "analyze"
  - If no: Extract skill name and description, set mode to "create"

Phase 2: Invoke Skills Builder Agent

Actions:

Invoke the skills-builder agent to create the skill.

Provide the agent with:
- Full arguments: $ARGUMENTS
- The agent will handle all template loading, analysis, and creation

Phase 3: Summary

Actions:
- Display results from agent (skill name, location, validation status)
- Show next steps for using the skill
