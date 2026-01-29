---
name: mobile-navigation
description: React Navigation patterns for mobile apps including stack, tab, drawer navigators, deep linking, and typed navigation with TypeScript. Use when building navigation structure, handling deep links, or implementing authentication flows.
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, WebFetch
---

# Mobile Navigation

Comprehensive skill for implementing navigation in React Native/Expo apps.

## Overview

React Navigation provides flexible navigation for mobile:

- Stack, Tab, and Drawer navigators
- Deep linking and universal links
- Type-safe navigation with TypeScript
- Authentication flow handling

## Use When

This skill is automatically invoked when:

- Setting up app navigation structure
- Implementing authentication flows
- Configuring deep linking
- Building complex nested navigators

## Available Scripts

| Script                        | Description                          |
| ----------------------------- | ------------------------------------ |
| `scripts/setup-navigation.sh` | Install navigation dependencies      |
| `scripts/generate-types.sh`   | Generate TypeScript navigation types |

## Available Templates

| Template                        | Description                 |
| ------------------------------- | --------------------------- |
| `templates/root-layout.tsx`     | Root layout with auth flow  |
| `templates/tabs-layout.tsx`     | Tab navigator layout        |
| `templates/navigation-types.ts` | TypeScript type definitions |
| `templates/linking-config.ts`   | Deep linking configuration  |

## Navigation Structure

```
app/
├── _layout.tsx           # Root (auth check)
├── (tabs)/
│   ├── _layout.tsx       # Tab navigator
│   ├── index.tsx         # Home tab
│   └── profile.tsx       # Profile tab
├── auth/
│   ├── login.tsx
│   └── register.tsx
└── [id].tsx              # Dynamic route
```

## Best Practices

1. Use expo-router for file-based routing
2. Keep navigation types in dedicated file
3. Implement auth at root level
4. Configure deep links for both schemes
