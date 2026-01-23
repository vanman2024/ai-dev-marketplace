---
name: add-database
description: Add Supabase database integration
allowed-tools: Task, Bash, Read, Write, Edit, Glob, Grep, TodoWrite, AskUserQuestion
---

# /mobile:add-database

Add Supabase database with real-time and offline support.

## Arguments

$ARGUMENTS - Optional: features (realtime, offline, storage)

## Execution

### Phase 1: Install Dependencies

npx expo install @supabase/supabase-js @react-native-async-storage/async-storage react-native-url-polyfill

### Phase 2: Gather Requirements

Use AskUserQuestion:
- Features: Database, Real-time, Storage, Edge Functions (multiselect)
- Offline support with React Query: Yes/No

### Phase 3: Invoke Database Specialist

Task(description="Setup Supabase", subagent_type="mobile-database-specialist", prompt="Add Supabase to this Expo app:

Features: [from Phase 2]
Offline: [from Phase 2]

Create:
1. lib/supabase.ts with AsyncStorage auth
2. React Query setup if offline selected
3. Example hooks for CRUD operations
4. Real-time subscription hook if selected
5. Storage upload utility if selected
6. .env.example with Supabase placeholders

Use environment variables - NEVER hardcode credentials.")

### Phase 4: Summary

Display:
- Supabase configured
- Features: [list]
- Offline: enabled/disabled
- Next: Add Supabase keys to .env
