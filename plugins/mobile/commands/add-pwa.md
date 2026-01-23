---
name: add-pwa
description: Convert web app to Progressive Web App
allowed-tools: Task, Bash, Read, Write, Edit, Glob, Grep, TodoWrite, AskUserQuestion
---

# /mobile:add-pwa

Convert Next.js application to a PWA with offline support.

## Arguments

$ARGUMENTS - Optional: specific features

## Execution

### Phase 1: Install Dependencies

npm install next-pwa

### Phase 2: Invoke PWA Specialist

Task(description="Setup PWA", subagent_type="pwa-specialist", prompt="Convert this Next.js app to a PWA:

Create:
1. public/manifest.json with proper icons array
2. next.config.js with next-pwa configuration
3. Workbox runtime caching strategies
4. app/offline/page.tsx for offline fallback
5. hooks/useInstallPrompt.ts for install button
6. components/InstallBanner.tsx
7. Update layout.tsx with PWA meta tags

Configure:
- CacheFirst for images
- NetworkFirst for API calls
- StaleWhileRevalidate for static assets

Include icon sizes: 192x192 and 512x512.")

### Phase 3: Summary

Display:
- PWA configuration complete
- Files: manifest.json, offline page, install hook
- Next: Create icons, build for production, test with Lighthouse
