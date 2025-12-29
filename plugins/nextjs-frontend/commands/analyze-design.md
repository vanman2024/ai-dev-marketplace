---
description: Analyze website design patterns using Playwright browser automation
argument-hint: <url> [--mobile] [--compare <url2>]
---

---
🚨 **EXECUTION NOTICE FOR CLAUDE**

When you invoke this command via SlashCommand, the system returns THESE INSTRUCTIONS below.

**YOU are the executor. This is NOT an autonomous subprocess.**

- ✅ The phases below are YOUR execution checklist
- ✅ YOU must run each phase immediately using tools (Bash, Read, Write, Edit, TodoWrite, Task)
- ✅ Complete ALL phases before considering this command done
- ❌ DON't wait for "the command to complete" - YOU complete it by executing the phases
- ❌ DON't treat this as status output - it IS your instruction set

---

## Security Requirements

**CRITICAL:** All generated files must follow security rules:

- Never hardcode API keys or secrets
- Use placeholders where needed

**Arguments**: $ARGUMENTS

Goal: Analyze one or more websites to extract design patterns including layout, typography, colors, spacing, and components. Uses Playwright browser automation to navigate and capture screenshots.

## Quick Reference Sites

If user doesn't provide a URL, suggest these top-tier design examples:

**SaaS/Product:**
- `https://linear.app` - Clean, minimal, dark mode
- `https://vercel.com` - Developer-focused, modern
- `https://stripe.com` - Enterprise, trust signals
- `https://notion.so` - Friendly, approachable
- `https://figma.com` - Creative, colorful

**Marketing:**
- `https://apple.com` - Premium, minimal
- `https://airbnb.com` - Photography, warm
- `https://spotify.com` - Bold, colorful

Phase 1: Parse Arguments
Goal: Extract URL(s) and options from arguments

Actions:
- Parse $ARGUMENTS for:
  - Primary URL to analyze
  - `--mobile` flag for mobile-first analysis
  - `--compare <url2>` for comparison analysis
- If no URL provided, ask user to choose from curated list
- Validate URLs are accessible

Phase 2: Launch Browser & Navigate
Goal: Open browser and navigate to target site

Actions:
- Invoke design-patterns-agent for analysis:

Task(description="Analyze website design patterns", subagent_type="nextjs-frontend:design-patterns-agent", prompt="You are the design-patterns-agent with Playwright MCP access. Analyze the design patterns of a website.

**Target URL:** $ARGUMENTS

**Your Tasks:**

1. **Navigate to the site:**
   Use mcp__playwright__playwright_navigate with url: '[extracted URL]'

2. **Capture desktop screenshot:**
   Use mcp__playwright__playwright_screenshot with:
   - name: 'desktop-full'
   - fullPage: true
   - savePng: true

3. **Capture mobile screenshot:**
   Use mcp__playwright__playwright_resize with device: 'iPhone 13'
   Use mcp__playwright__playwright_screenshot with:
   - name: 'mobile-full'
   - fullPage: true

4. **Get page HTML for analysis:**
   Use mcp__playwright__playwright_get_visible_html

5. **Analyze and document:**
   - Layout patterns (header, hero, sections, footer)
   - Typography (fonts, sizes, weights, line-heights)
   - Colors (primary, secondary, neutrals, accents)
   - Spacing (section padding, gaps, max-widths)
   - Components (buttons, cards, forms)

6. **Generate implementation:**
   - Tailwind config with extracted values
   - Example components based on patterns

7. **Close browser:**
   Use mcp__playwright__playwright_close

**Deliverable:** Complete design analysis report with:
- Screenshots (desktop + mobile)
- Pattern documentation
- Tailwind config snippet
- Example component code")

Phase 3: Compare Sites (If --compare flag)
Goal: Analyze second site and compare patterns

Actions:
- If --compare flag present in $ARGUMENTS:
  - Run same analysis on second URL
  - Compare patterns between sites
  - Identify common patterns
  - Note unique differentiators

Phase 4: Generate Report
Goal: Create comprehensive design report

Actions:
- Compile findings into markdown report:

```markdown
# Design Pattern Analysis

## Site: [URL]
**Analyzed:** [Date]

## Screenshots
- Desktop: [screenshot path]
- Mobile: [screenshot path]

## Layout Patterns
[Extracted layout information]

## Typography
[Font families, sizes, weights]

## Color Palette
[Primary, secondary, neutrals, accents]

## Spacing System
[Base unit, section padding, gaps]

## Component Patterns
[Buttons, cards, navigation]

## Tailwind Configuration
\`\`\`typescript
// tailwind.config.ts additions
{
  theme: {
    extend: {
      // Extracted config
    }
  }
}
\`\`\`

## Example Components
[Generated component code]

## Recommendations
[How to apply these patterns]
```

Phase 5: Save & Present
Goal: Save report and present to user

Actions:
- Save report to `docs/design-analysis-[domain].md`
- Display summary of key findings
- Show screenshots inline if possible
- Provide actionable next steps

Display completion:
```
Design Analysis Complete! 🎨
============================

Site: [URL]
Screenshots: Saved to downloads

Key Findings:
- Layout: [summary]
- Typography: [font stack]
- Colors: [primary color]
- Spacing: [base unit]

Report saved to: docs/design-analysis-[domain].md

Next Steps:
1. Review the full report
2. Apply Tailwind config to your project
3. Use example components as starting points
4. Run /build-landing-page to apply patterns
```
