---
description: Build complete Clerk authentication - initializes if needed, then runs specialized agents for auth, organizations, OAuth, and framework integration
argument-hint: <project-name> [--framework <nextjs-app|nextjs-pages>]
---

# Build Complete Clerk Authentication

**Goal:** Create a production-ready Clerk authentication system by orchestrating all specialized agents.

**This command handles everything** - from setup to full integration with auth, organizations, OAuth providers, and MFA.

## Stack (Always Use Latest Versions)

- **Clerk** - Latest SDK and dashboard features
- **@clerk/nextjs** / **@clerk/clerk-sdk-node** - Latest packages
- Framework-appropriate middleware

**IMPORTANT:** Always use the latest Clerk SDK versions. Check npm for current versions.

## Arguments

- `$ARGUMENTS` - Project name and optional framework
- `--framework <name>` - Target framework (nextjs-app, nextjs-pages)

## Execution Flow

### Phase 1: Discovery & Planning

**Actions:**

1. Parse `$ARGUMENTS` for project name and framework
2. Auto-detect Next.js router type (App Router vs Pages)
3. Discover architecture documentation for auth requirements
4. Plan auth features based on use cases

### Phase 2: Clerk Setup

```
Task("Initialize Clerk", @clerk-setup-agent, {
  prompt: "Initialize Clerk authentication:
    - Install @clerk/nextjs (latest)
    - Configure environment variables
    - Set up ClerkProvider
    - Create middleware configuration
    Detect router type and configure appropriately."
})
```

### Phase 3: Parallel Agent Execution

```
// Agent 1: Core Authentication
Task("Build auth flow", @clerk-auth-builder, {
  prompt: "Implement core authentication:
    - Sign in/sign up flows
    - User profile management
    - Session handling
    - Protected routes
    Follow auth requirements from architecture."
})

// Agent 2: App Router Integration (if applicable)
Task("Integrate App Router", @clerk-nextjs-app-router-agent, {
  prompt: "Configure for Next.js App Router:
    - Set up auth() and currentUser()
    - Configure server components
    - Add route protection middleware
    - Implement server actions with auth
    Use latest App Router patterns."
})

// Agent 3: Organization Support (if needed)
Task("Build organizations", @clerk-organization-builder, {
  prompt: "Implement organization features if specified:
    - Multi-tenant architecture
    - Organization switching
    - Role-based permissions
    - Member management
    Skip if no org features in architecture."
})

// Agent 4: OAuth Configuration (if needed)
Task("Configure OAuth", @clerk-oauth-specialist, {
  prompt: "Set up OAuth providers if specified:
    - Configure social logins (Google, GitHub, etc.)
    - Set up enterprise SSO
    - Handle OAuth callbacks
    - Implement account linking
    Follow provider requirements from architecture."
})

// Agent 5: MFA Setup (if needed)
Task("Setup MFA", @clerk-mfa-specialist, {
  prompt: "Implement MFA if specified:
    - Configure 2FA options (TOTP, SMS)
    - Add backup codes
    - Implement MFA enrollment flow
    - Handle MFA challenges
    Skip if no MFA in architecture."
})

// Agent 6: UI Customization
Task("Customize UI", @clerk-ui-customizer, {
  prompt: "Customize Clerk UI components:
    - Apply brand colors/theme
    - Customize sign-in appearance
    - Style user button/profile
    - Add custom fields if needed
    Match design system from architecture."
})
```

### Phase 4: Validation

```
Task("Validate setup", @clerk-validator, {
  prompt: "Validate Clerk implementation:
    - Check environment variables
    - Verify middleware configuration
    - Test protected routes
    - Validate OAuth providers
    Report any issues."
})
```

### Phase 5: Final Output

**Provide summary:**
- Auth features implemented
- OAuth providers configured
- Test commands:
  ```bash
  # Start development
  npm run dev
  
  # Test protected route
  curl localhost:3000/api/protected -H "Authorization: Bearer $TOKEN"
  ```

## Utility Commands

- `/clerk:add-auth` - Basic auth only
- `/clerk:add-organizations` - Add org support
- `/clerk:add-oauth` - Add OAuth providers
- `/clerk:add-mfa` - Add multi-factor auth
- `/clerk:add-supabase` - Integrate with Supabase
