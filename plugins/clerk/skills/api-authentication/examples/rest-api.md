# REST API with Clerk Authentication

Complete Express REST API implementation with Clerk authentication middleware.

## Overview

This example demonstrates:
- Public routes (no authentication)
- Optional authentication (works with or without tokens)
- Protected routes (requires authentication)
- Role-based access control (admin only routes)
- Webhook handling for Clerk events

## Implementation

### 1. Server Setup

```typescript
import express from 'express'
import cors from 'cors'
import { requireAuth, optionalAuth, requireRole } from './middleware/clerk-auth'

const app = express()

app.use(cors({
  origin: process.env.FRONTEND_URL || 'http://localhost:3000',
  credentials: true,
}))
app.use(express.json())
```

### 2. Public Routes

```typescript
// Anyone can access
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok' })
})

app.get('/api/public/posts', async (req, res) => {
  const posts = await getPosts()
  res.json({ posts })
})
```

### 3. Optional Authentication

```typescript
// Works with or without authentication
app.get('/api/posts/:id', optionalAuth, async (req, res) => {
  const { userId } = req.auth || {}
  const { id } = req.params

  const post = await getPost(id)

  // Show extra data if authenticated
  if (userId) {
    post.authorDetails = await getAuthorDetails(post.authorId)
  }

  res.json({ post, authenticated: !!userId })
})
```

### 4. Protected Routes

```typescript
// Requires authentication
app.get('/api/user/profile', requireAuth, async (req, res) => {
  const { userId } = req.auth

  const user = await getUserById(userId)

  res.json({
    id: user.id,
    email: user.emailAddresses[0]?.emailAddress,
    firstName: user.firstName,
    lastName: user.lastName,
  })
})

app.post('/api/posts', requireAuth, async (req, res) => {
  const { userId } = req.auth
  const { title, content } = req.body

  const newPost = await createPost({
    userId,
    title,
    content,
  })

  res.status(201).json({ post: newPost })
})
```

### 5. Role-Based Access Control

```typescript
// Admin only routes
app.get('/api/admin/users', requireAuth, requireRole('admin'), async (req, res) => {
  const users = await getAllUsers()
  res.json({ users })
})

app.put('/api/admin/users/:id/role', requireAuth, requireRole('admin'), async (req, res) => {
  const { id } = req.params
  const { role } = req.body

  await updateUserRole(id, role)
  res.json({ message: 'Role updated', userId: id, role })
})
```

## Full Code

See `examples/rest-api-clerk.ts.bak` for complete implementation with:
- Error handling middleware
- Webhook event handling
- Database operations
- Validation logic
- Type definitions

## Testing

### 1. Test Public Endpoint

```bash
curl http://localhost:8000/api/health
# Response: {"status":"ok"}
```

### 2. Test Protected Endpoint (Unauthenticated)

```bash
curl http://localhost:8000/api/user/profile
# Response: 401 Unauthorized
```

### 3. Test Protected Endpoint (Authenticated)

```bash
curl http://localhost:8000/api/user/profile \
  -H "Authorization: Bearer <your-jwt-token>"
# Response: User profile data
```

### 4. Test Admin Endpoint

```bash
# Requires admin role in user.publicMetadata
curl http://localhost:8000/api/admin/users \
  -H "Authorization: Bearer <admin-jwt-token>"
# Response: List of all users
```

## Security Best Practices

1. **Always validate tokens server-side**
2. **Use HTTPS in production**
3. **Implement rate limiting**
4. **Sanitize user inputs**
5. **Log authentication events**
6. **Never expose sensitive data**

## Common Issues

### "Invalid token" errors
- Verify `CLERK_SECRET_KEY` is correct
- Check token expiration
- Ensure clock sync

### CORS errors
- Configure CORS before Clerk middleware
- Whitelist frontend domain
- Include credentials in fetch requests

## Environment Variables

```bash
# .env
CLERK_PUBLISHABLE_KEY=your_clerk_publishable_key_here
CLERK_SECRET_KEY=your_clerk_secret_key_here
CLERK_WEBHOOK_SECRET=your_webhook_secret_here
FRONTEND_URL=http://localhost:3000
PORT=8000
```
