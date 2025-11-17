// session-types.ts
// TypeScript type definitions for Clerk session objects

/**
 * Session Status
 * Possible states of a Clerk session
 */
export type SessionStatus =
  | 'abandoned'
  | 'active'
  | 'ended'
  | 'expired'
  | 'removed'
  | 'replaced'
  | 'revoked';

/**
 * Session Resource Interface
 * Complete type definition for Clerk session objects
 */
export interface SessionResource {
  /** Unique session identifier */
  id: string;

  /** Current session status */
  status: SessionStatus;

  /** User ID associated with this session */
  userId: string;

  /** Timestamp when session was created */
  createdAt: Date;

  /** Timestamp when session was last updated */
  updatedAt: Date;

  /** Timestamp when session was last active */
  lastActiveAt: Date;

  /** Timestamp when session will expire */
  expireAt: Date;

  /** Timestamp when session was abandoned (if applicable) */
  abandonAt: Date | null;

  /** Session claims (JWT payload) */
  publicUserData?: {
    firstName: string | null;
    lastName: string | null;
    imageUrl: string;
    hasImage: boolean;
    identifier: string;
  };

  /** Last active organization ID */
  lastActiveOrganizationId: string | null;

  /** Last active token (JWT) */
  lastActiveToken?: {
    jwt: string;
    object: 'token';
  };

  /** Factors used for this session (authentication methods) */
  factors?: Array<{
    id: string;
    strategy: string;
    verification?: unknown;
  }>;

  /**
   * Extend session lifetime
   * Refreshes the session and updates expireAt
   */
  touch(): Promise<SessionResource>;

  /**
   * End the session
   * Marks session as ended and clears tokens
   */
  end(): Promise<SessionResource>;

  /**
   * Remove the session
   * Permanently removes session from client
   */
  remove(): Promise<void>;

  /**
   * Get token for this session
   * Returns JWT for API calls
   */
  getToken(options?: GetTokenOptions): Promise<string | null>;

  /**
   * Check if session is active
   */
  isActive(): boolean;
}

/**
 * Get Token Options
 */
export interface GetTokenOptions {
  /** Template name for custom JWT claims */
  template?: string;

  /** Throw error if token generation fails (default: false) */
  throwOnError?: boolean;

  /** Skip cache and force new token generation */
  skipCache?: boolean;

  /** Legacy option for backward compatibility */
  leewayInSeconds?: number;
}

/**
 * Client Resource Interface
 * The Clerk client managing sessions
 */
export interface ClientResource {
  /** All active sessions */
  sessions: SessionResource[];

  /** Currently active session */
  session: SessionResource | null;

  /** Sign in attempt in progress */
  signIn?: unknown;

  /** Sign up attempt in progress */
  signUp?: unknown;

  /** User object for active session */
  user?: unknown;

  /** Set a specific session as active */
  setActiveSession(sessionId: string | SessionResource): Promise<void>;

  /** Create a new session token */
  createSessionToken(options?: GetTokenOptions): Promise<string>;

  /** Sign out of all sessions */
  signOut(): Promise<void>;

  /** Sign out of specific session */
  signOutOne(sessionId: string): Promise<void>;
}

/**
 * Session Verification Response
 */
export interface SessionVerificationResponse {
  /** Whether session is valid */
  valid: boolean;

  /** User ID if valid */
  userId?: string;

  /** Session ID if valid */
  sessionId?: string;

  /** JWT claims if valid */
  claims?: Record<string, unknown>;

  /** Error message if invalid */
  error?: string;

  /** Error code if invalid */
  code?: string;
}

/**
 * Session Configuration
 */
export interface SessionConfiguration {
  /** Session lifetime in seconds */
  lifetime: number;

  /** Maximum session lifetime in seconds */
  maxLifetime: number;

  /** Inactivity timeout in seconds (0 = disabled) */
  inactivityTimeout: number;

  /** Allow multiple concurrent sessions */
  multiSession: boolean;

  /** Automatically refresh sessions */
  autoRefresh: boolean;

  /** Refresh threshold (percentage of lifetime) */
  refreshThreshold: number;
}

/**
 * Session Event Types
 */
export type SessionEvent =
  | 'session:created'
  | 'session:active'
  | 'session:ended'
  | 'session:expired'
  | 'session:removed'
  | 'session:revoked'
  | 'session:refreshed'
  | 'session:touched';

/**
 * Session Event Handler
 */
export type SessionEventHandler = (session: SessionResource) => void;

/**
 * Session Manager Interface
 * Helper for managing session lifecycle
 */
export interface SessionManager {
  /** Current session */
  session: SessionResource | null;

  /** Check if session is valid */
  isValid(): boolean;

  /** Check if session is expired */
  isExpired(): boolean;

  /** Check if session needs refresh */
  needsRefresh(): boolean;

  /** Refresh session */
  refresh(): Promise<void>;

  /** End session */
  end(): Promise<void>;

  /** Get time until expiration */
  timeUntilExpiration(): number;

  /** Get time since last activity */
  timeSinceActivity(): number;

  /** Add event listener */
  on(event: SessionEvent, handler: SessionEventHandler): void;

  /** Remove event listener */
  off(event: SessionEvent, handler: SessionEventHandler): void;
}

/**
 * Type guards
 */

export function isActiveSession(
  session: SessionResource | null
): session is SessionResource {
  return session !== null && session.status === 'active';
}

export function isExpiredSession(session: SessionResource | null): boolean {
  if (!session) return true;
  return (
    session.status === 'expired' ||
    session.status === 'ended' ||
    Date.now() >= session.expireAt.getTime()
  );
}

export function isValidSession(session: SessionResource | null): boolean {
  return isActiveSession(session) && !isExpiredSession(session);
}

/**
 * Session utilities
 */

export function getTimeUntilExpiration(session: SessionResource): number {
  return Math.max(0, session.expireAt.getTime() - Date.now());
}

export function getTimeSinceActivity(session: SessionResource): number {
  return Date.now() - session.lastActiveAt.getTime();
}

export function formatSessionTime(milliseconds: number): string {
  const seconds = Math.floor(milliseconds / 1000);
  const minutes = Math.floor(seconds / 60);
  const hours = Math.floor(minutes / 60);
  const days = Math.floor(hours / 24);

  if (days > 0) return `${days}d ${hours % 24}h`;
  if (hours > 0) return `${hours}h ${minutes % 60}m`;
  if (minutes > 0) return `${minutes}m ${seconds % 60}s`;
  return `${seconds}s`;
}

/**
 * Usage Examples:
 *
 * // Type-safe session handling
 * function handleSession(session: SessionResource | null) {
 *   if (!isValidSession(session)) {
 *     console.log('Invalid session');
 *     return;
 *   }
 *
 *   const timeLeft = getTimeUntilExpiration(session);
 *   console.log(`Session expires in ${formatSessionTime(timeLeft)}`);
 *
 *   if (timeLeft < 5 * 60 * 1000) {
 *     session.touch(); // Refresh if < 5 minutes left
 *   }
 * }
 *
 * // Get token with custom template
 * async function getCustomToken(session: SessionResource) {
 *   const token = await session.getToken({
 *     template: 'custom-claims',
 *     throwOnError: true,
 *   });
 *   return token;
 * }
 *
 * // Client management
 * async function switchSession(
 *   client: ClientResource,
 *   sessionId: string
 * ) {
 *   await client.setActiveSession(sessionId);
 * }
 */
