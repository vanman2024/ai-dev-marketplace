---
name: init
description: Initialize a new React Native/Expo mobile app
allowed-tools: Task, Bash, Read, Write, Edit, Glob, Grep, TodoWrite, AskUserQuestion
---

# /mobile:init

Initialize a new React Native mobile application using Expo.

## Arguments

$ARGUMENTS - Optional project name

## Execution

### Phase 1: Gather Requirements

Use AskUserQuestion:
- Project name (default from $ARGUMENTS or "my-mobile-app")
- Template: tabs (recommended), blank, or drawer
- Integrations: Supabase, Clerk, NativeWind, React Query (multiselect)

### Phase 2: Invoke Expo Specialist

Task(description="Initialize Expo project", subagent_type="expo-specialist", prompt="Create a new Expo project with the following configuration:

Project Name: [from Phase 1]
Template: [selected template]
Integrations: [selected integrations]

Steps:
1. Run npx create-expo-app with selected template
2. Install selected integration packages
3. Create lib/ directory with integration configs
4. Create .env.example with placeholder keys
5. Update .gitignore for mobile development
6. Initialize EAS if user confirms

Use placeholders for all API keys - NEVER hardcode credentials.")

### Phase 3: Summary

Display:
- Project created at: [project name]
- Template: [selected]
- Integrations: [list]
- Next: cd [project], add .env, run npx expo start
