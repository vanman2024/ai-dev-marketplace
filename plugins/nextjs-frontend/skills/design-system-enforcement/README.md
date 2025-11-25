# Design System Enforcement Skill

This skill provides mandatory design system guidelines that ALL agents must follow when creating components, pages, or any UI elements in Next.js projects.

## Purpose

Ensures 100% consistency across:

- Typography (4 sizes, 2 weights only)
- Spacing (8pt grid system)
- Colors (60/30/10 rule)
- Component architecture (shadcn/ui + Tailwind v4)

## Files

- `design-system-template.md` - Template with placeholders for project-specific configuration
- `setup-design-system.sh` - Script to generate configured design system guidelines from template
- `example-design-system.md` - Example of a fully configured design system for reference

## Usage

### During Project Initialization

Run the setup script to create project-specific design system guidelines:

```bash
./plugins/nextjs-frontend/skills/design-system-enforcement/setup-design-system.sh
```

This will:

1. Ask for project configuration (brand color, font sizes, etc.)
2. Generate `design-system.md` in the project root
3. Configure it based on conversation with the agent

### During Development

All agents MUST:

1. Read `design-system.md` before creating ANY UI
2. Validate all code against the design system checklist
3. Reject any violations

## Integration with Commands

The following commands automatically enforce design system:

- `add-page.md` - Reads design system before generating pages
- `add-component.md` - Reads design system before generating components
- `init.md` - Runs setup script during project initialization
