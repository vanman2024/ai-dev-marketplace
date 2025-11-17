#!/bin/bash
# configure-roles.sh - Setup RBAC roles and permissions for Clerk organizations
# Usage: ./configure-roles.sh [basic|advanced|custom]

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

MODE="${1:-basic}"

echo "================================================"
echo "Clerk RBAC Configuration"
echo "================================================"
echo ""

# Validate mode
if [[ ! "$MODE" =~ ^(basic|advanced|custom)$ ]]; then
  echo -e "${RED}Error: Invalid mode. Use 'basic', 'advanced', or 'custom'${NC}"
  echo ""
  echo "Usage: $0 [basic|advanced|custom]"
  echo ""
  echo "Modes:"
  echo "  basic    - Admin + Member roles only (default)"
  echo "  advanced - Admin + Manager + Member + Viewer roles"
  echo "  custom   - Interactive custom role creation"
  exit 1
fi

# Output directory for RBAC policies
OUTPUT_DIR="src/lib"
if [ ! -d "$OUTPUT_DIR" ]; then
  mkdir -p "$OUTPUT_DIR"
fi

OUTPUT_FILE="$OUTPUT_DIR/rbac.ts"

echo -e "${BLUE}Mode: $MODE${NC}"
echo ""

# Function to create basic RBAC file
create_basic_rbac() {
  cat > "$OUTPUT_FILE" << 'EOF'
/**
 * Clerk RBAC Configuration - Basic Mode
 * Roles: Admin, Member
 */

export const ROLES = {
  ADMIN: 'org:admin',
  MEMBER: 'org:member',
} as const;

export type Role = typeof ROLES[keyof typeof ROLES];

/**
 * Role definitions with descriptions
 */
export const ROLE_DEFINITIONS = {
  [ROLES.ADMIN]: {
    name: 'Admin',
    description: 'Full access to organization and all resources',
    permissions: ['*'], // All permissions
  },
  [ROLES.MEMBER]: {
    name: 'Member',
    description: 'Standard access to organization resources',
    permissions: [
      'resource:read',
      'resource:create',
      'resource:update',
    ],
  },
} as const;

/**
 * Check if user has required role
 */
export function hasRole(userRole: string | undefined, requiredRole: Role): boolean {
  if (!userRole) return false;

  // Admins have access to everything
  if (userRole === ROLES.ADMIN) return true;

  return userRole === requiredRole;
}

/**
 * Check if user is admin
 */
export function isAdmin(userRole: string | undefined): boolean {
  return userRole === ROLES.ADMIN;
}

/**
 * Get role display name
 */
export function getRoleName(role: string): string {
  return ROLE_DEFINITIONS[role as Role]?.name || 'Unknown';
}

/**
 * Get all available roles for assignment
 */
export function getAvailableRoles(): Role[] {
  return Object.values(ROLES);
}
EOF
  echo -e "${GREEN}✓ Created basic RBAC configuration at $OUTPUT_FILE${NC}"
}

# Function to create advanced RBAC file
create_advanced_rbac() {
  cat > "$OUTPUT_FILE" << 'EOF'
/**
 * Clerk RBAC Configuration - Advanced Mode
 * Roles: Admin, Manager, Member, Viewer
 */

export const ROLES = {
  ADMIN: 'org:admin',
  MANAGER: 'org:manager',
  MEMBER: 'org:member',
  VIEWER: 'org:viewer',
} as const;

export type Role = typeof ROLES[keyof typeof ROLES];

/**
 * Permission definitions
 */
export const PERMISSIONS = {
  // Organization management
  ORG_MANAGE: 'org:manage',
  ORG_DELETE: 'org:delete',

  // Member management
  MEMBERS_INVITE: 'members:invite',
  MEMBERS_MANAGE: 'members:manage',
  MEMBERS_REMOVE: 'members:remove',

  // Resource permissions
  RESOURCE_CREATE: 'resource:create',
  RESOURCE_READ: 'resource:read',
  RESOURCE_UPDATE: 'resource:update',
  RESOURCE_DELETE: 'resource:delete',

  // Billing (if using Clerk Billing)
  BILLING_MANAGE: 'billing:manage',
  BILLING_VIEW: 'billing:view',
} as const;

export type Permission = typeof PERMISSIONS[keyof typeof PERMISSIONS];

/**
 * Role definitions with permissions
 */
export const ROLE_DEFINITIONS = {
  [ROLES.ADMIN]: {
    name: 'Admin',
    description: 'Full access to organization and all resources',
    permissions: ['*'], // All permissions
  },
  [ROLES.MANAGER]: {
    name: 'Manager',
    description: 'Manage team members and resources, no billing access',
    permissions: [
      PERMISSIONS.MEMBERS_INVITE,
      PERMISSIONS.MEMBERS_MANAGE,
      PERMISSIONS.RESOURCE_CREATE,
      PERMISSIONS.RESOURCE_READ,
      PERMISSIONS.RESOURCE_UPDATE,
      PERMISSIONS.RESOURCE_DELETE,
      PERMISSIONS.BILLING_VIEW,
    ],
  },
  [ROLES.MEMBER]: {
    name: 'Member',
    description: 'Standard access to organization resources',
    permissions: [
      PERMISSIONS.RESOURCE_CREATE,
      PERMISSIONS.RESOURCE_READ,
      PERMISSIONS.RESOURCE_UPDATE,
    ],
  },
  [ROLES.VIEWER]: {
    name: 'Viewer',
    description: 'Read-only access to organization resources',
    permissions: [
      PERMISSIONS.RESOURCE_READ,
      PERMISSIONS.BILLING_VIEW,
    ],
  },
} as const;

/**
 * Check if user has specific permission
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
 * Check if user has required role
 */
export function hasRole(userRole: string | undefined, requiredRole: Role): boolean {
  if (!userRole) return false;

  // Admins have access to everything
  if (userRole === ROLES.ADMIN) return true;

  return userRole === requiredRole;
}

/**
 * Check if user is admin
 */
export function isAdmin(userRole: string | undefined): boolean {
  return userRole === ROLES.ADMIN;
}

/**
 * Get role display name
 */
export function getRoleName(role: string): string {
  return ROLE_DEFINITIONS[role as Role]?.name || 'Unknown';
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
EOF
  echo -e "${GREEN}✓ Created advanced RBAC configuration at $OUTPUT_FILE${NC}"
}

# Function to create custom RBAC file (interactive)
create_custom_rbac() {
  echo -e "${YELLOW}Interactive custom role creation${NC}"
  echo ""
  echo "You will define custom roles and permissions."
  echo ""

  # For now, create advanced template and show instructions
  create_advanced_rbac

  echo ""
  echo -e "${BLUE}Custom RBAC Setup Instructions:${NC}"
  echo ""
  echo "1. Edit $OUTPUT_FILE to add your custom roles"
  echo "2. Define roles in the ROLES constant"
  echo "3. Define permissions in the PERMISSIONS constant"
  echo "4. Map roles to permissions in ROLE_DEFINITIONS"
  echo ""
  echo "Example custom role:"
  echo ""
  echo "  BILLING_ADMIN: 'org:billing_admin',"
  echo ""
  echo "  [ROLES.BILLING_ADMIN]: {"
  echo "    name: 'Billing Admin',"
  echo "    description: 'Manage billing only',"
  echo "    permissions: ["
  echo "      PERMISSIONS.BILLING_MANAGE,"
  echo "      PERMISSIONS.BILLING_VIEW,"
  echo "    ],"
  echo "  },"
  echo ""
  echo -e "${YELLOW}Note: Custom roles must also be created in Clerk Dashboard!${NC}"
}

# Execute based on mode
case "$MODE" in
  basic)
    create_basic_rbac
    ;;
  advanced)
    create_advanced_rbac
    ;;
  custom)
    create_custom_rbac
    ;;
esac

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}RBAC Configuration Complete!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo "Next steps:"
echo ""
echo "1. Configure roles in Clerk Dashboard:"
echo "   - Go to https://dashboard.clerk.com"
echo "   - Navigate to 'Organizations' → 'Roles'"
echo "   - Create custom roles matching your RBAC configuration"
echo ""
echo "2. Import RBAC utilities in your components:"
echo "   import { hasRole, hasPermission, isAdmin } from '@/lib/rbac';"
echo ""
echo "3. Protect routes with middleware:"
echo "   See examples/org-admin-dashboard.tsx for usage"
echo ""
echo "4. Add permission checks to UI components:"
echo "   {hasPermission(orgRole, PERMISSIONS.MEMBERS_MANAGE) && <InviteButton />}"
echo ""
echo -e "${BLUE}See SKILL.md for complete examples and documentation.${NC}"
echo ""
