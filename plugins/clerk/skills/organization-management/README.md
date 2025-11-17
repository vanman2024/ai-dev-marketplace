# Organization Management Skill

Comprehensive multi-tenant organization features and RBAC patterns for Clerk authentication.

## Overview

This skill provides everything needed to implement production-ready multi-tenant SaaS applications with:

- **Organization Management**: Create, switch, and manage organizations
- **RBAC (Role-Based Access Control)**: Granular permission system with custom roles
- **Data Isolation**: Multi-tenant database patterns with organization scoping
- **UI Components**: Pre-built organization switcher and admin dashboard
- **Security**: Built-in permission checks and middleware protection

## Quick Start

### 1. Enable Organizations

```bash
./scripts/setup-organizations.sh
```

This script guides you through:
- Enabling organizations in Clerk Dashboard
- Configuring environment variables
- Setting up organization components directory

### 2. Configure RBAC

```bash
# Basic roles (Admin + Member)
./scripts/configure-roles.sh basic

# Advanced roles (Admin + Manager + Member + Viewer)
./scripts/configure-roles.sh advanced

# Custom roles (interactive)
./scripts/configure-roles.sh custom
```

### 3. Add Organization Components

```bash
# Organization switcher
cp templates/organization-switcher.tsx src/components/

# RBAC policies
cp templates/rbac-policies.ts src/lib/

# Database schema (review and adapt)
cat templates/organization-schema.md
```

### 4. Test Organization Isolation

```bash
# Run isolation tests
./scripts/test-org-isolation.sh
```

## Directory Structure

```
organization-management/
├── SKILL.md                          # Main skill documentation
├── README.md                         # This file
├── scripts/
│   ├── setup-organizations.sh        # Enable organizations
│   ├── configure-roles.sh            # Setup RBAC
│   └── test-org-isolation.sh         # Test data isolation
├── templates/
│   ├── organization-schema.md        # Database schema patterns
│   ├── rbac-policies.ts              # Role and permission definitions
│   └── organization-switcher.tsx     # Organization switcher component
└── examples/
    ├── multi-tenant-app.tsx          # Complete multi-tenant application
    └── org-admin-dashboard.tsx       # Organization admin interface
```

## Key Features

### Multi-Tenant Data Isolation

- Row-Level Security (RLS) patterns for Postgres/Supabase
- Application-level scoping for Prisma/MongoDB
- Automatic organization_id injection in queries
- Cross-tenant data leakage prevention

### RBAC System

**Basic Roles:**
- Admin: Full organization control
- Member: Standard access

**Advanced Roles:**
- Admin: Full organization control
- Manager: Team management, no billing
- Member: Regular access
- Viewer: Read-only access

**Custom Roles:**
- Define your own roles and permissions
- Granular permission checks
- Role hierarchy support

### Permission System

```typescript
import { hasPermission, PERMISSIONS } from '@/lib/rbac';

// Check permission
if (hasPermission(userRole, PERMISSIONS.PROJECT_CREATE)) {
  // Allow action
}

// Check multiple permissions
if (hasAnyPermission(userRole, [PERMISSIONS.BILLING_VIEW, PERMISSIONS.BILLING_MANAGE])) {
  // Allow access to billing
}
```

### Database Patterns

**Supabase/Postgres with RLS:**
```sql
-- Enable RLS
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;

-- Create policy
CREATE POLICY "org_isolation" ON projects
FOR ALL USING (organization_id = current_setting('app.current_organization_id'));
```

**Prisma (Application-level):**
```typescript
// Auto-filter by organizationId
const projects = await prisma.project.findMany({
  where: { organizationId: currentOrgId }
});
```

## Components

### Organization Switcher

Four variants included:
1. `SimpleOrganizationSwitcher` - Uses Clerk's built-in component (recommended)
2. `CustomOrganizationSwitcher` - Full custom implementation with dropdown
3. `CompactOrganizationSwitcher` - Mobile-friendly compact version
4. `OrganizationSwitcherWithSettings` - Includes settings link

### Admin Dashboard

Complete organization management interface:
- Member list with role management
- Pending invitations
- Role assignment
- Member removal
- Permission-based UI rendering

## Usage Examples

### Protect Routes with Middleware

```typescript
import { auth } from '@clerk/nextjs/server';
import { hasPermission, PERMISSIONS } from '@/lib/rbac';

export default async function middleware(req: Request) {
  const { orgId, orgRole } = await auth();

  if (!orgId) {
    return NextResponse.redirect('/select-organization');
  }

  if (!hasPermission(orgRole, PERMISSIONS.PROJECT_CREATE)) {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
  }
}
```

### Organization-Scoped API Routes

```typescript
import { auth } from '@clerk/nextjs/server';

export async function GET() {
  const { orgId } = await auth();

  // Automatically scoped to organization
  const projects = await db.project.findMany({
    where: { organizationId: orgId }
  });

  return NextResponse.json(projects);
}
```

### Permission-Based UI

```typescript
import { useOrganization } from '@clerk/nextjs';
import { hasPermission, PERMISSIONS } from '@/lib/rbac';

function MyComponent() {
  const { membership } = useOrganization();

  if (!hasPermission(membership?.role, PERMISSIONS.MEMBERS_MANAGE)) {
    return null; // Hide component
  }

  return <AdminButton />;
}
```

## Environment Variables

```bash
# Required
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_your_clerk_key_here
CLERK_SECRET_KEY=sk_test_your_clerk_secret_here

# Optional feature flags
NEXT_PUBLIC_ENABLE_ORG_CREATION=true
NEXT_PUBLIC_MAX_ORGS_PER_USER=5
```

## Testing

### Manual Testing Checklist

1. Create organization in multiple accounts
2. Switch between organizations
3. Verify data isolation (no cross-tenant leakage)
4. Test role-based access control
5. Verify permission checks in UI and API
6. Test member invitation flow
7. Test role assignment changes

### Automated Testing

```bash
# Run isolation tests
./scripts/test-org-isolation.sh
```

## Best Practices

### Security

- ✅ Always filter queries by `organizationId`
- ✅ Validate organization ownership before mutations
- ✅ Use RLS policies (Postgres/Supabase)
- ✅ Check permissions in both UI and API
- ✅ Never trust client-sent organization IDs

### Performance

- ✅ Add indexes on `organization_id` columns
- ✅ Use connection pooling for database
- ✅ Cache organization metadata
- ✅ Optimize RLS policies

### UX

- ✅ Show clear organization context in UI
- ✅ Provide easy organization switching
- ✅ Display user's role prominently
- ✅ Hide features based on permissions

## Troubleshooting

### Organizations Not Appearing

- Verify organizations enabled in Clerk Dashboard
- Check environment variables set correctly
- Ensure user has created/joined an organization

### RBAC Not Working

- Verify custom roles defined in Clerk Dashboard
- Check role assignment in organization settings
- Confirm middleware/permission checks use correct role names

### Data Isolation Failing

- Verify all tables include `organization_id` column
- Check RLS policies enabled and correct
- Test with multiple organizations

## Resources

- [Clerk Organizations Documentation](https://clerk.com/docs)
- [SKILL.md](./SKILL.md) - Complete skill documentation
- [Examples](./examples/) - Full application examples
- [Templates](./templates/) - Reusable code templates

## Version

**Version:** 1.0.0
**Clerk SDK:** @clerk/nextjs 5+, @clerk/clerk-react 5+
**Frameworks:** Next.js (App Router & Pages Router), React, Remix, Gatsby

## License

MIT
