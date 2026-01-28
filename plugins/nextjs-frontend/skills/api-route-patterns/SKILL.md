---
name: api-route-patterns
description: Load Next.js API route patterns for App Router. Use when creating API routes, server actions, or discussing backend endpoints. Auto-invokes when user mentions API, route handler, server action, POST, GET, or endpoint.
---

# Next.js API Route Patterns (App Router)

**Purpose:** Ensure consistent API route structure following App Router conventions.

## Discover Existing API Routes

!find app/api -name "route.ts" -type f 2>/dev/null | head -10 || echo "No existing API routes found"

## Route Handler Template

```typescript
// app/api/[resource]/route.ts
import { NextRequest, NextResponse } from 'next/server';

// GET - Fetch resources
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const limit = searchParams.get('limit') || '10';

    const data = await fetchData({ limit: parseInt(limit) });

    return NextResponse.json({ data });
  } catch (error) {
    console.error('GET /api/resource error:', error);
    return NextResponse.json(
      { error: 'Failed to fetch resources' },
      { status: 500 }
    );
  }
}

// POST - Create resource
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();

    // Validate input
    if (!body.name) {
      return NextResponse.json({ error: 'Name is required' }, { status: 400 });
    }

    const created = await createResource(body);

    return NextResponse.json({ data: created }, { status: 201 });
  } catch (error) {
    console.error('POST /api/resource error:', error);
    return NextResponse.json(
      { error: 'Failed to create resource' },
      { status: 500 }
    );
  }
}
```

## Dynamic Route Handler

```typescript
// app/api/posts/[id]/route.ts
import { NextRequest, NextResponse } from 'next/server';

interface RouteParams {
  params: Promise<{ id: string }>;
}

// GET single resource
export async function GET(request: NextRequest, { params }: RouteParams) {
  const { id } = await params;

  const post = await getPost(id);

  if (!post) {
    return NextResponse.json({ error: 'Post not found' }, { status: 404 });
  }

  return NextResponse.json({ data: post });
}

// PATCH - Update resource
export async function PATCH(request: NextRequest, { params }: RouteParams) {
  const { id } = await params;
  const body = await request.json();

  const updated = await updatePost(id, body);

  return NextResponse.json({ data: updated });
}

// DELETE - Remove resource
export async function DELETE(request: NextRequest, { params }: RouteParams) {
  const { id } = await params;

  await deletePost(id);

  return new NextResponse(null, { status: 204 });
}
```

## Server Actions (Alternative to API Routes)

```typescript
// app/actions/posts.ts
'use server';

import { revalidatePath } from 'next/cache';

export async function createPost(formData: FormData) {
  const title = formData.get('title') as string;
  const content = formData.get('content') as string;

  // Validate
  if (!title || !content) {
    return { error: 'Title and content are required' };
  }

  // Create
  const post = await db.posts.create({
    data: { title, content },
  });

  // Revalidate cache
  revalidatePath('/posts');

  return { data: post };
}

// Usage in component
// <form action={createPost}>...</form>
```

## Response Patterns

```typescript
// Success responses
return NextResponse.json({ data: result }); // 200
return NextResponse.json({ data: created }, { status: 201 }); // 201 Created
return new NextResponse(null, { status: 204 }); // 204 No Content

// Error responses
return NextResponse.json({ error: 'Bad request' }, { status: 400 });
return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
return NextResponse.json({ error: 'Not found' }, { status: 404 });
return NextResponse.json({ error: 'Server error' }, { status: 500 });
```

## Middleware for Auth

```typescript
// middleware.ts (root level)
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  const token = request.cookies.get('auth-token');

  if (!token && request.nextUrl.pathname.startsWith('/api/protected')) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  return NextResponse.next();
}

export const config = {
  matcher: '/api/:path*',
};
```
