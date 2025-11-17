// custom-claims.ts
// Custom JWT claims configuration and type definitions

/**
 * Base Clerk JWT Claims
 * Standard claims present in all Clerk JWTs
 */
export interface BaseClerkClaims {
  /** Issuer - Clerk instance ID */
  iss: string;
  /** Subject - User ID */
  sub: string;
  /** Audience */
  aud: string;
  /** Expiration timestamp (seconds since epoch) */
  exp: number;
  /** Issued at timestamp (seconds since epoch) */
  iat: number;
  /** Not before timestamp (seconds since epoch) */
  nbf: number;
  /** Session ID */
  sid: string;
}

/**
 * Standard User Claims
 * Common user information in JWTs
 */
export interface StandardUserClaims extends BaseClerkClaims {
  /** Primary email address */
  email?: string;
  /** Email verified status */
  email_verified?: boolean;
  /** User's full name */
  name?: string;
  /** Primary phone number */
  phone?: string;
  /** Phone verified status */
  phone_verified?: boolean;
  /** User's profile image URL */
  picture?: string;
}

/**
 * Custom Business Logic Claims
 * Extend with your application-specific claims
 */
export interface CustomClaims extends StandardUserClaims {
  /** User role (e.g., 'admin', 'member', 'guest') */
  role?: string;
  /** Organization ID */
  org_id?: string;
  /** Organization role */
  org_role?: string;
  /** Organization slug */
  org_slug?: string;
  /** User permissions array */
  permissions?: string[];
  /** Subscription plan */
  plan?: 'free' | 'pro' | 'enterprise';
  /** Custom metadata object */
  metadata?: Record<string, unknown>;
  /** Account creation timestamp */
  created_at?: number;
}

/**
 * Hasura Integration Claims
 * For Hasura GraphQL Engine integration
 */
export interface HasuraClaims extends BaseClerkClaims {
  'https://hasura.io/jwt/claims': {
    'x-hasura-default-role': string;
    'x-hasura-allowed-roles': string[];
    'x-hasura-user-id': string;
    'x-hasura-org-id'?: string;
    // Add custom Hasura claims as needed
    [key: `x-hasura-${string}`]: string | string[];
  };
  email?: string;
}

/**
 * Supabase Integration Claims
 * For Supabase integration
 */
export interface SupabaseClaims extends BaseClerkClaims {
  /** Authenticated role */
  role: 'authenticated' | 'anon';
  /** Application metadata */
  app_metadata: {
    provider: string;
    providers: string[];
  };
  /** User metadata */
  user_metadata?: Record<string, unknown>;
  email?: string;
  phone?: string;
}

/**
 * Type guard for custom claims
 */
export function hasCustomClaims(claims: unknown): claims is CustomClaims {
  return (
    typeof claims === 'object' &&
    claims !== null &&
    'sub' in claims &&
    typeof (claims as BaseClerkClaims).sub === 'string'
  );
}

/**
 * Type guard for Hasura claims
 */
export function hasHasuraClaims(claims: unknown): claims is HasuraClaims {
  return (
    typeof claims === 'object' &&
    claims !== null &&
    'https://hasura.io/jwt/claims' in claims
  );
}

/**
 * Type guard for Supabase claims
 */
export function hasSupabaseClaims(claims: unknown): claims is SupabaseClaims {
  return (
    typeof claims === 'object' &&
    claims !== null &&
    'role' in claims &&
    'app_metadata' in claims
  );
}

/**
 * Custom Claims Helper
 * Type-safe access to custom claims
 */
export class CustomClaimsHelper {
  constructor(private claims: CustomClaims) {}

  /** Get user ID */
  getUserId(): string {
    return this.claims.sub;
  }

  /** Get user email */
  getEmail(): string | undefined {
    return this.claims.email;
  }

  /** Get user role */
  getRole(): string | undefined {
    return this.claims.role;
  }

  /** Get organization ID */
  getOrgId(): string | undefined {
    return this.claims.org_id;
  }

  /** Get organization role */
  getOrgRole(): string | undefined {
    return this.claims.org_role;
  }

  /** Get permissions */
  getPermissions(): string[] {
    return this.claims.permissions || [];
  }

  /** Check if user has permission */
  hasPermission(permission: string): boolean {
    return this.getPermissions().includes(permission);
  }

  /** Check if user has role */
  hasRole(role: string | string[]): boolean {
    const userRole = this.getRole();
    if (!userRole) return false;

    const allowedRoles = Array.isArray(role) ? role : [role];
    return allowedRoles.includes(userRole);
  }

  /** Check if user is in organization */
  hasOrganization(): boolean {
    return !!this.claims.org_id;
  }

  /** Get subscription plan */
  getPlan(): 'free' | 'pro' | 'enterprise' | undefined {
    return this.claims.plan;
  }

  /** Get custom metadata */
  getMetadata<T = Record<string, unknown>>(): T | undefined {
    return this.claims.metadata as T;
  }

  /** Check if session is expired */
  isExpired(): boolean {
    return Date.now() >= this.claims.exp * 1000;
  }

  /** Get time until expiration in milliseconds */
  getTimeUntilExpiration(): number {
    return Math.max(0, this.claims.exp * 1000 - Date.now());
  }
}

/**
 * JWT Template Configurations
 */

/** Default JWT template */
export const DEFAULT_JWT_TEMPLATE = {
  aud: 'authenticated',
  exp: '{{session.expire_at}}',
  iat: '{{session.created_at}}',
  iss: '{{instance.id}}',
  nbf: '{{session.created_at}}',
  sid: '{{session.id}}',
  sub: '{{user.id}}',
  email: '{{user.primary_email_address}}',
  email_verified: '{{user.primary_email_address_verified}}',
  name: '{{user.full_name}}',
  metadata: '{{user.public_metadata}}',
};

/** Custom business logic template */
export const CUSTOM_JWT_TEMPLATE = {
  ...DEFAULT_JWT_TEMPLATE,
  role: '{{user.public_metadata.role}}',
  org_id: '{{org.id}}',
  org_role: '{{org_membership.role}}',
  org_slug: '{{org.slug}}',
  permissions: '{{org_membership.permissions}}',
  plan: '{{user.public_metadata.subscription_plan}}',
  created_at: '{{user.created_at}}',
};

/** Hasura integration template */
export const HASURA_JWT_TEMPLATE = {
  'https://hasura.io/jwt/claims': {
    'x-hasura-default-role': '{{user.public_metadata.hasura_role}}',
    'x-hasura-allowed-roles': '{{user.public_metadata.hasura_roles}}',
    'x-hasura-user-id': '{{user.id}}',
    'x-hasura-org-id': '{{org.id}}',
  },
  sub: '{{user.id}}',
  email: '{{user.primary_email_address}}',
};

/** Supabase integration template */
export const SUPABASE_JWT_TEMPLATE = {
  aud: 'authenticated',
  exp: '{{session.expire_at}}',
  sub: '{{user.id}}',
  email: '{{user.primary_email_address}}',
  phone: '{{user.primary_phone_number}}',
  app_metadata: {
    provider: 'clerk',
    providers: ['clerk'],
  },
  user_metadata: '{{user.public_metadata}}',
  role: 'authenticated',
};

/**
 * Usage Examples:
 *
 * // In API route (Next.js App Router)
 * import { auth } from '@clerk/nextjs/server';
 * import { CustomClaimsHelper } from '@/lib/custom-claims';
 *
 * export async function GET() {
 *   const { sessionClaims } = await auth();
 *
 *   if (!sessionClaims) {
 *     return Response.json({ error: 'Unauthorized' }, { status: 401 });
 *   }
 *
 *   const claims = new CustomClaimsHelper(sessionClaims as CustomClaims);
 *
 *   // Type-safe access
 *   const userId = claims.getUserId();
 *   const role = claims.getRole();
 *   const permissions = claims.getPermissions();
 *
 *   // Permission checks
 *   if (!claims.hasPermission('read:data')) {
 *     return Response.json({ error: 'Forbidden' }, { status: 403 });
 *   }
 *
 *   // Role-based logic
 *   if (claims.hasRole(['admin', 'moderator'])) {
 *     // Admin/moderator logic
 *   }
 *
 *   return Response.json({ userId, role, permissions });
 * }
 *
 * // Setting custom metadata (server-side)
 * import { clerkClient } from '@clerk/nextjs/server';
 *
 * await clerkClient.users.updateUser(userId, {
 *   publicMetadata: {
 *     role: 'admin',
 *     subscription_plan: 'pro',
 *     permissions: ['read:data', 'write:data'],
 *   },
 * });
 *
 * // User must sign out and sign in again for claims to update
 */

/**
 * Security Notes:
 *
 * 1. NEVER store sensitive data in JWT claims (they're readable by client)
 * 2. Use publicMetadata for claims (not privateMetadata)
 * 3. Keep JWTs small (<4KB recommended)
 * 4. Validate claims server-side, never trust client values
 * 5. Claims are cached in session - require re-auth for updates
 * 6. Use privateMetadata for sensitive data (server-only access)
 */
