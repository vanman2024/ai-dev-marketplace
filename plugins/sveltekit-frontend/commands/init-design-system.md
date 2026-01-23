---
description: Initialize design system for SvelteKit project with CSS variables, typography, spacing, and color tokens
argument-hint: [project-name] [--brand-color blue|purple|green|red|orange]
allowed-tools: Read, Write, Edit, Bash, AskUserQuestion, TodoWrite
---

**Arguments**: $ARGUMENTS

Goal: Set up a complete design system for a SvelteKit project with CSS variables, enforced typography scale, 8pt grid spacing, and 60/30/10 color distribution.

## Phase 1: Check Existing Setup

Actions:
- Check for existing app.css: `find . -name "app.css" -path "*/src/*" | head -1`
- Check for existing design-system.md: `test -f design-system.md && echo "EXISTS"`
- If design system exists, ask user if they want to overwrite

## Phase 2: Gather Preferences (if not in $ARGUMENTS)

Use AskUserQuestion to gather:

1. **Brand Color** - "What is your primary brand color?"
   - Blue (#3b82f6) - Professional, trust
   - Purple (#8b5cf6) - Creative, premium
   - Green (#10b981) - Growth, success
   - Red (#ef4444) - Bold, urgent
   - Orange (#f59e0b) - Energetic, friendly

2. **Dark Mode** - "Do you need dark mode support?"
   - Yes (recommended)
   - No

## Phase 3: Generate CSS Variables

Based on selections, create/update `src/app.css` with:

```css
:root {
  /* Typography Scale - 4 SIZES ONLY */
  --text-3xl: 2rem;      /* 32px - Size 1: Headings */
  --text-2xl: 1.5rem;    /* 24px - Size 2: Subheadings */
  --text-base: 1rem;     /* 16px - Size 3: Body */
  --text-sm: 0.875rem;   /* 14px - Size 4: Small/Labels */

  /* 60% - Neutral Backgrounds */
  --bg-primary: #f8fafc;
  --bg-secondary: #f1f5f9;
  --bg-card: #ffffff;

  /* 30% - Text Colors */
  --text-primary: #0f172a;
  --text-secondary: #475569;
  --text-muted: #94a3b8;

  /* 10% - Accent (SELECTED_COLOR) */
  --accent-primary: SELECTED_HEX;
  --accent-secondary: SELECTED_SECONDARY;

  /* Supporting */
  --border-color: #e2e8f0;
  --success: #10b981;
  --warning: #f59e0b;
  --error: #ef4444;
  --info: #06b6d4;
  --shadow: rgba(0, 0, 0, 0.1);

  /* Component Tokens */
  --card-bg: var(--bg-card);
  --card-border: var(--border-color);
  --card-radius: 12px;
  --btn-radius: 8px;
  --input-radius: 8px;
}

:root.dark {
  --bg-primary: #0f172a;
  --bg-secondary: #1e293b;
  --bg-card: #1e293b;
  --text-primary: #f1f5f9;
  --text-secondary: #cbd5e1;
  --text-muted: #64748b;
  --border-color: #334155;
  --accent-primary: SELECTED_LIGHT_HEX;
  --accent-secondary: SELECTED_LIGHT_SECONDARY;
  --shadow: rgba(0, 0, 0, 0.3);
  --card-bg: var(--bg-card);
  --card-border: var(--border-color);
}
```

## Phase 4: Generate design-system.md

Create `design-system.md` in project root with:

- Project name and brand color
- Typography rules (4 sizes, 2 weights)
- Spacing rules (8pt grid)
- Color distribution (60/30/10)
- Component standards
- Code examples

Use template: @~/.claude/plugins/marketplaces/ai-dev-marketplace/plugins/sveltekit-frontend/skills/design-system-enforcement/templates/design-system-template.md

## Phase 5: Add Base Styles

Ensure app.css includes base resets and utility classes:

```css
/* Reset */
*, *::before, *::after {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

html {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  font-size: 16px;
  line-height: 1.5;
}

body {
  background: var(--bg-primary);
  color: var(--text-primary);
  min-height: 100vh;
}

/* Typography */
h1, h2, h3, h4 { font-weight: 600; color: var(--text-primary); }
h1 { font-size: var(--text-3xl); }
h2 { font-size: var(--text-2xl); }
h3 { font-size: var(--text-base); font-weight: 600; }

/* Button Base */
.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  padding: 0.5rem 1rem;
  font-size: var(--text-sm);
  font-weight: 500;
  border: none;
  border-radius: var(--btn-radius);
  cursor: pointer;
  transition: all 0.2s;
}

.btn-primary {
  background: var(--accent-primary);
  color: white;
}

.btn-secondary {
  background: var(--bg-secondary);
  color: var(--text-primary);
  border: 1px solid var(--border-color);
}

/* Card Base */
.card {
  background: var(--card-bg);
  border: 1px solid var(--card-border);
  border-radius: var(--card-radius);
  padding: 1.25rem;
}

/* Form Elements */
input, select, textarea {
  font-family: inherit;
  font-size: var(--text-sm);
  padding: 0.5rem 0.75rem;
  background: var(--bg-card);
  color: var(--text-primary);
  border: 1px solid var(--border-color);
  border-radius: var(--input-radius);
}

input:focus, select:focus, textarea:focus {
  outline: none;
  border-color: var(--accent-primary);
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.2);
}
```

## Phase 6: Summary

Display:
```
Design System Initialized!
============================

Project: [name]
Brand Color: [color]
Dark Mode: [yes/no]

Files Created/Updated:
- src/app.css (CSS variables + base styles)
- design-system.md (documentation)

Design Rules Enforced:
- 4 font sizes: 32px, 24px, 16px, 14px
- 2 font weights: 600 (semibold), 400 (regular)
- 8pt grid spacing
- 60/30/10 color distribution

Next Steps:
1. Review design-system.md for component patterns
2. Use /sveltekit-frontend:add-component to create components
3. Run /sveltekit-frontend:enforce-design-system to validate
```
