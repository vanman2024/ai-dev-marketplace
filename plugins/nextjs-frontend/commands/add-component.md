---
description: Add component with shadcn/ui integration and TypeScript
argument-hint: <component-name>
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, mcp__context7, mcp__shadcn, mcp__tailwind-ui, mcp__figma-application
---

**Arguments**: $ARGUMENTS

Goal: Create a new React component with shadcn/ui integration, TypeScript types, and proper file structure

Core Principles:
- Understand component requirements before building
- Follow Next.js and shadcn/ui conventions
- Use TypeScript for type safety
- Follow existing project patterns

Phase 1: Parse Arguments
Goal: Extract component name from user input

Actions:
- Parse $ARGUMENTS for component name
- Validate component name is in kebab-case or PascalCase
- Example: !{bash echo "$ARGUMENTS" | grep -E '^[a-z-]+$|^[A-Z][a-zA-Z]+$'}

Phase 2: Discovery
Goal: Gather component requirements and understand project structure

Actions:
- Use AskUserQuestion to determine:
  - Component type: UI component, feature component, or layout component?
  - Does it need shadcn/ui primitives (Button, Input, Card, etc.)?
  - Should it be client-side or server component?
  - Any specific props or functionality needed?
- Load Next.js config to understand project setup
- Example: @next.config.js
- Check existing component structure
- Example: !{bash find . -type f -name "*.tsx" -path "*/components/*" | head -5}

Phase 3: Pattern Analysis
Goal: Understand existing component conventions

Actions:
- Read 2-3 existing components to identify patterns
- Check for component directory structure (flat vs nested)
- Identify naming conventions (PascalCase files, index exports)
- Note import patterns and common utilities
- Example: !{bash ls -la app/components/ src/components/ components/ 2>/dev/null | head -20}

Phase 4: Implementation
Goal: Create the component using component-builder-agent

Actions:

Task(description="Build React component", subagent_type="component-builder-agent", prompt="You are the component-builder-agent. Create a new React component for $ARGUMENTS.

Context from Discovery:
- Component name: $ARGUMENTS
- Project type: Next.js with TypeScript
- Available: shadcn/ui primitives, Tailwind CSS
- Component conventions: Follow existing patterns identified

Requirements:
- Create component file with proper TypeScript types
- Use functional component with React.FC or direct typing
- Include Props interface if component accepts props
- Add shadcn/ui components if specified by user
- Follow Next.js 13+ conventions (use client/server directives as needed)
- Include proper imports and exports
- Add JSDoc comments for props
- Follow existing project structure

Deliverable:
- Component file at appropriate location
- Proper TypeScript types
- shadcn/ui integration if needed
- Export statement for easy imports")

Phase 5: Verification
Goal: Verify component was created correctly

Actions:
- Check that component file exists
- Example: !{bash find . -name "*$ARGUMENTS*" -type f 2>/dev/null}
- Run TypeScript type checking if available
- Example: !{bash npm run typecheck 2>/dev/null || npx tsc --noEmit 2>/dev/null || echo "Type check not available"}
- Verify imports resolve correctly
- List component location for user reference

Phase 6: Usage Instructions
Goal: Show user how to use the new component

Actions:
- Display component file path
- Show import statement example
- Provide basic usage example
- Suggest next steps:
  - Add to Storybook if using
  - Create tests
  - Add to component library documentation
  - Integrate into pages/layouts
