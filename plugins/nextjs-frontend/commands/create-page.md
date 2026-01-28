---
description: Create a new page in the Next.js application following App Router conventions
argument-hint: <page-path> [--with-loading] [--with-error]
---

# Create Page

Create a new page in the Next.js App Router structure.

**Arguments:** `$ARGUMENTS`

## Execution

Use the page-generator-agent to create the page:

```
Task("Create page", @page-generator-agent, {
  prompt: "Create a new page at '$ARGUMENTS':
    - Follow App Router conventions (app/ directory)
    - Create page.tsx with proper exports
    - Add loading.tsx if --with-loading specified
    - Add error.tsx if --with-error specified
    - Use Server Components by default
    - Follow project design system
    - Import existing components from project"
})
```

## Examples

```bash
/nextjs-frontend:create-page dashboard
/nextjs-frontend:create-page settings/profile --with-loading
/nextjs-frontend:create-page (auth)/login
```
