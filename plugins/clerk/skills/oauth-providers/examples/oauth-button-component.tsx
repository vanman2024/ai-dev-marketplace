// Advanced OAuth Button Component Example
// Framework: Next.js 14+ with Clerk
// Features: Loading states, error handling, analytics, custom styling

'use client';

import { SignIn } from '@clerk/nextjs';
import { useState, useCallback } from 'react';
import { trackEvent } from '@/lib/analytics'; // Your analytics implementation

// Provider configuration with branding
const PROVIDER_CONFIG = {
  google: {
    name: 'Google',
    icon: (
      <svg className="w-5 h-5" viewBox="0 0 24 24">
        <path
          fill="currentColor"
          d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
        />
        <path
          fill="currentColor"
          d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
        />
        <path
          fill="currentColor"
          d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
        />
        <path
          fill="currentColor"
          d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
        />
      </svg>
    ),
    bgColor: 'bg-white hover:bg-gray-50',
    textColor: 'text-gray-900',
    borderColor: 'border-gray-300'
  },
  github: {
    name: 'GitHub',
    icon: (
      <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
        <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/>
      </svg>
    ),
    bgColor: 'bg-gray-900 hover:bg-gray-800',
    textColor: 'text-white',
    borderColor: 'border-gray-900'
  },
  discord: {
    name: 'Discord',
    icon: (
      <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
        <path d="M20.317 4.492c-1.53-.69-3.17-1.2-4.885-1.49a.075.075 0 0 0-.079.036c-.21.369-.444.85-.608 1.23a18.566 18.566 0 0 0-5.487 0 12.36 12.36 0 0 0-.617-1.23A.077.077 0 0 0 8.562 3c-1.714.29-3.354.8-4.885 1.491a.07.07 0 0 0-.032.027C.533 9.093-.32 13.555.099 17.961a.08.08 0 0 0 .031.055 20.03 20.03 0 0 0 5.993 2.98.078.078 0 0 0 .084-.026 13.83 13.83 0 0 0 1.226-1.963.074.074 0 0 0-.041-.104 13.201 13.201 0 0 1-1.872-.878.075.075 0 0 1-.008-.125c.126-.093.252-.19.372-.287a.075.075 0 0 1 .078-.01c3.927 1.764 8.18 1.764 12.061 0a.075.075 0 0 1 .079.009c.12.098.245.195.372.288a.075.075 0 0 1-.006.125c-.598.344-1.22.635-1.873.877a.075.075 0 0 0-.041.105c.36.687.772 1.341 1.225 1.962a.077.077 0 0 0 .084.028 19.963 19.963 0 0 0 6.002-2.981.076.076 0 0 0 .032-.054c.5-5.094-.838-9.52-3.549-13.442a.06.06 0 0 0-.031-.028zM8.02 15.278c-1.182 0-2.157-1.069-2.157-2.38 0-1.312.956-2.38 2.157-2.38 1.21 0 2.176 1.077 2.157 2.38 0 1.312-.956 2.38-2.157 2.38zm7.975 0c-1.183 0-2.157-1.069-2.157-2.38 0-1.312.955-2.38 2.157-2.38 1.21 0 2.176 1.077 2.157 2.38 0 1.312-.946 2.38-2.157 2.38z"/>
      </svg>
    ),
    bgColor: 'bg-indigo-600 hover:bg-indigo-700',
    textColor: 'text-white',
    borderColor: 'border-indigo-600'
  },
  microsoft: {
    name: 'Microsoft',
    icon: (
      <svg className="w-5 h-5" viewBox="0 0 24 24">
        <path fill="#f25022" d="M1 1h10v10H1z"/>
        <path fill="#00a4ef" d="M13 1h10v10H13z"/>
        <path fill="#7fba00" d="M1 13h10v10H1z"/>
        <path fill="#ffb900" d="M13 13h10v10H13z"/>
      </svg>
    ),
    bgColor: 'bg-blue-600 hover:bg-blue-700',
    textColor: 'text-white',
    borderColor: 'border-blue-600'
  }
} as const;

type Provider = keyof typeof PROVIDER_CONFIG;

interface OAuthButtonProps {
  provider: Provider;
  onSuccess?: (userId: string) => void;
  onError?: (error: Error) => void;
  className?: string;
  fullWidth?: boolean;
  disabled?: boolean;
}

export function OAuthButton({
  provider,
  onSuccess,
  onError,
  className = '',
  fullWidth = true,
  disabled = false
}: OAuthButtonProps) {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const config = PROVIDER_CONFIG[provider];

  const handleClick = useCallback(async () => {
    try {
      setIsLoading(true);
      setError(null);

      // Track OAuth initiation
      trackEvent('oauth_initiation', {
        provider,
        timestamp: new Date().toISOString()
      });

      // The actual OAuth flow is handled by Clerk
      // This is just for UX feedback
    } catch (err) {
      const error = err instanceof Error ? err : new Error('OAuth failed');
      setError(error.message);

      // Track error
      trackEvent('oauth_error', {
        provider,
        error: error.message,
        timestamp: new Date().toISOString()
      });

      onError?.(error);
    } finally {
      setIsLoading(false);
    }
  }, [provider, onError]);

  return (
    <div className={fullWidth ? 'w-full' : ''}>
      <SignIn.Strategy name={`oauth_${provider}`}>
        <button
          type="button"
          onClick={handleClick}
          disabled={disabled || isLoading}
          className={`
            inline-flex items-center justify-center gap-3
            px-6 py-3 rounded-lg font-medium
            border transition-all duration-200
            disabled:opacity-50 disabled:cursor-not-allowed
            focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-${provider}
            ${config.bgColor}
            ${config.textColor}
            ${config.borderColor}
            ${fullWidth ? 'w-full' : ''}
            ${className}
          `}
          aria-label={`Sign in with ${config.name}`}
        >
          {isLoading ? (
            <svg
              className="animate-spin h-5 w-5"
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
            >
              <circle
                className="opacity-25"
                cx="12"
                cy="12"
                r="10"
                stroke="currentColor"
                strokeWidth="4"
              />
              <path
                className="opacity-75"
                fill="currentColor"
                d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
              />
            </svg>
          ) : (
            config.icon
          )}
          <span>
            {isLoading ? 'Connecting...' : `Continue with ${config.name}`}
          </span>
        </button>
      </SignIn.Strategy>

      {error && (
        <p className="mt-2 text-sm text-red-600" role="alert">
          {error}
        </p>
      )}
    </div>
  );
}

// Multi-provider button group with analytics and error handling
export function OAuthButtonGroup({
  providers = ['google', 'github', 'discord'],
  onSuccess,
  onError
}: {
  providers?: Provider[];
  onSuccess?: (userId: string) => void;
  onError?: (error: Error) => void;
}) {
  return (
    <div className="space-y-3">
      {providers.map((provider) => (
        <OAuthButton
          key={provider}
          provider={provider}
          onSuccess={onSuccess}
          onError={onError}
        />
      ))}
    </div>
  );
}

// Compact icon-only variant
export function OAuthIconButton({
  provider,
  size = 'md'
}: {
  provider: Provider;
  size?: 'sm' | 'md' | 'lg';
}) {
  const config = PROVIDER_CONFIG[provider];

  const sizeClasses = {
    sm: 'w-8 h-8 text-sm',
    md: 'w-10 h-10 text-base',
    lg: 'w-12 h-12 text-lg'
  };

  return (
    <SignIn.Strategy name={`oauth_${provider}`}>
      <button
        type="button"
        title={`Sign in with ${config.name}`}
        className={`
          inline-flex items-center justify-center
          rounded-full
          ${sizeClasses[size]}
          ${config.bgColor}
          ${config.textColor}
          border ${config.borderColor}
          hover:scale-110
          transition-all duration-200
          focus:outline-none focus:ring-2 focus:ring-offset-2
        `}
        aria-label={`Sign in with ${config.name}`}
      >
        {config.icon}
      </button>
    </SignIn.Strategy>
  );
}

// Example usage:
/*
'use client';

import { OAuthButton, OAuthButtonGroup, OAuthIconButton } from '@/components/auth/OAuthButton';

export default function LoginPage() {
  return (
    <div className="max-w-md mx-auto p-6 space-y-8">
      {/* Full button group *\/}
      <div>
        <h2 className="text-xl font-bold mb-4">Sign in with</h2>
        <OAuthButtonGroup
          providers={['google', 'github', 'discord']}
          onSuccess={(userId) => {
            console.log('Authenticated:', userId);
            window.location.href = '/dashboard';
          }}
          onError={(error) => {
            console.error('Auth failed:', error);
          }}
        />
      </div>

      {/* Individual buttons *\/}
      <div className="space-y-3">
        <OAuthButton provider="google" />
        <OAuthButton provider="github" />
      </div>

      {/* Icon-only buttons *\/}
      <div className="flex gap-3 justify-center">
        <OAuthIconButton provider="google" size="lg" />
        <OAuthIconButton provider="github" size="lg" />
        <OAuthIconButton provider="discord" size="lg" />
        <OAuthIconButton provider="microsoft" size="lg" />
      </div>
    </div>
  );
}
*/
