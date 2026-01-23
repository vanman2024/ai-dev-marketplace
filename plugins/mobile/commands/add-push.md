---
name: add-push
description: Add push notification support using Expo Notifications
allowed-tools: Task, Bash, Read, Write, Edit, Glob, Grep, TodoWrite, AskUserQuestion
---

# /mobile:add-push

Add push notifications with Expo Notifications.

## Arguments

$ARGUMENTS - Optional: backend type (supabase, custom)

## Execution

### Phase 1: Install Dependencies

npx expo install expo-notifications expo-device expo-constants

### Phase 2: Invoke Expo Specialist

Task(description="Setup push notifications", subagent_type="expo-specialist", prompt="Add push notifications to this Expo app:

Create:
1. lib/notifications.ts with:
   - registerForPushNotifications function
   - schedulePushNotification utility
   - Notification handler configuration
2. hooks/usePushNotifications.ts with:
   - Token registration
   - Notification listeners
   - Response handling
3. Update app.json with expo-notifications plugin
4. SQL migration for push_tokens table (Supabase)

Configure Android notification channel.
Use expo-device to check for physical device.")

### Phase 3: Summary

Display:
- Push notifications configured
- Files: lib/notifications.ts, hooks/usePushNotifications.ts
- App.json updated with notification plugin
- Next: Add to root layout, configure EAS project ID
