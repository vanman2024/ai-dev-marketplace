// session-config.ts
// Clerk session configuration patterns

/**
 * Session Configuration Types
 */

export interface SessionConfig {
  /** Session lifetime in seconds (default: 7 days) */
  sessionLifetime: number;
  /** Maximum session lifetime in seconds (default: 30 days) */
  maxSessionLifetime: number;
  /** Inactivity timeout in seconds (0 = no timeout) */
  inactivityTimeout: number;
  /** Enable multi-session mode */
  multiSession: boolean;
  /** Auto-refresh session before expiration */
  autoRefresh: boolean;
  /** Refresh threshold as percentage of session lifetime (0-100) */
  refreshThresholdPercent: number;
}

/**
 * Default session configuration
 */
export const DEFAULT_SESSION_CONFIG: SessionConfig = {
  sessionLifetime: 7 * 24 * 60 * 60, // 7 days
  maxSessionLifetime: 30 * 24 * 60 * 60, // 30 days
  inactivityTimeout: 0, // No inactivity timeout
  multiSession: true, // Allow multiple devices
  autoRefresh: true, // Enable auto-refresh
  refreshThresholdPercent: 10, // Refresh in last 10% of session
};

/**
 * Production session configuration
 * More restrictive for security
 */
export const PRODUCTION_SESSION_CONFIG: SessionConfig = {
  sessionLifetime: 3 * 24 * 60 * 60, // 3 days
  maxSessionLifetime: 7 * 24 * 60 * 60, // 7 days
  inactivityTimeout: 2 * 60 * 60, // 2 hours
  multiSession: false, // Single session only
  autoRefresh: true,
  refreshThresholdPercent: 15, // More aggressive refresh
};

/**
 * Development session configuration
 * Longer sessions for easier development
 */
export const DEVELOPMENT_SESSION_CONFIG: SessionConfig = {
  sessionLifetime: 30 * 24 * 60 * 60, // 30 days
  maxSessionLifetime: 90 * 24 * 60 * 60, // 90 days
  inactivityTimeout: 0, // No timeout
  multiSession: true,
  autoRefresh: false, // Manual testing
  refreshThresholdPercent: 5,
};

/**
 * High-security session configuration
 * For sensitive applications (banking, healthcare, etc.)
 */
export const HIGH_SECURITY_SESSION_CONFIG: SessionConfig = {
  sessionLifetime: 15 * 60, // 15 minutes
  maxSessionLifetime: 60 * 60, // 1 hour
  inactivityTimeout: 5 * 60, // 5 minutes
  multiSession: false, // Prevent session hijacking
  autoRefresh: false, // Require explicit re-authentication
  refreshThresholdPercent: 20,
};

/**
 * Session configuration helper
 */
export class SessionConfigHelper {
  constructor(private config: SessionConfig) {}

  /**
   * Get refresh time in milliseconds
   */
  getRefreshTime(): number {
    const sessionMs = this.config.sessionLifetime * 1000;
    const threshold = this.config.refreshThresholdPercent / 100;
    return sessionMs * (1 - threshold);
  }

  /**
   * Calculate when to refresh session
   */
  getRefreshTimestamp(sessionCreatedAt: Date): Date {
    const refreshTime = this.getRefreshTime();
    return new Date(sessionCreatedAt.getTime() + refreshTime);
  }

  /**
   * Check if session should be refreshed
   */
  shouldRefresh(session: { createdAt: Date; expireAt: Date }): boolean {
    if (!this.config.autoRefresh) return false;

    const now = Date.now();
    const refreshAt = this.getRefreshTimestamp(session.createdAt).getTime();

    return now >= refreshAt && now < session.expireAt.getTime();
  }

  /**
   * Check if session is expired
   */
  isExpired(session: { expireAt: Date }): boolean {
    return Date.now() >= session.expireAt.getTime();
  }

  /**
   * Get time until expiration in milliseconds
   */
  getTimeUntilExpiration(session: { expireAt: Date }): number {
    return Math.max(0, session.expireAt.getTime() - Date.now());
  }

  /**
   * Format time remaining
   */
  formatTimeRemaining(session: { expireAt: Date }): string {
    const ms = this.getTimeUntilExpiration(session);

    if (ms === 0) return 'Expired';

    const minutes = Math.floor(ms / 60000);
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);

    if (days > 0) return `${days}d ${hours % 24}h`;
    if (hours > 0) return `${hours}h ${minutes % 60}m`;
    return `${minutes}m`;
  }
}

/**
 * Environment-based configuration selector
 */
export function getSessionConfig(env?: string): SessionConfig {
  const environment = env || process.env.NODE_ENV || 'development';

  switch (environment) {
    case 'production':
      return PRODUCTION_SESSION_CONFIG;
    case 'development':
      return DEVELOPMENT_SESSION_CONFIG;
    case 'high-security':
      return HIGH_SECURITY_SESSION_CONFIG;
    default:
      return DEFAULT_SESSION_CONFIG;
  }
}

/**
 * Usage Examples:
 *
 * // Get configuration for current environment
 * const config = getSessionConfig();
 * const helper = new SessionConfigHelper(config);
 *
 * // Check if session needs refresh
 * if (helper.shouldRefresh(session)) {
 *   await session.touch();
 * }
 *
 * // Display time remaining
 * const timeLeft = helper.formatTimeRemaining(session);
 * console.log(`Session expires in ${timeLeft}`);
 *
 * // Custom configuration
 * const customConfig: SessionConfig = {
 *   sessionLifetime: 24 * 60 * 60, // 1 day
 *   maxSessionLifetime: 7 * 24 * 60 * 60, // 7 days
 *   inactivityTimeout: 60 * 60, // 1 hour
 *   multiSession: true,
 *   autoRefresh: true,
 *   refreshThresholdPercent: 20,
 * };
 * const customHelper = new SessionConfigHelper(customConfig);
 */
