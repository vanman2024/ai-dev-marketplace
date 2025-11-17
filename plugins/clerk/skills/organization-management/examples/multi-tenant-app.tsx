/**
 * Multi-Tenant Application Example
 *
 * Complete example of a multi-tenant SaaS application with:
 * - Organization context management
 * - Organization-scoped data isolation
 * - Permission-based UI rendering
 * - Organization switching flow
 *
 * This example uses Next.js App Router with Clerk for authentication
 */

'use client';

import { useOrganization, useUser } from '@clerk/nextjs';
import { useEffect, useState } from 'react';
import { hasPermission, PERMISSIONS, getRoleName } from '@/lib/rbac';

/**
 * Organization Context Provider
 *
 * Wraps your app to provide organization context to all components
 */
export function OrganizationProvider({ children }: { children: React.ReactNode }) {
  const { organization, membership, isLoaded } = useOrganization();

  // Show loading state while organization data loads
  if (!isLoaded) {
    return (
      <div className="flex items-center justify-center h-screen">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500" />
      </div>
    );
  }

  // If no organization, prompt user to create/join one
  if (!organization) {
    return <NoOrganizationView />;
  }

  return (
    <div className="organization-context" data-org-id={organization.id}>
      {children}
    </div>
  );
}

/**
 * View shown when user is not in any organization
 */
function NoOrganizationView() {
  const { user } = useUser();

  return (
    <div className="flex items-center justify-center h-screen bg-gray-50">
      <div className="max-w-md w-full bg-white rounded-lg shadow-lg p-8">
        <h1 className="text-2xl font-bold mb-4">Welcome, {user?.firstName}!</h1>
        <p className="text-gray-600 mb-6">
          To get started, create an organization or join an existing one.
        </p>

        <div className="space-y-3">
          <a
            href="/create-organization"
            className="block w-full px-4 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 text-center font-medium"
          >
            Create Organization
          </a>
          <a
            href="/join-organization"
            className="block w-full px-4 py-3 border border-gray-300 rounded-lg hover:bg-gray-50 text-center font-medium"
          >
            Join Organization
          </a>
        </div>
      </div>
    </div>
  );
}

/**
 * Organization Dashboard - Main App View
 */
export function OrganizationDashboard() {
  const { organization, membership } = useOrganization();
  const [projects, setProjects] = useState<Project[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  // Fetch organization-scoped projects
  useEffect(() => {
    async function fetchProjects() {
      try {
        setIsLoading(true);
        // API automatically filters by organization via middleware
        const response = await fetch('/api/projects');
        if (!response.ok) throw new Error('Failed to fetch projects');
        const data = await response.json();
        setProjects(data);
      } catch (error) {
        console.error('Error fetching projects:', error);
      } finally {
        setIsLoading(false);
      }
    }

    if (organization) {
      fetchProjects();
    }
  }, [organization]);

  if (!organization || !membership) return null;

  const canCreateProject = hasPermission(membership.role, PERMISSIONS.PROJECT_CREATE);
  const canManageMembers = hasPermission(membership.role, PERMISSIONS.MEMBERS_MANAGE);

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      {/* Organization Header */}
      <div className="mb-8">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">{organization.name}</h1>
            <p className="text-gray-500 mt-1">
              Your role: {getRoleName(membership.role)}
            </p>
          </div>

          {/* Action Buttons (permission-based) */}
          <div className="flex gap-3">
            {canManageMembers && (
              <a
                href={`/organization/${organization.id}/members`}
                className="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 font-medium"
              >
                Manage Members
              </a>
            )}
            {canCreateProject && (
              <a
                href="/projects/new"
                className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 font-medium"
              >
                New Project
              </a>
            )}
          </div>
        </div>
      </div>

      {/* Projects List */}
      <div>
        <h2 className="text-xl font-semibold mb-4">Projects</h2>

        {isLoading ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {[1, 2, 3].map((i) => (
              <div key={i} className="h-32 bg-gray-200 animate-pulse rounded-lg" />
            ))}
          </div>
        ) : projects.length === 0 ? (
          <div className="text-center py-12 bg-gray-50 rounded-lg">
            <p className="text-gray-500 mb-4">No projects yet</p>
            {canCreateProject && (
              <a
                href="/projects/new"
                className="inline-block px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
              >
                Create First Project
              </a>
            )}
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {projects.map((project) => (
              <ProjectCard key={project.id} project={project} userRole={membership.role} />
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

/**
 * Project Card Component
 */
function ProjectCard({ project, userRole }: { project: Project; userRole: string }) {
  const canUpdate = hasPermission(userRole, PERMISSIONS.PROJECT_UPDATE);
  const canDelete = hasPermission(userRole, PERMISSIONS.PROJECT_DELETE);

  return (
    <div className="bg-white rounded-lg border border-gray-200 p-6 hover:shadow-md transition-shadow">
      <div className="flex items-start justify-between mb-4">
        <h3 className="text-lg font-semibold">{project.name}</h3>
        {(canUpdate || canDelete) && (
          <div className="flex gap-2">
            {canUpdate && (
              <button
                className="p-1 hover:bg-gray-100 rounded"
                aria-label="Edit project"
              >
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
                  />
                </svg>
              </button>
            )}
            {canDelete && (
              <button
                className="p-1 hover:bg-red-100 rounded text-red-600"
                aria-label="Delete project"
              >
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                  />
                </svg>
              </button>
            )}
          </div>
        )}
      </div>

      <p className="text-gray-600 text-sm mb-4 line-clamp-2">
        {project.description || 'No description'}
      </p>

      <div className="flex items-center justify-between text-sm text-gray-500">
        <span>Created {new Date(project.createdAt).toLocaleDateString()}</span>
        <a
          href={`/projects/${project.id}`}
          className="text-blue-600 hover:text-blue-700 font-medium"
        >
          View →
        </a>
      </div>
    </div>
  );
}

/**
 * API Route Example: Organization-scoped data fetching
 *
 * File: app/api/projects/route.ts
 */
/*
import { auth } from '@clerk/nextjs/server';
import { NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';

export async function GET() {
  try {
    const { orgId } = await auth();

    if (!orgId) {
      return NextResponse.json(
        { error: 'No organization context' },
        { status: 400 }
      );
    }

    // Automatically filtered by organizationId
    const projects = await prisma.project.findMany({
      where: {
        organizationId: orgId,
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    return NextResponse.json(projects);
  } catch (error) {
    console.error('Error fetching projects:', error);
    return NextResponse.json(
      { error: 'Failed to fetch projects' },
      { status: 500 }
    );
  }
}

export async function POST(request: Request) {
  try {
    const { orgId, orgRole } = await auth();

    if (!orgId) {
      return NextResponse.json(
        { error: 'No organization context' },
        { status: 400 }
      );
    }

    // Check permission
    if (!hasPermission(orgRole, PERMISSIONS.PROJECT_CREATE)) {
      return NextResponse.json(
        { error: 'Insufficient permissions' },
        { status: 403 }
      );
    }

    const body = await request.json();

    // Create project scoped to organization
    const project = await prisma.project.create({
      data: {
        ...body,
        organizationId: orgId,
      },
    });

    return NextResponse.json(project);
  } catch (error) {
    console.error('Error creating project:', error);
    return NextResponse.json(
      { error: 'Failed to create project' },
      { status: 500 }
    );
  }
}
*/

/**
 * Middleware Example: Require organization membership
 *
 * File: middleware.ts
 */
/*
import { authMiddleware } from '@clerk/nextjs/server';
import { NextResponse } from 'next/server';

export default authMiddleware({
  afterAuth(auth, req) {
    // Paths that require organization membership
    const orgRequiredPaths = ['/projects', '/dashboard', '/api/projects'];

    const isOrgRequiredPath = orgRequiredPaths.some(path =>
      req.nextUrl.pathname.startsWith(path)
    );

    if (isOrgRequiredPath && !auth.orgId) {
      // Redirect to organization selection page
      return NextResponse.redirect(new URL('/select-organization', req.url));
    }

    return NextResponse.next();
  },
});

export const config = {
  matcher: ['/((?!.+\\.[\\w]+$|_next).*)', '/', '/(api|trpc)(.*)'],
};
*/

// TypeScript types
interface Project {
  id: string;
  organizationId: string;
  name: string;
  description?: string;
  createdAt: string;
  updatedAt: string;
}
