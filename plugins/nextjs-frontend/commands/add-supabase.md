---
description: Add Supabase integration to the Next.js project with auth, database client, and types
argument-hint: [--with-auth] [--with-realtime]
---

# Add Supabase

Integrate Supabase into the Next.js project.

**Arguments:** `$ARGUMENTS`

## Execution

Use the supabase-integration-agent to add Supabase:

```
Task("Add Supabase", @supabase-integration-agent, {
  prompt: "Add Supabase integration to this project:
    - Install @supabase/supabase-js and @supabase/ssr (latest versions)
    - Create lib/supabase/client.ts for browser client
    - Create lib/supabase/server.ts for server client
    - Create lib/supabase/middleware.ts for auth middleware
    - Add environment variables to .env.example
    - Generate TypeScript types from schema if available
    - If --with-auth: Add auth helpers and middleware
    - If --with-realtime: Add realtime subscription utilities
    - Follow project structure conventions"
})
```

## After Running

1. Add your Supabase credentials to `.env.local`:
   ```
   NEXT_PUBLIC_SUPABASE_URL=your_project_url
   NEXT_PUBLIC_SUPABASE_ANON_KEY=your_anon_key
   ```

2. Generate types from your database:
   ```bash
   npx supabase gen types typescript --project-id your_project_id > lib/supabase/types.ts
   ```
