# Multi-Tenant Database Schema Patterns

This document provides database schema patterns for implementing organization-scoped data isolation.

## Core Principle

**Every tenant-scoped table MUST include `organization_id`** to ensure data isolation.

## Pattern 1: Supabase/PostgreSQL with Row-Level Security (RLS)

### Schema Design

```sql
-- Example: Projects table with organization scoping
CREATE TABLE projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id TEXT NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for performance
CREATE INDEX idx_projects_organization_id ON projects(organization_id);

-- Enable RLS
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can only access their organization's projects
CREATE POLICY "Users can access their org's projects"
ON projects
FOR ALL
USING (
  organization_id = current_setting('app.current_organization_id', true)
);
```

### Setting Organization Context (Supabase Client)

```typescript
import { createClient } from '@supabase/supabase-js';
import { auth } from '@clerk/nextjs/server';

export async function getSupabaseClient() {
  const { orgId } = await auth();

  if (!orgId) {
    throw new Error('No organization context');
  }

  const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!, // Use service role for RLS
    {
      global: {
        headers: {
          // Set organization context for RLS
          'x-organization-id': orgId,
        },
      },
    }
  );

  // Set session variable for RLS policies
  await supabase.rpc('set_organization_context', {
    org_id: orgId,
  });

  return supabase;
}
```

### RLS Helper Function

```sql
-- Create function to set organization context
CREATE OR REPLACE FUNCTION set_organization_context(org_id TEXT)
RETURNS VOID AS $$
BEGIN
  PERFORM set_config('app.current_organization_id', org_id, false);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### Additional RLS Policies

```sql
-- Policy for inserting (auto-set organization_id)
CREATE POLICY "Users can insert into their org"
ON projects
FOR INSERT
WITH CHECK (
  organization_id = current_setting('app.current_organization_id', true)
);

-- Policy for updating (only their org's data)
CREATE POLICY "Users can update their org's projects"
ON projects
FOR UPDATE
USING (
  organization_id = current_setting('app.current_organization_id', true)
);

-- Policy for deleting (only their org's data)
CREATE POLICY "Users can delete their org's projects"
ON projects
FOR DELETE
USING (
  organization_id = current_setting('app.current_organization_id', true)
);
```

## Pattern 2: Prisma (Application-Level Scoping)

### Prisma Schema

```prisma
// schema.prisma
model Project {
  id             String   @id @default(uuid())
  organizationId String   @map("organization_id")
  name           String
  description    String?
  createdBy      String   @map("created_by")
  createdAt      DateTime @default(now()) @map("created_at")
  updatedAt      DateTime @updatedAt @map("updated_at")

  // Relations
  organization Organization @relation(fields: [organizationId], references: [id])

  @@index([organizationId])
  @@map("projects")
}

model Organization {
  id        String    @id @default(uuid())
  clerkId   String    @unique @map("clerk_id") // Clerk organization ID
  name      String
  createdAt DateTime  @default(now()) @map("created_at")
  updatedAt DateTime  @updatedAt @map("updated_at")

  // Relations
  projects  Project[]

  @@map("organizations")
}
```

### Prisma Client Middleware (Auto-Inject Organization ID)

```typescript
// lib/prisma.ts
import { PrismaClient } from '@prisma/client';
import { auth } from '@clerk/nextjs/server';

const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined;
};

export const prisma = globalForPrisma.prisma ?? new PrismaClient();

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma;

/**
 * Middleware to auto-inject organizationId on create operations
 */
prisma.$use(async (params, next) => {
  // Only apply to models with organizationId field
  const modelsWithOrg = ['Project', 'Task', 'Document']; // Add your models here

  if (modelsWithOrg.includes(params.model || '')) {
    if (params.action === 'create') {
      const { orgId } = await auth();

      if (!orgId) {
        throw new Error('No organization context for create operation');
      }

      // Auto-inject organizationId
      params.args.data.organizationId = orgId;
    }

    // Filter all queries by organizationId
    if (['findMany', 'findFirst', 'count', 'aggregate'].includes(params.action)) {
      const { orgId } = await auth();

      if (orgId) {
        params.args.where = {
          ...params.args.where,
          organizationId: orgId,
        };
      }
    }
  }

  return next(params);
});
```

### Prisma Queries (Manual Scoping)

```typescript
import { prisma } from '@/lib/prisma';
import { auth } from '@clerk/nextjs/server';

// Create project scoped to organization
export async function createProject(data: { name: string; description: string }) {
  const { orgId } = await auth();

  if (!orgId) {
    throw new Error('No organization context');
  }

  return prisma.project.create({
    data: {
      ...data,
      organizationId: orgId,
    },
  });
}

// Get all projects for current organization
export async function getProjects() {
  const { orgId } = await auth();

  if (!orgId) {
    throw new Error('No organization context');
  }

  return prisma.project.findMany({
    where: {
      organizationId: orgId,
    },
    orderBy: {
      createdAt: 'desc',
    },
  });
}

// Get single project (with organization check)
export async function getProject(id: string) {
  const { orgId } = await auth();

  if (!orgId) {
    throw new Error('No organization context');
  }

  const project = await prisma.project.findFirst({
    where: {
      id,
      organizationId: orgId, // Critical: Must match org
    },
  });

  if (!project) {
    throw new Error('Project not found or access denied');
  }

  return project;
}
```

## Pattern 3: MongoDB (Document-Based)

### Schema Design

```typescript
// MongoDB schema with organization scoping
interface Project {
  _id: ObjectId;
  organizationId: string; // Clerk organization ID
  name: string;
  description?: string;
  createdBy: string;
  createdAt: Date;
  updatedAt: Date;
}

// Create index for performance
db.projects.createIndex({ organizationId: 1 });
```

### MongoDB Queries

```typescript
import { MongoClient } from 'mongodb';
import { auth } from '@clerk/nextjs/server';

export async function getProjects() {
  const { orgId } = await auth();

  if (!orgId) {
    throw new Error('No organization context');
  }

  const client = new MongoClient(process.env.MONGODB_URI!);
  await client.connect();

  const db = client.db();
  const projects = await db
    .collection('projects')
    .find({ organizationId: orgId })
    .toArray();

  await client.close();

  return projects;
}
```

## Best Practices

### 1. Always Filter by Organization ID

```typescript
// ✅ CORRECT
const projects = await db.projects.findMany({
  where: { organizationId: currentOrgId },
});

// ❌ WRONG - No organization filter!
const projects = await db.projects.findMany();
```

### 2. Validate Organization Access

```typescript
export async function validateOrganizationAccess(resourceId: string) {
  const { orgId } = await auth();
  const resource = await db.resource.findUnique({ where: { id: resourceId } });

  if (resource?.organizationId !== orgId) {
    throw new Error('Unauthorized: Resource belongs to different organization');
  }

  return resource;
}
```

### 3. Use Database Constraints

```sql
-- Add NOT NULL constraint
ALTER TABLE projects
ALTER COLUMN organization_id SET NOT NULL;

-- Add foreign key (if you have organizations table)
ALTER TABLE projects
ADD CONSTRAINT fk_organization
FOREIGN KEY (organization_id)
REFERENCES organizations(clerk_id);
```

### 4. Test Isolation Thoroughly

Use the `test-org-isolation.sh` script to verify:
- No cross-tenant data leakage
- Organization switching updates context correctly
- All queries filter by organizationId

## Security Checklist

- [ ] All tenant-scoped tables have `organization_id` column
- [ ] `organization_id` is NOT NULL
- [ ] Indexes created on `organization_id` for performance
- [ ] RLS policies enabled (if using Postgres/Supabase)
- [ ] Application queries ALWAYS filter by organization
- [ ] API routes validate organization ownership
- [ ] Middleware enforces organization context
- [ ] Tests verify data isolation between organizations
- [ ] No raw SQL without organization filtering

## Common Mistakes to Avoid

### ❌ Mistake 1: Missing Organization ID in Queries

```typescript
// WRONG - Missing organization filter
const project = await db.project.findUnique({ where: { id } });
```

### ❌ Mistake 2: Client-Side Organization Filtering

```typescript
// WRONG - Filtering after fetching (data leak!)
const allProjects = await db.project.findMany();
const orgProjects = allProjects.filter(p => p.organizationId === orgId);
```

### ❌ Mistake 3: Trusting Client-Sent Organization ID

```typescript
// WRONG - Using org ID from request body (can be spoofed!)
const { organizationId } = req.body;

// CORRECT - Get org ID from authenticated session
const { orgId } = await auth();
```

## Migration Guide

### Adding Organization ID to Existing Tables

```sql
-- Step 1: Add column (nullable initially)
ALTER TABLE projects ADD COLUMN organization_id TEXT;

-- Step 2: Backfill organization_id for existing data
UPDATE projects
SET organization_id = 'default_org_id'
WHERE organization_id IS NULL;

-- Step 3: Make column NOT NULL
ALTER TABLE projects ALTER COLUMN organization_id SET NOT NULL;

-- Step 4: Add index
CREATE INDEX idx_projects_organization_id ON projects(organization_id);

-- Step 5: Enable RLS (Postgres/Supabase only)
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;

-- Step 6: Add RLS policies
CREATE POLICY "org_isolation_policy" ON projects
FOR ALL USING (organization_id = current_setting('app.current_organization_id', true));
```

---

**Remember:** Organization-scoped data isolation is critical for multi-tenant security. Always test thoroughly!
