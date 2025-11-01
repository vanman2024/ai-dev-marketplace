# Next.js Frontend Plugin Hooks

This directory contains lifecycle hooks for the nextjs-frontend plugin.

## Available Hooks

### `pre-commit.sh`

Runs before git commits to validate design system compliance.

**When it runs:** Before each git commit
**What it checks:**
- Design system consistency
- Component naming conventions
- Tailwind CSS usage
- shadcn/ui integration
- TypeScript compliance

**To bypass:** Use `git commit --no-verify` (not recommended)

### `post-component-add.sh`

Runs after adding new components to enforce design system.

**When it runs:** After `/nextjs-frontend:add-component` command
**What it checks:**
- New component follows design guidelines
- Proper shadcn/ui usage
- Tailwind CSS best practices

**Usage:** Automatically called by add-component command

## Installation

To install hooks in your project:

```bash
# From your Next.js project root
cp path/to/plugin/hooks/pre-commit.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

# Or use the setup script
bash path/to/plugin/scripts/setup-hooks.sh
```

## Hook Configuration

Hooks can be configured via `.design-system.md` in your project root.

## Disabling Hooks

To temporarily disable hooks:

```bash
# Skip pre-commit hook
git commit --no-verify

# Disable globally (not recommended)
git config core.hooksPath /dev/null
```
