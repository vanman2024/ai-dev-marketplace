---
description: Build a complete Claude Code plugin from scratch by orchestrating plugin creation, command building, agent building, and final validation
argument-hint: <plugin-name>
allowed-tools: Task(*), Read(*), Write(*), Bash(*), Glob(*), Grep(*), AskUserQuestion(*), SlashCommand(*), TodoWrite(*)
---

**Arguments**: $ARGUMENTS

Goal: Build a complete, validated Claude Code plugin from scratch by chaining all plugin builder commands and validating the final result.

Core Principles:
- Track progress with TodoWrite throughout the build
- Chain commands sequentially for proper dependencies
- Validate at each major phase
- Ensure 100% compliance before completion

Phase 1: Discovery
Goal: Understand what plugin needs to be built

Actions:
- Create todo list with all build phases using TodoWrite
- Parse $ARGUMENTS for plugin name
- If unclear or no plugin name provided, use AskUserQuestion to gather:
  - What's the plugin name?
  - Plugin type? (SDK, Framework, Custom)
  - For SDK: Which SDK? (Claude Agent SDK, FastMCP, etc.)
  - For Framework: Which framework? (React, Next.js, etc.)
  - Languages supported? (TypeScript, Python, JavaScript)

Phase 2: Create Plugin Scaffold
Goal: Build initial plugin structure

Actions:

Invoke the plugin-create command to scaffold the plugin.

SlashCommand: /domain-plugin-builder:plugin-create $ARGUMENTS

This will:
- Create plugin directory structure
- Generate plugin.json manifest
- Create root files (README, LICENSE, etc.)
- Build initial commands and agents
- Run initial validation

Wait for plugin-create to complete before proceeding.

Update TodoWrite to mark plugin scaffold complete.

Phase 3: Verify Plugin Structure
Goal: Ensure plugin was created correctly

Actions:

Check that plugin exists and has basic structure:
- Verify directory: plugins/$ARGUMENTS exists
- Verify plugin.json exists
- List created commands and agents

If any issues found, stop and report errors.

Update TodoWrite to mark verification complete.

Phase 4: Final Validation
Goal: Comprehensive validation of entire plugin

Actions:

Invoke the plugin-validator agent to validate plugins/$ARGUMENTS

The agent should:
- Run all validation scripts (validate-all.sh)
- Check command compliance
- Check agent compliance
- Verify documentation quality
- Check template adherence
- Validate framework conventions
- Output comprehensive report with Overall Status: PASS/FAIL/PASS WITH WARNINGS

Wait for agent to complete and return its report.

Read the agent's validation report output.

Parse the report for validation status:
- Look for "Overall Status: PASS" → Validation successful, continue to Phase 5
- Look for "Overall Status: FAIL" → Validation failed, need to fix issues
- Look for "Overall Status: PASS WITH WARNINGS" → Acceptable, continue with warnings

If validation status is FAIL:
- Read the "Critical Issues" and "Warnings" sections from report
- Identify auto-fixable issues:
  - Line length problems → Trim descriptions
  - ARGUMENTS usage errors → Replace numbered args with $ARGUMENTS
  - Missing @ symbols → Add @ prefix to file loading
  - Missing frontmatter fields → Add required fields
- Show issues to user
- Use AskUserQuestion: "Auto-fix common issues or manual fix?"
- If auto-fix selected:
  - Apply fixes using Edit tool based on issues in report
  - Re-invoke plugin-validator agent on plugins/$ARGUMENTS
  - Wait for new report
  - Parse new report status
  - Loop until Overall Status is PASS or PASS WITH WARNINGS
- If manual fix selected:
  - Show detailed errors from report
  - Pause for user to fix manually
  - After user confirms fixes, re-invoke validator

Continue looping until Overall Status: PASS or PASS WITH WARNINGS achieved.

Update TodoWrite to mark validation complete.

Phase 5: Summary
Goal: Document what was built

Actions:
- Mark all todos as complete using TodoWrite
- Display comprehensive summary:
  - Plugin name and type
  - Location: plugins/$ARGUMENTS
  - Components created:
    * X commands
    * Y agents
    * Z skills (if any)
  - Validation status: ✅ ALL PASSED
  - Plugin manifest: .claude-plugin/plugin.json
  - Documentation: README.md
- Show next steps:
  - Test plugin commands
  - Deploy to marketplace
  - Create additional features
- Report format: Plugin name, type, location, component counts, validation status, next steps
