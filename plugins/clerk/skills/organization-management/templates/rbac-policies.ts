/**
 * Clerk RBAC Policies - Template
 *
 * This template provides a comprehensive RBAC implementation for Clerk organizations.
 * Customize roles and permissions based on your application requirements.
 *
 * IMPORTANT: Custom roles must also be created in Clerk Dashboard!
 * Dashboard → Organizations → Roles
 */

/**
 * Organization roles
 * These must match the roles created in your Clerk Dashboard
 */
export const ROLES = {
  ADMIN: 'org:admin',
  MANAGER: 'org:manager',
  MEMBER: 'org:member',
  VIEWER: 'org:viewer',
} as const;

export type Role = typeof ROLES[keyof typeof ROLES];

/**
 * Granular permissions for fine-grained access control
 */
export const PERMISSIONS = {
  // Organization management
  ORG_MANAGE: 'org:manage',
  ORG_DELETE: 'org:delete',
  ORG_SETTINGS: 'org:settings',

  // Member management
  MEMBERS_INVITE: 'members:invite',
  MEMBERS_MANAGE: 'members:manage',
  MEMBERS_REMOVE: 'members:remove',
  MEMBERS_VIEW: 'members:view',

  // Project permissions
  PROJECT_CREATE: 'project:create',
  PROJECT_READ: 'project:read',
  PROJECT_UPDATE: 'project:update',
  PROJECT_DELETE: 'project:delete',

  // Document permissions (example resource)
  DOCUMENT_CREATE: 'document:create',
  DOCUMENT_READ: 'document:read',
  DOCUMENT_UPDATE: 'document:update',
  DOCUMENT_DELETE: 'document:delete',

  // Billing (if using Clerk Billing)
  BILLING_MANAGE: 'billing:manage',
  BILLING_VIEW: 'billing:view',

  // API access
  API_KEY_CREATE: 'api_key:create',
  API_KEY_MANAGE: 'api_key:manage',

  // Analytics/Reporting
  ANALYTICS_VIEW: 'analytics:view',
  REPORTS_EXPORT: 'reports:export',
} as const;

export type Permission = typeof PERMISSIONS[keyof typeof PERMISSIONS];

/**
 * Role definitions with assigned permissions
 */
export const ROLE_DEFINITIONS = {
  [ROLES.ADMIN]: {
    name: 'Admin',
    description: 'Full access to organization and all resources',
    color: '#EF4444', // Red
    permissions: ['*'], // Wildcard grants all permissions
  },
  [ROLES.MANAGER]: {
    name: 'Manager',
    description: 'Manage team members and resources, limited admin access',
    color: '#F59E0B', // Orange
    permissions: [
      // Member management
      PERMISSIONS.MEMBERS_INVITE,
      PERMISSIONS.MEMBERS_MANAGE,
      PERMISSIONS.MEMBERS_VIEW,

      // Full resource access
      PERMISSIONS.PROJECT_CREATE,
      PERMISSIONS.PROJECT_READ,
      PERMISSIONS.PROJECT_UPDATE,
      PERMISSIONS.PROJECT_DELETE,
      PERMISSIONS.DOCUMENT_CREATE,
      PERMISSIONS.DOCUMENT_READ,
      PERMISSIONS.DOCUMENT_UPDATE,
      PERMISSIONS.DOCUMENT_DELETE,

      // View-only billing
      PERMISSIONS.BILLING_VIEW,

      // Analytics
      PERMISSIONS.ANALYTICS_VIEW,
      PERMISSIONS.REPORTS_EXPORT,
    ],
  },
  [ROLES.MEMBER]: {
    name: 'Member',
    description: 'Standard access to organization resources',
    color: '#3B82F6', // Blue
    permissions: [
      // View members only
      PERMISSIONS.MEMBERS_VIEW,

      // Create and manage own resources
      PERMISSIONS.PROJECT_CREATE,
      PERMISSIONS.PROJECT_READ,
      PERMISSIONS.PROJECT_UPDATE,
      PERMISSIONS.DOCUMENT_CREATE,
      PERMISSIONS.DOCUMENT_READ,
      PERMISSIONS.DOCUMENT_UPDATE,

      // View analytics
      PERMISSIONS.ANALYTICS_VIEW,
    ],
  },
  [ROLES.VIEWER]: {
    name: 'Viewer',
    description: 'Read-only access to organization resources',
    color: '#6B7280', // Gray
    permissions: [
      // Read-only access
      PERMISSIONS.MEMBERS_VIEW,
      PERMISSIONS.PROJECT_READ,
      PERMISSIONS.DOCUMENT_READ,
      PERMISSIONS.BILLING_VIEW,
      PERMISSIONS.ANALYTICS_VIEW,
    ],
  },
} as const;

/**
 * Check if user has specific permission
 *
 * @param userRole - User's role in the organization (from Clerk)
 * @param permission - Required permission
 * @returns true if user has permission
 */
export function hasPermission(
  userRole: string | undefined,
  permission: Permission
): boolean {
  if (!userRole) return false;

  const rolePerms = ROLE_DEFINITIONS[userRole as Role]?.permissions;
  if (!rolePerms) return false;

  // Wildcard permission grants all
  if (rolePerms.includes('*')) return true;

  return rolePerms.includes(permission);
}

/**
 * Check if user has ANY of the specified permissions
 *
 * @param userRole - User's role in the organization
 * @param permissions - Array of permissions (OR logic)
 * @returns true if user has at least one permission
 */
export function hasAnyPermission(
  userRole: string | undefined,
  permissions: Permission[]
): boolean {
  return permissions.some(permission => hasPermission(userRole, permission));
}

/**
 * Check if user has ALL specified permissions
 *
 * @param userRole - User's role in the organization
 * @param permissions - Array of permissions (AND logic)
 * @returns true if user has all permissions
 */
export function hasAllPermissions(
  userRole: string | undefined,
  permissions: Permission[]
): boolean {
  return permissions.every(permission => hasPermission(userRole, permission));
}

/**
 * Check if user has required role (exact match)
 *
 * @param userRole - User's role in the organization
 * @param requiredRole - Required role
 * @returns true if user has exact role
 */
export function hasRole(userRole: string | undefined, requiredRole: Role): boolean {
  if (!userRole) return false;
  return userRole === requiredRole;
}

/**
 * Check if user has role with at least the required access level
 * Admin > Manager > Member > Viewer
 *
 * @param userRole - User's role in the organization
 * @param minimumRole - Minimum required role
 * @returns true if user role meets or exceeds minimum
 */
export function hasMinimumRole(
  userRole: string | undefined,
  minimumRole: Role
): boolean {
  if (!userRole) return false;

  const roleHierarchy: Record<Role, number> = {
    [ROLES.ADMIN]: 4,
    [ROLES.MANAGER]: 3,
    [ROLES.MEMBER]: 2,
    [ROLES.VIEWER]: 1,
  };

  const userLevel = roleHierarchy[userRole as Role] || 0;
  const minimumLevel = roleHierarchy[minimumRole];

  return userLevel >= minimumLevel;
}

/**
 * Check if user is admin
 */
export function isAdmin(userRole: string | undefined): boolean {
  return userRole === ROLES.ADMIN;
}

/**
 * Check if user is manager or higher
 */
export function isManagerOrAbove(userRole: string | undefined): boolean {
  return hasMinimumRole(userRole, ROLES.MANAGER);
}

/**
 * Get role display name
 */
export function getRoleName(role: string): string {
  return ROLE_DEFINITIONS[role as Role]?.name || 'Unknown';
}

/**
 * Get role description
 */
export function getRoleDescription(role: string): string {
  return ROLE_DEFINITIONS[role as Role]?.description || '';
}

/**
 * Get role color (for UI badges)
 */
export function getRoleColor(role: string): string {
  return ROLE_DEFINITIONS[role as Role]?.color || '#6B7280';
}

/**
 * Get all permissions for a role
 */
export function getRolePermissions(role: string): Permission[] | ['*'] {
  return ROLE_DEFINITIONS[role as Role]?.permissions || [];
}

/**
 * Get all available roles for assignment
 */
export function getAvailableRoles(): Role[] {
  return Object.values(ROLES);
}

/**
 * Get role information for UI display
 */
export function getRoleInfo(role: string) {
  const definition = ROLE_DEFINITIONS[role as Role];
  if (!definition) return null;

  return {
    role: role as Role,
    name: definition.name,
    description: definition.description,
    color: definition.color,
    permissions: definition.permissions,
  };
}

/**
 * Get all roles with their information
 */
export function getAllRolesInfo() {
  return Object.entries(ROLE_DEFINITIONS).map(([role, definition]) => ({
    role: role as Role,
    name: definition.name,
    description: definition.description,
    color: definition.color,
    permissions: definition.permissions,
  }));
}

/**
 * Middleware helper: Require specific permission
 *
 * Usage in API routes:
 * if (!hasPermission(orgRole, PERMISSIONS.PROJECT_CREATE)) {
 *   return new Response('Forbidden', { status: 403 });
 * }
 */
export function requirePermission(
  userRole: string | undefined,
  permission: Permission
): void {
  if (!hasPermission(userRole, permission)) {
    throw new Error(`Missing required permission: ${permission}`);
  }
}

/**
 * Middleware helper: Require minimum role
 *
 * Usage in API routes:
 * requireMinimumRole(orgRole, ROLES.MANAGER);
 */
export function requireMinimumRole(
  userRole: string | undefined,
  minimumRole: Role
): void {
  if (!hasMinimumRole(userRole, minimumRole)) {
    throw new Error(`Insufficient role: requires ${minimumRole} or higher`);
  }
}

/**
 * Get permission display name (for UI)
 */
export function getPermissionName(permission: Permission): string {
  return permission.replace(/_/g, ' ').replace(/:/g, ' - ');
}

/**
 * Type guard for checking if a string is a valid role
 */
export function isValidRole(role: string): role is Role {
  return Object.values(ROLES).includes(role as Role);
}

/**
 * Type guard for checking if a string is a valid permission
 */
export function isValidPermission(permission: string): permission is Permission {
  return Object.values(PERMISSIONS).includes(permission as Permission);
}
