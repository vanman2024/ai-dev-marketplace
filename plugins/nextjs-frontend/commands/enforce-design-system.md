---
description: Enforce design system consistency across Next.js components
argument-hint: [component-path] [--fix]
allowed-tools: Task, Read, Bash, Glob, Grep
---

## Security Requirements

**CRITICAL:** All generated files must follow security rules:

@docs/security/SECURITY-RULES.md

**Key requirements:**
- Never hardcode API keys or secrets
- Use placeholders: `your_service_key_here`
- Protect `.env` files with `.gitignore`
- Create `.env.example` with placeholders only
- Document key acquisition for users

**Arguments**: $ARGUMENTS

Goal: Validate and optionally fix design system compliance across Next.js components using shadcn/ui with Tailwind v4 standards.

Core Principles:
- Validate against mandatory design system constraints (4 font sizes, 2 weights, 8pt grid, 60/30/10 color rule)
- Provide clear violation reports with actionable feedback
- Auto-fix violations when --fix flag is provided
- Ensure all components follow OKLCH color format and accessibility standards

Phase 1: Discovery
Goal: Understand target scope and check for design system configuration

Actions:
- Parse $ARGUMENTS to extract component path and --fix flag
- Check if design system is configured: !{bash test -f .design-system.md && echo "Found" || echo "Not configured"}
- If not configured, warn user to run initialization first
- Determine validation scope (single component or all components)
- Example: !{bash echo "$ARGUMENTS" | grep -q "\-\-fix" && echo "Fix mode enabled" || echo "Validation only"}

Phase 2: Load Design System
Goal: Read current design system configuration

Actions:
- Load design system file: @.design-system.md
- Load validation script for reference
- Identify target components to validate
- If $ARGUMENTS contains specific path, validate that component only
- Otherwise, find all components: !{bash find app/components -name "*.tsx" -o -name "*.jsx" 2>/dev/null || find src/components -name "*.tsx" -o -name "*.jsx" 2>/dev/null}

Phase 3: Validation
Goal: Run comprehensive design system validation

Actions:
- Execute validation script on target components
- Example: !{bash bash plugins/nextjs-frontend/skills/design-system-enforcement/scripts/validate-design-system.sh}
- Capture validation results:
  - Typography violations (>4 font sizes, wrong weights)
  - Spacing violations (not divisible by 8/4)
  - Color distribution violations (>10% accent usage)
  - Custom CSS usage (should use Tailwind)
  - Accessibility issues (missing ARIA labels)
  - Non-shadcn/ui components

Phase 4: Report Generation
Goal: Present clear validation results

Actions:
- Display validation summary with counts:
  - Total components scanned
  - Compliant components
  - Components with violations
  - Breakdown by violation type
- For each violation, show:
  - File path and line number
  - Specific constraint violated
  - Current value vs. expected value
  - Suggested fix

Phase 5: Auto-Fix (Conditional)
Goal: Automatically repair violations if --fix flag provided

Actions:
- Check if --fix flag present in $ARGUMENTS
- If NOT present:
  - Display "Run with --fix flag to auto-repair violations"
  - Show manual fix instructions
  - Exit with validation report
- If --fix flag IS present:
  - Invoke component-builder-agent to fix violations

Task(description="Fix design system violations", subagent_type="component-builder-agent", prompt="You are the component-builder-agent. Fix design system violations in components identified by validation.

Design System Configuration:
@.design-system.md

Violations to Fix:
[Based on validation results from Phase 3]

Fix Requirements:
- Consolidate to 4 font sizes maximum (from .design-system.md)
- Use only Semibold and Regular font weights
- Ensure all spacing divisible by 8 or 4 (use Tailwind classes: p-2, p-4, p-6, p-8, m-2, m-4, gap-2, gap-4, etc.)
- Enforce 60/30/10 color distribution (60% bg-background, 30% text-foreground, 10% bg-primary)
- Replace custom CSS with Tailwind utilities
- Use only shadcn/ui components from @/components/ui/
- Add missing ARIA labels for accessibility
- Convert colors to OKLCH format

Process:
1. Read each violating component
2. Apply fixes following design system constraints
3. Preserve functionality while updating styles
4. Self-validate after each fix
5. Report all changes made

Deliverable: Fixed components passing all design system validation checks")

Phase 6: Re-Validation (If Fixed)
Goal: Verify all violations were resolved

Actions:
- If fixes were applied, re-run validation
- Example: !{bash bash plugins/nextjs-frontend/skills/design-system-enforcement/scripts/validate-design-system.sh}
- Compare before/after results
- Confirm all violations resolved
- If violations remain, report what still needs manual attention

Phase 7: Summary
Goal: Present comprehensive enforcement results

Actions:
- Display final validation status:
  - "All components compliant" or "X violations remaining"
  - Components fixed (if --fix was used)
  - Auto-fixable vs. manual fixes needed
- Show key metrics:
  - Typography compliance: X/Y components
  - Spacing compliance: X/Y components
  - Color distribution compliance: X/Y components
  - Accessibility compliance: X/Y components
- Suggest next steps:
  - If violations remain: "Review manual fixes needed above"
  - If all compliant: "Design system enforcement complete"
  - Recommend running validation in CI/CD pipeline
