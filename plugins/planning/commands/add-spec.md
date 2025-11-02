---
description: Add single spec to existing project with auto-numbering
argument-hint: <feature-description>
allowed-tools: Task, Read, Write, Bash, Grep, Glob
---

**Arguments**: $ARGUMENTS

Goal: Add a single numbered specification to an existing project with automatic sequential numbering

Core Principles:
- Auto-detect next spec number from existing specs
- Load project context for consistency
- Use single spec-writer agent for generation
- Update project tracking files

Phase 1: Validate Project Setup
Goal: Ensure project has spec infrastructure

Actions:
- Check if specs directory exists
- Example: !{bash test -d specs && echo "Specs directory found" || echo "ERROR: No specs directory. Run /planning:init first"}
- If no specs directory, stop and instruct user to run /planning:init

Phase 2: Determine Next Spec Number
Goal: Find the highest existing spec number and increment

Actions:
- Find all existing numbered specs
- Example: !{bash find specs -maxdepth 1 -name "[0-9][0-9][0-9]-*" -type f 2>/dev/null | sort | tail -1}
- Extract the highest number
- Example: !{bash HIGHEST=$(find specs -maxdepth 1 -name "[0-9][0-9][0-9]-*" -type f 2>/dev/null | sort | tail -1 | grep -oE '^specs/[0-9]+' | grep -oE '[0-9]+'); if [ -z "$HIGHEST" ]; then echo "000"; else echo "$HIGHEST"; fi}
- Calculate next number (N+1) with zero-padding
- Example: !{bash HIGHEST=$(find specs -maxdepth 1 -name "[0-9][0-9][0-9]-*" -type f 2>/dev/null | sort | tail -1 | grep -oE '[0-9]{3}' | head -1); if [ -z "$HIGHEST" ]; then NEXT=1; else NEXT=$((10#$HIGHEST + 1)); fi; printf "%03d" $NEXT}

Phase 3: Load Project Context
Goal: Gather existing project context for consistency

Actions:
- Check if .planning/project-specs.json exists
- If exists, load it: @.planning/project-specs.json
- If not exists, create minimal context structure
- Load project overview if available: @specs/000-project-overview.md (if exists)
- This helps spec-writer maintain consistency with existing specs

Phase 4: Generate New Spec
Goal: Create specification using spec-writer agent

Actions:

Task(description="Generate new spec", subagent_type="spec-writer", prompt="You are the spec-writer agent. Create a detailed specification for: $ARGUMENTS

Context:
- This is spec number: [NEXT_NUMBER from Phase 2]
- Project context: [Loaded from .planning/project-specs.json if available]
- Existing project overview: [From 000-project-overview.md if available]

Requirements:
- Follow the specification template structure
- Use clear, unambiguous language
- Include: Goals, Requirements, Technical Details, Success Criteria
- Be consistent with existing project terminology and patterns
- Format: Markdown with proper headings and structure

Deliverable:
- Write the spec file to: specs/[NEXT_NUMBER]-[feature-slug].md
- Where [feature-slug] is derived from the feature description
- Use kebab-case for the filename
- Return the full path of the created spec file")

Phase 5: Update Project Tracking
Goal: Register new spec in project-specs.json

Actions:
- If .planning/project-specs.json exists, read it: @.planning/project-specs.json
- Add new spec entry with: spec number, feature name, file path, status "draft", created date
- Write updated project-specs.json with new spec entry appended to specs array

Phase 6: Summary
Goal: Report what was created

Actions:
- Display:
  - New spec number
  - New spec file path
  - Feature description
  - Next steps: "Review the spec in specs/[NUMBER]-[SLUG].md"
- Show command to view: `cat specs/[NUMBER]-[SLUG].md`
