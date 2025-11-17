// session-refresh.ts
// Session refresh patterns and utilities

'use client';

import { useSession } from '@clerk/nextjs';
import { useEffect, useState, useCallback } from 'react';

/**
 * Session Refresh Hook
 * Automatically refreshes session before expiration
 */
export function useSessionRefresh(options?: {
  /** Refresh threshold as percentage of session lifetime (default: 10) */
  thresholdPercent?: number;
  /** Enable auto-refresh (default: true) */
  enabled?: boolean;
  /** Callback when session is refreshed */
  onRefresh?: () => void;
  /** Callback when refresh fails */
  onError?: (error: Error) => void;
}) {
  const { session } = useSession();
  const {
    thresholdPercent = 10,
    enabled = true,
    onRefresh,
    onError,
  } = options || {};

  useEffect(() => {
    if (!session || !enabled) return;

    const expiresAt = session.expireAt?.getTime();
    const createdAt = session.createdAt?.getTime();

    if (!expiresAt || !createdAt) return;

    // Calculate refresh time
    const sessionDuration = expiresAt - createdAt;
    const refreshThreshold = thresholdPercent / 100;
    const refreshAt = expiresAt - sessionDuration * refreshThreshold;
    const now = Date.now();

    // If we're already past refresh time, refresh immediately
    if (now >= refreshAt && now < expiresAt) {
      session
        .touch()
        .then(() => {
          console.log('[Session] Refreshed immediately');
          onRefresh?.();
        })
        .catch((error) => {
          console.error('[Session] Immediate refresh failed:', error);
          onError?.(error);
        });
      return;
    }

    // Schedule refresh
    const timeUntilRefresh = refreshAt - now;
    if (timeUntilRefresh > 0) {
      const timeout = setTimeout(() => {
        session
          .touch()
          .then(() => {
            console.log('[Session] Refreshed at scheduled time');
            onRefresh?.();
          })
          .catch((error) => {
            console.error('[Session] Scheduled refresh failed:', error);
            onError?.(error);
          });
      }, timeUntilRefresh);

      return () => clearTimeout(timeout);
    }
  }, [session, thresholdPercent, enabled, onRefresh, onError]);

  return session;
}

/**
 * Manual Session Refresh Hook
 * Provides manual control over session refresh
 */
export function useManualSessionRefresh() {
  const { session } = useSession();
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [lastRefreshed, setLastRefreshed] = useState<Date | null>(null);

  const refresh = useCallback(async () => {
    if (!session || isRefreshing) return;

    setIsRefreshing(true);
    try {
      await session.touch();
      setLastRefreshed(new Date());
      console.log('[Session] Manual refresh successful');
    } catch (error) {
      console.error('[Session] Manual refresh failed:', error);
      throw error;
    } finally {
      setIsRefreshing(false);
    }
  }, [session, isRefreshing]);

  return {
    refresh,
    isRefreshing,
    lastRefreshed,
    canRefresh: !!session && !isRefreshing,
  };
}

/**
 * Session Countdown Component
 * Displays time until session expiration with auto-refresh
 */
export function SessionCountdown({
  autoRefresh = true,
  thresholdPercent = 10,
}: {
  autoRefresh?: boolean;
  thresholdPercent?: number;
}) {
  const { session } = useSession();
  const [timeLeft, setTimeLeft] = useState<number>(0);
  const [refreshed, setRefreshed] = useState(false);

  // Auto-refresh if enabled
  useSessionRefresh({
    enabled: autoRefresh,
    thresholdPercent,
    onRefresh: () => setRefreshed(true),
  });

  // Update countdown every second
  useEffect(() => {
    if (!session?.expireAt) return;

    const interval = setInterval(() => {
      const now = Date.now();
      const expiresAt = session.expireAt.getTime();
      const left = Math.max(0, expiresAt - now);
      setTimeLeft(left);

      if (left === 0) {
        console.log('[Session] Expired');
      }
    }, 1000);

    return () => clearInterval(interval);
  }, [session]);

  // Reset refreshed flag after a delay
  useEffect(() => {
    if (refreshed) {
      const timeout = setTimeout(() => setRefreshed(false), 3000);
      return () => clearTimeout(timeout);
    }
  }, [refreshed]);

  if (!session) {
    return <div>No active session</div>;
  }

  const minutes = Math.floor(timeLeft / 60000);
  const seconds = Math.floor((timeLeft % 60000) / 1000);

  const isExpiringSoon = minutes < 5;

  return (
    <div
      style={{
        padding: '12px',
        backgroundColor: isExpiringSoon ? '#fff3cd' : '#f5f5f5',
        border: `1px solid ${isExpiringSoon ? '#ffc107' : '#ddd'}`,
        borderRadius: '4px',
        fontSize: '14px',
      }}
    >
      <div style={{ fontWeight: 'bold', marginBottom: '4px' }}>
        Session expires in: {minutes}m {seconds}s
      </div>
      {isExpiringSoon && (
        <div style={{ color: '#856404', fontSize: '12px' }}>
          ⚠️ Session expiring soon
        </div>
      )}
      {refreshed && (
        <div style={{ color: '#28a745', fontSize: '12px', marginTop: '4px' }}>
          ✓ Session refreshed
        </div>
      )}
    </div>
  );
}

/**
 * Inactivity Monitor Hook
 * Tracks user activity and refreshes session on activity
 */
export function useInactivityMonitor(options?: {
  /** Inactivity timeout in milliseconds (default: 15 minutes) */
  timeout?: number;
  /** Events to listen for (default: mousemove, keydown, click, scroll) */
  events?: string[];
  /** Refresh session on activity (default: true) */
  refreshOnActivity?: boolean;
  /** Callback when inactivity timeout reached */
  onInactive?: () => void;
}) {
  const { session } = useSession();
  const {
    timeout = 15 * 60 * 1000, // 15 minutes
    events = ['mousemove', 'keydown', 'click', 'scroll', 'touchstart'],
    refreshOnActivity = true,
    onInactive,
  } = options || {};

  const [lastActivity, setLastActivity] = useState<Date>(new Date());
  const [isInactive, setIsInactive] = useState(false);

  useEffect(() => {
    let inactivityTimer: NodeJS.Timeout;

    const resetTimer = () => {
      setLastActivity(new Date());
      setIsInactive(false);

      // Refresh session if enabled
      if (refreshOnActivity && session) {
        session.touch().catch((error) => {
          console.error('[Session] Activity refresh failed:', error);
        });
      }

      // Reset inactivity timer
      clearTimeout(inactivityTimer);
      inactivityTimer = setTimeout(() => {
        setIsInactive(true);
        onInactive?.();
        console.log('[Session] User inactive for', timeout / 1000, 'seconds');
      }, timeout);
    };

    // Set initial timer
    resetTimer();

    // Add event listeners
    events.forEach((event) => {
      window.addEventListener(event, resetTimer);
    });

    // Cleanup
    return () => {
      clearTimeout(inactivityTimer);
      events.forEach((event) => {
        window.removeEventListener(event, resetTimer);
      });
    };
  }, [session, timeout, refreshOnActivity, onInactive, events]);

  return {
    lastActivity,
    isInactive,
    timeSinceLastActivity: Date.now() - lastActivity.getTime(),
  };
}

/**
 * Inactivity Warning Component
 * Warns user before session expires due to inactivity
 */
export function InactivityWarning({
  warningThreshold = 5 * 60 * 1000, // 5 minutes
  inactivityTimeout = 15 * 60 * 1000, // 15 minutes
}: {
  warningThreshold?: number;
  inactivityTimeout?: number;
}) {
  const [showWarning, setShowWarning] = useState(false);
  const { refresh } = useManualSessionRefresh();

  const { timeSinceLastActivity, isInactive } = useInactivityMonitor({
    timeout: inactivityTimeout,
    refreshOnActivity: true,
  });

  // Show warning when approaching inactivity timeout
  useEffect(() => {
    const timeUntilInactive = inactivityTimeout - timeSinceLastActivity;
    setShowWarning(
      timeUntilInactive > 0 && timeUntilInactive <= warningThreshold
    );
  }, [timeSinceLastActivity, inactivityTimeout, warningThreshold]);

  if (!showWarning) return null;

  const secondsLeft = Math.ceil(
    (inactivityTimeout - timeSinceLastActivity) / 1000
  );

  return (
    <div
      style={{
        position: 'fixed',
        bottom: '20px',
        right: '20px',
        padding: '16px',
        backgroundColor: '#fff3cd',
        border: '2px solid #ffc107',
        borderRadius: '8px',
        boxShadow: '0 4px 12px rgba(0,0,0,0.15)',
        maxWidth: '300px',
        zIndex: 1000,
      }}
    >
      <div style={{ fontWeight: 'bold', marginBottom: '8px' }}>
        ⚠️ Session Expiring
      </div>
      <div style={{ fontSize: '14px', marginBottom: '12px' }}>
        Your session will expire in {secondsLeft} seconds due to inactivity.
      </div>
      <button
        onClick={() => {
          refresh();
          setShowWarning(false);
        }}
        style={{
          padding: '8px 16px',
          backgroundColor: '#0070f3',
          color: '#fff',
          border: 'none',
          borderRadius: '4px',
          cursor: 'pointer',
          width: '100%',
        }}
      >
        Stay Logged In
      </button>
    </div>
  );
}

/**
 * Usage Examples:
 *
 * // Auto-refresh in root layout
 * export default function RootLayout({ children }) {
 *   useSessionRefresh({ thresholdPercent: 10 });
 *   return <html>{children}</html>;
 * }
 *
 * // Manual refresh button
 * function MyComponent() {
 *   const { refresh, isRefreshing } = useManualSessionRefresh();
 *   return (
 *     <button onClick={refresh} disabled={isRefreshing}>
 *       {isRefreshing ? 'Refreshing...' : 'Refresh Session'}
 *     </button>
 *   );
 * }
 *
 * // Session countdown display
 * function Dashboard() {
 *   return (
 *     <div>
 *       <SessionCountdown autoRefresh={true} thresholdPercent={10} />
 *       <InactivityWarning />
 *     </div>
 *   );
 * }
 *
 * // Inactivity monitoring
 * function App() {
 *   useInactivityMonitor({
 *     timeout: 10 * 60 * 1000, // 10 minutes
 *     onInactive: () => {
 *       console.log('User has been inactive');
 *       // Optionally sign out or show warning
 *     },
 *   });
 *   return <YourApp />;
 * }
 */
