---
description: Create a new React component with shadcn/ui, TypeScript, and Tailwind CSS
argument-hint: <component-name> [--client] [--server]
---

# Create Component

Create a new React component following project conventions.

**Arguments:** `$ARGUMENTS`

## Execution

Use the component-builder-agent to create the component:

```
Task("Create component", @component-builder-agent, {
  prompt: "Create a new component named '$ARGUMENTS':
    - Place in components/ directory (or subdirectory based on type)
    - Use TypeScript with proper props interface
    - Use shadcn/ui primitives where applicable
    - Style with Tailwind CSS following design system
    - Default to Server Component unless --client specified
    - Add 'use client' directive if --client specified
    - Follow project naming conventions"
})
```

## Examples

```bash
/nextjs-frontend:create-component UserCard
/nextjs-frontend:create-component forms/LoginForm --client
/nextjs-frontend:create-component layout/Sidebar
```
