---
name: add-offline
description: Add offline support with data caching and sync
allowed-tools: Task, Bash, Read, Write, Edit, Glob, Grep, TodoWrite, AskUserQuestion
---

# /mobile:add-offline

Add offline-first capabilities with React Query and AsyncStorage.

## Arguments

$ARGUMENTS - Optional: specific features

## Execution

### Phase 1: Install Dependencies

npm install @tanstack/react-query @tanstack/query-async-storage-persister
npx expo install @react-native-async-storage/async-storage @react-native-community/netinfo

### Phase 2: Invoke Mobile Architect

Task(description="Setup offline support", subagent_type="mobile-architect", prompt="Add offline-first capabilities:

Create:
1. lib/queryClient.ts with persistence config
2. hooks/useNetworkStatus.ts for connectivity detection
3. lib/offlineQueue.ts for mutation queuing
4. hooks/useOfflineSync.ts for background sync
5. components/OfflineBanner.tsx for UI indicator
6. hooks/useOptimisticMutation.ts for optimistic updates

Configure:
- 24-hour cache retention
- Offline-first network mode
- Queue processing on reconnect

Update root layout with PersistQueryClientProvider.")

### Phase 3: Summary

Display:
- Offline support enabled
- Features: Query caching, Network detection, Mutation queue, Optimistic updates
- Files created: [list]
