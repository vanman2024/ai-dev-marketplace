---
name: responsive-design
description: Responsive design patterns for mobile apps including adaptive layouts, safe areas, screen size handling, and platform-specific styling. Use when building responsive UI or handling different screen sizes.
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, WebFetch
---

# Responsive Design

Comprehensive skill for building responsive layouts in React Native/Expo mobile apps.

## Overview

Mobile responsive design requires:

- Safe area handling (notch, home indicator)
- Screen size adaptation
- Platform-specific styling (iOS vs Android)
- Orientation changes
- Tablet support

## Use When

This skill is automatically invoked when:

- Building responsive layouts
- Handling safe areas
- Supporting multiple screen sizes
- Implementing platform-specific UI

## Available Templates

| Template                       | Description                    |
| ------------------------------ | ------------------------------ |
| `templates/responsive.ts`      | Responsive dimension utilities |
| `templates/safe-view.tsx`      | Safe area wrapper component    |
| `templates/typography.tsx`     | Responsive text components     |
| `templates/platform-styles.ts` | Platform-specific styles       |

## Key Utilities

```typescript
// From templates/responsive.ts
wp(50); // 50% of screen width
hp(25); // 25% of screen height
moderateScale(16); // Scaled font size
isTablet; // Device type detection
```

## Best Practices

1. Always wrap root with SafeAreaProvider
2. Use percentages and flex for layout
3. Follow platform conventions (iOS/Android)
4. Test on both small and large devices
