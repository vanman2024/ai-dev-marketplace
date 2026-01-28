---
description: Initialize a new Next.js project with TypeScript, Tailwind CSS, and shadcn/ui
argument-hint: <project-name>
---

# Initialize Next.js Project

Create a new Next.js project with the full stack setup.

**Arguments:** `$ARGUMENTS`

## Execution

Use the nextjs-setup-agent to initialize the project:

```
Task("Initialize project", @nextjs-setup-agent, {
  prompt: "Initialize a new Next.js project named '$ARGUMENTS':
    - Run npx create-next-app@latest with App Router
    - Enable TypeScript with strict mode
    - Enable Tailwind CSS (latest version)
    - Enable ESLint
    - Initialize shadcn/ui component library
    - Create proper directory structure:
      - app/ for routes
      - components/ for React components
      - lib/ for utilities
      - hooks/ for custom hooks
    - Set up path aliases (@/ for root imports)
    - Create .env.example with placeholders
    - Configure for production deployment"
})
```

## After Running

1. Navigate to your project:
   ```bash
   cd $ARGUMENTS
   ```

2. Start development server:
   ```bash
   npm run dev
   ```

3. Add integrations as needed:
   ```bash
   /nextjs-frontend:add-supabase
   /nextjs-frontend:add-ai-sdk
   ```
