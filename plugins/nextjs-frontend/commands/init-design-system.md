---
description: Initialize design system interactively with colors, typography, and generate design-system.md
argument-hint: [project-name]
allowed-tools: Read, Write, Edit, Bash, AskUserQuestion, TodoWrite
---

**Arguments**: $ARGUMENTS

Goal: Interactively configure and generate a complete design system with brand colors, typography scale, and OKLCH color variables for shadcn/ui with Tailwind v4.

Core Principles:
- Use AskUserQuestion for interactive design decisions
- Generate design-system.md with user preferences
- Create/update globals.css with OKLCH color variables
- Support both light and dark modes
- Follow 60/30/10 color distribution rule

Phase 0: Check Existing Configuration
Goal: Determine if design system already exists

Actions:
- Create todo list using TodoWrite
- Check for existing design system: !{bash test -f design-system.md && echo "EXISTS" || echo "NOT_FOUND"}
- If exists, warn user and ask to overwrite or exit
- Parse $ARGUMENTS for project name (optional)

Phase 1: Gather Project Information
Goal: Collect basic project details

Actions:
- If project name not in $ARGUMENTS, check package.json: !{bash jq -r '.name // "my-app"' package.json 2>/dev/null || echo "my-app"}
- Ask user to confirm or provide project name

Phase 2: Interactive Color Selection
Goal: Gather brand color preferences from user

Actions:
- Use AskUserQuestion with these questions:
  1. "What is your primary brand color?" - Options: Blue (#3B82F6), Purple (#8B5CF6), Green (#10B981), Orange (#F97316)
  2. "What color scheme do you prefer?" - Options: Neutral, Warm, Cool
  3. "Do you need dark mode support?" - Options: Yes, No

Store selections for Phase 4.

Phase 3: Typography Scale Selection
Goal: Let user choose typography scale

Actions:
- Use AskUserQuestion: "What typography scale do you prefer?"
  - Compact: 12px, 14px, 18px, 24px (Dense UI)
  - Standard: 14px, 16px, 24px, 32px (Balanced)
  - Spacious: 16px, 18px, 30px, 48px (Reading-focused)

Phase 4: Generate Color Variables
Goal: Convert selections to OKLCH color values

Actions:
- Map brand color to OKLCH (Blue→oklch(0.623 0.214 259.815), Purple→oklch(0.558 0.228 293.071), Green→oklch(0.696 0.17 162.48), Orange→oklch(0.705 0.191 47.604))
- Map color scheme to background OKLCH (Neutral→oklch(1 0 0), Warm→oklch(0.995 0.005 85), Cool→oklch(0.995 0.005 240))
- Generate dark mode variants if selected

Phase 5: Generate design-system.md
Goal: Create the design system configuration file

Actions:
- Load template: @~/.claude/plugins/marketplaces/ai-dev-marketplace/plugins/nextjs-frontend/skills/design-system-enforcement/templates/design-system-template.md
- Replace all placeholders with user selections
- Write file: !{Write design-system.md}

Phase 6: Update globals.css
Goal: Add or update CSS color variables

Actions:
- Check if globals.css exists: !{bash find . -name "globals.css" -type f | head -1}
- If exists, update :root and .dark sections with new OKLCH values
- If not exists, create app/globals.css with complete color variable setup
- Include @theme block for Tailwind v4 compatibility

Phase 7: Summary
Goal: Report what was created

Actions:
- Mark all todos complete
- Display configuration summary (project, brand color, scheme, typography, dark mode)
- List files created/updated
- Show next steps: Review design-system.md, Build components with /nextjs-frontend:add-component, Validate with /nextjs-frontend:enforce-design-system
- Remind user of enforced constraints: 4 font sizes, 2 weights, 8pt grid, 60/30/10 colors
