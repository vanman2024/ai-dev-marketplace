---
name: add-auth
description: Add Clerk authentication to the mobile app
allowed-tools: Task, Bash, Read, Write, Edit, Glob, Grep, TodoWrite, AskUserQuestion
---

# /mobile:add-auth

Add Clerk authentication with sign-in, sign-up, and OAuth.

## Arguments

$ARGUMENTS - Optional: specific auth features

## Execution

### Phase 1: Check Dependencies

Verify @clerk/clerk-expo is installed.
If not, install: npx expo install @clerk/clerk-expo expo-secure-store expo-web-browser expo-linking

### Phase 2: Gather Requirements

Use AskUserQuestion:
- OAuth providers: Google, Apple, GitHub, or None (multiselect)
- Include biometrics: Yes/No

### Phase 3: Invoke Auth Specialist

Task(description="Setup Clerk auth", subagent_type="mobile-auth-specialist", prompt="Add Clerk authentication to this Expo app:

OAuth Providers: [from Phase 2]
Biometrics: [from Phase 2]

Create:
1. lib/tokenCache.ts for SecureStore
2. ClerkProvider in root layout
3. (auth) route group with sign-in/sign-up screens
4. OAuth button components if selected
5. Protected route wrapper for (tabs)
6. .env.example with EXPO_PUBLIC_CLERK_PUBLISHABLE_KEY placeholder

NEVER hardcode any API keys.")

### Phase 4: Summary

Display:
- Clerk auth configured
- OAuth providers: [list]
- Files created: [list]
- Next: Add Clerk key to .env
