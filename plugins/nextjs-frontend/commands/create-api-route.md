---
description: Create a new API route handler in the Next.js app/api directory
argument-hint: <route-path> [--method GET|POST|PUT|DELETE]
---

# Create API Route

Create a new API route handler following Next.js conventions.

**Arguments:** `$ARGUMENTS`

## Execution

Use the api-route-generator-agent to create the route:

```
Task("Create API route", @api-route-generator-agent, {
  prompt: "Create a new API route at '$ARGUMENTS':
    - Create in app/api/ directory
    - Generate route.ts with proper exports
    - Include request validation with Zod
    - Add proper error handling
    - Type request/response with TypeScript
    - Follow RESTful conventions
    - If --method specified, only create that handler"
})
```

## Examples

```bash
/nextjs-frontend:create-api-route users
/nextjs-frontend:create-api-route users/[id] --method GET
/nextjs-frontend:create-api-route auth/login --method POST
```
