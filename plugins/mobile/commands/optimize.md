---
name: optimize
description: Optimize mobile app performance
allowed-tools: Task, Bash, Read, Write, Edit, Glob, Grep, TodoWrite, AskUserQuestion
---

# /mobile:optimize

Optimize React Native/Expo app performance.

## Arguments

$ARGUMENTS - Optional: focus area (bundle, lists, images, memory)

## Execution

### Phase 1: Gather Focus Areas

Use AskUserQuestion:
- Areas: Bundle size, List performance, Images, Re-renders (multiselect)

### Phase 2: Invoke Mobile Architect

Task(description="Optimize performance", subagent_type="mobile-architect", prompt="Optimize this Expo app for performance:

Focus: [from Phase 1]

Create/Update:
1. For bundle: babel.config.js with tree shaking, metro.config.js optimizations
2. For lists: components/OptimizedList.tsx using FlashList
3. For images: components/OptimizedImage.tsx using expo-image
4. For re-renders: hooks/useMemoizedCallback.ts, memo examples
5. components/PerformanceMonitor.tsx (dev only)

Install as needed: @shopify/flash-list, expo-image

Provide before/after metrics guidance.")

### Phase 3: Summary

Display:
- Optimizations applied: [list]
- Components created: [list]
- Next: Profile with React DevTools, replace FlatList with FlashList
