// multi-session.tsx
// Multi-session management UI component

'use client';

import { useClerk, useUser } from '@clerk/nextjs';
import { useState } from 'react';
import type { SessionResource } from '@clerk/types';

/**
 * Session Card Component
 * Displays individual session information
 */
function SessionCard({
  session,
  isActive,
  onSwitch,
  onSignOut,
}: {
  session: SessionResource;
  isActive: boolean;
  onSwitch: () => void;
  onSignOut: () => void;
}) {
  const [loading, setLoading] = useState(false);

  const handleSwitch = async () => {
    setLoading(true);
    try {
      await onSwitch();
    } finally {
      setLoading(false);
    }
  };

  const handleSignOut = async () => {
    setLoading(true);
    try {
      await onSignOut();
    } finally {
      setLoading(false);
    }
  };

  // Format last active time
  const lastActive = session.lastActiveAt
    ? new Date(session.lastActiveAt).toLocaleString()
    : 'Unknown';

  const expires = session.expireAt
    ? new Date(session.expireAt).toLocaleString()
    : 'Unknown';

  return (
    <div
      style={{
        border: isActive ? '2px solid #0070f3' : '1px solid #ccc',
        borderRadius: '8px',
        padding: '16px',
        marginBottom: '12px',
        backgroundColor: isActive ? '#f0f8ff' : '#fff',
      }}
    >
      <div style={{ marginBottom: '8px' }}>
        <strong>Session ID:</strong> {session.id.slice(0, 16)}...
        {isActive && (
          <span
            style={{
              marginLeft: '8px',
              padding: '2px 8px',
              backgroundColor: '#0070f3',
              color: '#fff',
              borderRadius: '4px',
              fontSize: '12px',
            }}
          >
            Active
          </span>
        )}
      </div>

      <div style={{ fontSize: '14px', color: '#666', marginBottom: '12px' }}>
        <div>Status: {session.status}</div>
        <div>Last active: {lastActive}</div>
        <div>Expires: {expires}</div>
      </div>

      <div style={{ display: 'flex', gap: '8px' }}>
        {!isActive && (
          <button
            onClick={handleSwitch}
            disabled={loading}
            style={{
              padding: '8px 16px',
              backgroundColor: '#0070f3',
              color: '#fff',
              border: 'none',
              borderRadius: '4px',
              cursor: loading ? 'not-allowed' : 'pointer',
              opacity: loading ? 0.6 : 1,
            }}
          >
            {loading ? 'Switching...' : 'Switch to this session'}
          </button>
        )}
        <button
          onClick={handleSignOut}
          disabled={loading}
          style={{
            padding: '8px 16px',
            backgroundColor: '#fff',
            color: '#d32f2f',
            border: '1px solid #d32f2f',
            borderRadius: '4px',
            cursor: loading ? 'not-allowed' : 'pointer',
            opacity: loading ? 0.6 : 1,
          }}
        >
          {loading ? 'Signing out...' : 'Sign out'}
        </button>
      </div>
    </div>
  );
}

/**
 * Multi-Session Manager Component
 * Main component for managing multiple active sessions
 */
export function MultiSessionManager() {
  const { client } = useClerk();
  const { user } = useUser();
  const [error, setError] = useState<string | null>(null);

  if (!client || !user) {
    return <div>Loading...</div>;
  }

  const sessions = client.sessions || [];
  const activeSessionId = client.session?.id;

  // Switch to a different session
  const handleSwitch = async (sessionId: string) => {
    try {
      setError(null);
      await client.setActiveSession(sessionId);
      // Page will re-render with new active session
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to switch session');
    }
  };

  // Sign out of a specific session
  const handleSignOut = async (sessionId: string) => {
    try {
      setError(null);
      const session = sessions.find((s) => s.id === sessionId);
      if (session) {
        await session.remove();
        // If it was the active session, user will be signed out
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to sign out');
    }
  };

  // Sign out of all other sessions
  const handleSignOutOthers = async () => {
    try {
      setError(null);
      const otherSessions = sessions.filter((s) => s.id !== activeSessionId);

      await Promise.all(otherSessions.map((session) => session.remove()));
    } catch (err) {
      setError(
        err instanceof Error ? err.message : 'Failed to sign out other sessions'
      );
    }
  };

  return (
    <div style={{ maxWidth: '600px', margin: '0 auto', padding: '20px' }}>
      <h2>Active Sessions</h2>
      <p style={{ color: '#666', marginBottom: '20px' }}>
        You have {sessions.length} active session{sessions.length !== 1 ? 's' : ''}
      </p>

      {error && (
        <div
          style={{
            padding: '12px',
            backgroundColor: '#fee',
            border: '1px solid #d32f2f',
            borderRadius: '4px',
            marginBottom: '16px',
            color: '#d32f2f',
          }}
        >
          {error}
        </div>
      )}

      {sessions.length > 1 && (
        <button
          onClick={handleSignOutOthers}
          style={{
            padding: '10px 20px',
            backgroundColor: '#d32f2f',
            color: '#fff',
            border: 'none',
            borderRadius: '4px',
            cursor: 'pointer',
            marginBottom: '20px',
          }}
        >
          Sign out all other sessions
        </button>
      )}

      <div>
        {sessions.map((session) => (
          <SessionCard
            key={session.id}
            session={session}
            isActive={session.id === activeSessionId}
            onSwitch={() => handleSwitch(session.id)}
            onSignOut={() => handleSignOut(session.id)}
          />
        ))}
      </div>

      {sessions.length === 0 && (
        <div
          style={{
            padding: '40px',
            textAlign: 'center',
            color: '#666',
            border: '1px dashed #ccc',
            borderRadius: '8px',
          }}
        >
          No active sessions
        </div>
      )}
    </div>
  );
}

/**
 * Usage in your page/component:
 *
 * ```tsx
 * import { MultiSessionManager } from '@/components/MultiSessionManager';
 *
 * export default function SessionsPage() {
 *   return (
 *     <div>
 *       <h1>Manage Your Sessions</h1>
 *       <MultiSessionManager />
 *     </div>
 *   );
 * }
 * ```
 */

/**
 * Session Information Component
 * Lightweight display of current session info
 */
export function SessionInfo() {
  const { client } = useClerk();
  const session = client?.session;

  if (!session) {
    return <div>No active session</div>;
  }

  const timeUntilExpiration = session.expireAt
    ? session.expireAt.getTime() - Date.now()
    : 0;

  const hours = Math.floor(timeUntilExpiration / (1000 * 60 * 60));
  const minutes = Math.floor((timeUntilExpiration % (1000 * 60 * 60)) / (1000 * 60));

  return (
    <div
      style={{
        padding: '12px',
        backgroundColor: '#f5f5f5',
        borderRadius: '4px',
        fontSize: '14px',
      }}
    >
      <div>
        <strong>Session:</strong> {session.id.slice(0, 16)}...
      </div>
      <div>
        <strong>Status:</strong> {session.status}
      </div>
      <div>
        <strong>Expires in:</strong> {hours}h {minutes}m
      </div>
      <button
        onClick={() => session.touch()}
        style={{
          marginTop: '8px',
          padding: '6px 12px',
          backgroundColor: '#0070f3',
          color: '#fff',
          border: 'none',
          borderRadius: '4px',
          cursor: 'pointer',
          fontSize: '12px',
        }}
      >
        Extend session
      </button>
    </div>
  );
}

/**
 * Multi-Session Configuration Notes:
 *
 * 1. Enable in Dashboard:
 *    - Go to Settings → Sessions
 *    - Set "Multi-session handling" to "Allow multiple sessions"
 *
 * 2. Security Considerations:
 *    - Each session has its own expiration
 *    - Revoking one session doesn't affect others
 *    - Active session can be switched without re-authentication
 *
 * 3. Common Use Cases:
 *    - Consumer apps: Enable (users on multiple devices)
 *    - Enterprise apps: Consider disabling (tighter security)
 *    - Banking/healthcare: Disable (single session only)
 *
 * 4. Session Limits:
 *    - Clerk enforces reasonable limits on concurrent sessions
 *    - Old sessions automatically expire based on configuration
 *    - Users can manually revoke sessions
 */
