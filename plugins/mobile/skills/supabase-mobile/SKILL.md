# supabase-mobile

Supabase integration patterns for React Native/Expo apps.

## Contents

- Client configuration with AsyncStorage
- CRUD operations
- Real-time subscriptions
- File storage
- Offline-first patterns

## Usage

Reference this skill when integrating Supabase in mobile apps.

## Key Patterns

### Client Setup
- AsyncStorage for auth persistence
- detectSessionInUrl: false (mobile)
- URL polyfill required

### Queries
- .from().select()
- .insert(), .update(), .delete()
- Typed queries with Database type

### Real-time
- .channel() for subscriptions
- postgres_changes event
- removeChannel cleanup

### Storage
- Base64 upload with decode()
- expo-image-picker integration
- getPublicUrl for display

### Offline
- React Query with persistence
- Optimistic updates
- Mutation queue for sync

## Security

Never expose service role key. Use RLS policies.
