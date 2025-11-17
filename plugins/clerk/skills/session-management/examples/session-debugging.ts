// session-debugging.ts
// Debugging utilities and helpers for Clerk session management

'use client';

import { useClerk, useSession, useAuth } from '@clerk/nextjs';
import { useEffect, useState } from 'react';
import type { SessionResource } from '@clerk/types';

/**
 * Session Debug Info
 * Comprehensive session debugging information
 */
export interface SessionDebugInfo {
  // Session identification
  sessionId: string | null;
  userId: string | null;
  status: string | null;

  // Timestamps
  createdAt: string | null;
  lastActiveAt: string | null;
  expireAt: string | null;
  timeUntilExpiration: string | null;

  // Configuration
  multiSession: boolean;
  sessionCount: number;

  // Claims
  claims: Record<string, unknown> | null;

  // Environment
  environment: string;
  publishableKey: string;
}

/**
 * Session Debug Hook
 * Hook for collecting session debugging information
 */
export function useSessionDebug(): SessionDebugInfo {
  const { client } = useClerk();
  const { session } = useSession();
  const { userId } = useAuth();

  const formatTime = (date: Date | null | undefined): string | null => {
    if (!date) return null;
    return date.toISOString();
  };

  const getTimeUntilExpiration = (): string | null => {
    if (!session?.expireAt) return null;

    const ms = session.expireAt.getTime() - Date.now();
    const minutes = Math.floor(ms / 60000);
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);

    if (days > 0) return `${days}d ${hours % 24}h ${minutes % 60}m`;
    if (hours > 0) return `${hours}h ${minutes % 60}m`;
    return `${minutes}m`;
  };

  return {
    sessionId: session?.id || null,
    userId: userId || null,
    status: session?.status || null,
    createdAt: formatTime(session?.createdAt),
    lastActiveAt: formatTime(session?.lastActiveAt),
    expireAt: formatTime(session?.expireAt),
    timeUntilExpiration: getTimeUntilExpiration(),
    multiSession: (client?.sessions?.length || 0) > 1,
    sessionCount: client?.sessions?.length || 0,
    claims: session ? (session as unknown as { __raw: unknown }).__raw : null,
    environment: process.env.NODE_ENV || 'unknown',
    publishableKey:
      process.env.NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY?.slice(0, 20) + '...' ||
      'not set',
  };
}

/**
 * Session Debug Panel Component
 * Visual debugging panel for session information
 */
export function SessionDebugPanel() {
  const debug = useSessionDebug();
  const [expanded, setExpanded] = useState(false);

  return (
    <div
      style={{
        position: 'fixed',
        bottom: '20px',
        right: '20px',
        backgroundColor: '#1a1a1a',
        color: '#fff',
        borderRadius: '8px',
        boxShadow: '0 4px 12px rgba(0,0,0,0.3)',
        fontFamily: 'monospace',
        fontSize: '12px',
        maxWidth: expanded ? '600px' : '200px',
        zIndex: 9999,
      }}
    >
      {/* Header */}
      <div
        onClick={() => setExpanded(!expanded)}
        style={{
          padding: '12px',
          borderBottom: expanded ? '1px solid #333' : 'none',
          cursor: 'pointer',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
        }}
      >
        <div>
          🔍 Session Debug
          {debug.userId && (
            <span
              style={{
                marginLeft: '8px',
                padding: '2px 6px',
                backgroundColor: '#0a0',
                borderRadius: '4px',
                fontSize: '10px',
              }}
            >
              ACTIVE
            </span>
          )}
        </div>
        <div>{expanded ? '▼' : '▶'}</div>
      </div>

      {/* Expanded Content */}
      {expanded && (
        <div style={{ padding: '12px', maxHeight: '400px', overflow: 'auto' }}>
          {/* Session Info */}
          <div style={{ marginBottom: '12px' }}>
            <div style={{ color: '#888', marginBottom: '4px' }}>SESSION</div>
            <div>ID: {debug.sessionId || 'none'}</div>
            <div>User: {debug.userId || 'none'}</div>
            <div>Status: {debug.status || 'none'}</div>
            <div>
              Sessions: {debug.sessionCount}{' '}
              {debug.multiSession && '(multi-session)'}
            </div>
          </div>

          {/* Timestamps */}
          <div style={{ marginBottom: '12px' }}>
            <div style={{ color: '#888', marginBottom: '4px' }}>TIMESTAMPS</div>
            <div>Created: {debug.createdAt || 'n/a'}</div>
            <div>Last Active: {debug.lastActiveAt || 'n/a'}</div>
            <div>Expires: {debug.expireAt || 'n/a'}</div>
            <div
              style={{
                color: debug.timeUntilExpiration ? '#0f0' : '#f00',
              }}
            >
              Time Left: {debug.timeUntilExpiration || 'expired'}
            </div>
          </div>

          {/* Environment */}
          <div style={{ marginBottom: '12px' }}>
            <div style={{ color: '#888', marginBottom: '4px' }}>ENVIRONMENT</div>
            <div>Node Env: {debug.environment}</div>
            <div>Pub Key: {debug.publishableKey}</div>
          </div>

          {/* Claims */}
          {debug.claims && (
            <div>
              <div style={{ color: '#888', marginBottom: '4px' }}>
                CLAIMS (Raw)
              </div>
              <pre
                style={{
                  backgroundColor: '#000',
                  padding: '8px',
                  borderRadius: '4px',
                  overflow: 'auto',
                  maxHeight: '150px',
                  fontSize: '10px',
                }}
              >
                {JSON.stringify(debug.claims, null, 2)}
              </pre>
            </div>
          )}
        </div>
      )}
    </div>
  );
}

/**
 * Session Logger
 * Logs session events to console
 */
export function useSessionLogger() {
  const { session } = useSession();
  const { userId } = useAuth();

  useEffect(() => {
    if (!session) {
      console.log('[Session] No active session');
      return;
    }

    console.group('🔐 Session Debug Info');
    console.log('Session ID:', session.id);
    console.log('User ID:', userId);
    console.log('Status:', session.status);
    console.log('Created:', session.createdAt);
    console.log('Last Active:', session.lastActiveAt);
    console.log('Expires:', session.expireAt);
    console.log(
      'Time Until Expiration:',
      session.expireAt.getTime() - Date.now(),
      'ms'
    );
    console.groupEnd();

    // Log session changes
    const handleTouch = () => {
      console.log('[Session] Session refreshed/touched');
    };

    // Monitor for changes
    const interval = setInterval(() => {
      const now = Date.now();
      const expiresAt = session.expireAt.getTime();

      if (now >= expiresAt) {
        console.warn('[Session] Session has expired!');
      } else if (expiresAt - now < 5 * 60 * 1000) {
        console.warn('[Session] Session expiring soon (< 5 minutes)');
      }
    }, 60000); // Check every minute

    return () => clearInterval(interval);
  }, [session, userId]);
}

/**
 * Session Performance Monitor
 * Tracks session-related performance metrics
 */
export function useSessionPerformance() {
  const [metrics, setMetrics] = useState({
    tokenFetchTime: 0,
    touchLatency: 0,
    lastMeasured: null as Date | null,
  });

  const { session } = useSession();

  const measureTokenFetch = async () => {
    if (!session) return;

    const start = performance.now();
    try {
      await session.getToken();
      const end = performance.now();
      setMetrics((prev) => ({
        ...prev,
        tokenFetchTime: end - start,
        lastMeasured: new Date(),
      }));
      console.log(`[Session] Token fetch: ${end - start}ms`);
    } catch (error) {
      console.error('[Session] Token fetch failed:', error);
    }
  };

  const measureTouch = async () => {
    if (!session) return;

    const start = performance.now();
    try {
      await session.touch();
      const end = performance.now();
      setMetrics((prev) => ({
        ...prev,
        touchLatency: end - start,
        lastMeasured: new Date(),
      }));
      console.log(`[Session] Touch latency: ${end - start}ms`);
    } catch (error) {
      console.error('[Session] Touch failed:', error);
    }
  };

  return {
    metrics,
    measureTokenFetch,
    measureTouch,
  };
}

/**
 * Session State Inspector
 * Detailed inspection of session state
 */
export function SessionStateInspector() {
  const { client } = useClerk();
  const { session } = useSession();
  const [state, setState] = useState<string>('');

  useEffect(() => {
    if (!session || !client) {
      setState('No active session');
      return;
    }

    const inspection = {
      session: {
        id: session.id,
        status: session.status,
        userId: session.userId,
        createdAt: session.createdAt.toISOString(),
        lastActiveAt: session.lastActiveAt.toISOString(),
        expireAt: session.expireAt.toISOString(),
        abandonAt: session.abandonAt?.toISOString() || null,
      },
      client: {
        sessionCount: client.sessions.length,
        activeSessionId: client.session?.id,
        allSessionIds: client.sessions.map((s) => s.id),
      },
      computed: {
        isExpired: Date.now() >= session.expireAt.getTime(),
        timeUntilExpiration: session.expireAt.getTime() - Date.now(),
        timeSinceActivity: Date.now() - session.lastActiveAt.getTime(),
      },
    };

    setState(JSON.stringify(inspection, null, 2));
  }, [session, client]);

  return (
    <div style={{ padding: '20px' }}>
      <h3>Session State Inspector</h3>
      <pre
        style={{
          backgroundColor: '#f5f5f5',
          padding: '16px',
          borderRadius: '8px',
          overflow: 'auto',
          fontSize: '12px',
          fontFamily: 'monospace',
        }}
      >
        {state}
      </pre>
    </div>
  );
}

/**
 * Usage Examples:
 *
 * // Add debug panel to your app (development only)
 * export default function RootLayout({ children }) {
 *   return (
 *     <html>
 *       <body>
 *         {children}
 *         {process.env.NODE_ENV === 'development' && <SessionDebugPanel />}
 *       </body>
 *     </html>
 *   );
 * }
 *
 * // Log session information
 * function MyComponent() {
 *   useSessionLogger();
 *   return <div>Content</div>;
 * }
 *
 * // Monitor performance
 * function PerformanceTest() {
 *   const { metrics, measureTokenFetch } = useSessionPerformance();
 *
 *   return (
 *     <div>
 *       <button onClick={measureTokenFetch}>Test Token Fetch</button>
 *       <p>Last fetch: {metrics.tokenFetchTime}ms</p>
 *     </div>
 *   );
 * }
 *
 * // Inspect state
 * function DebugPage() {
 *   return <SessionStateInspector />;
 * }
 */
