// Multi-Provider OAuth Authentication Buttons
// Framework: Next.js + Clerk
// Documentation: https://clerk.com/docs/components/authentication/sign-in

'use client';

import { SignIn } from '@clerk/nextjs';
import { useState } from 'react';

export interface AuthButtonsProps {
  // Which providers to display
  providers?: Array<'google' | 'github' | 'discord' | 'microsoft' | 'apple' | 'facebook' | 'linkedin' | 'twitter'>;

  // Layout orientation
  orientation?: 'vertical' | 'horizontal';

  // Button styling
  className?: string;

  // Show divider between providers
  showDivider?: boolean;

  // Callback after successful authentication
  onSuccess?: (userId: string) => void;

  // Callback on error
  onError?: (error: Error) => void;
}

export function AuthButtons({
  providers = ['google', 'github', 'discord'],
  orientation = 'vertical',
  className = '',
  showDivider = true,
  onSuccess,
  onError
}: AuthButtonsProps) {
  const [loading, setLoading] = useState<string | null>(null);

  const providerConfig = {
    google: {
      name: 'Google',
      icon: '🔍',
      color: 'bg-white hover:bg-gray-50 border border-gray-300 text-gray-700'
    },
    github: {
      name: 'GitHub',
      icon: '🐙',
      color: 'bg-gray-900 hover:bg-gray-800 text-white'
    },
    discord: {
      name: 'Discord',
      icon: '💬',
      color: 'bg-indigo-600 hover:bg-indigo-700 text-white'
    },
    microsoft: {
      name: 'Microsoft',
      icon: '🪟',
      color: 'bg-blue-600 hover:bg-blue-700 text-white'
    },
    apple: {
      name: 'Apple',
      icon: '🍎',
      color: 'bg-black hover:bg-gray-900 text-white'
    },
    facebook: {
      name: 'Facebook',
      icon: '📘',
      color: 'bg-blue-600 hover:bg-blue-700 text-white'
    },
    linkedin: {
      name: 'LinkedIn',
      icon: '💼',
      color: 'bg-blue-700 hover:bg-blue-800 text-white'
    },
    twitter: {
      name: 'Twitter',
      icon: '🐦',
      color: 'bg-sky-500 hover:bg-sky-600 text-white'
    }
  };

  const containerClass = orientation === 'vertical'
    ? 'flex flex-col space-y-3'
    : 'flex flex-row space-x-3';

  return (
    <SignIn.Root>
      <SignIn.Step name="start">
        <div className={`${containerClass} ${className}`}>
          {providers.map((provider, index) => {
            const config = providerConfig[provider];
            const isLoading = loading === provider;

            return (
              <div key={provider}>
                <SignIn.Strategy name={`oauth_${provider}`}>
                  <button
                    type="button"
                    disabled={isLoading || loading !== null}
                    onClick={() => setLoading(provider)}
                    className={`
                      w-full px-6 py-3 rounded-lg font-medium
                      flex items-center justify-center gap-3
                      transition-all duration-200
                      disabled:opacity-50 disabled:cursor-not-allowed
                      ${config.color}
                    `}
                  >
                    {isLoading ? (
                      <span className="animate-spin">⏳</span>
                    ) : (
                      <span>{config.icon}</span>
                    )}
                    <span>
                      {isLoading ? 'Connecting...' : `Continue with ${config.name}`}
                    </span>
                  </button>
                </SignIn.Strategy>

                {showDivider && index < providers.length - 1 && (
                  <div className="relative my-4">
                    <div className="absolute inset-0 flex items-center">
                      <div className="w-full border-t border-gray-300" />
                    </div>
                    <div className="relative flex justify-center text-sm">
                      <span className="bg-white px-2 text-gray-500">or</span>
                    </div>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </SignIn.Step>
    </SignIn.Root>
  );
}

// Example usage:
/*
import { AuthButtons } from '@/components/auth/AuthButtons';

export default function LoginPage() {
  return (
    <div className="max-w-md mx-auto p-6">
      <h1 className="text-2xl font-bold mb-6">Sign in to your account</h1>

      <AuthButtons
        providers={['google', 'github', 'discord']}
        orientation="vertical"
        onSuccess={(userId) => console.log('Authenticated:', userId)}
        onError={(error) => console.error('Auth error:', error)}
      />
    </div>
  );
}
*/

// Compact variant with icon-only buttons
export function AuthButtonsCompact({
  providers = ['google', 'github', 'discord'],
  className = ''
}: Pick<AuthButtonsProps, 'providers' | 'className'>) {
  const providerConfig = {
    google: { name: 'Google', icon: '🔍' },
    github: { name: 'GitHub', icon: '🐙' },
    discord: { name: 'Discord', icon: '💬' },
    microsoft: { name: 'Microsoft', icon: '🪟' },
    apple: { name: 'Apple', icon: '🍎' },
    facebook: { name: 'Facebook', icon: '📘' },
    linkedin: { name: 'LinkedIn', icon: '💼' },
    twitter: { name: 'Twitter', icon: '🐦' }
  };

  return (
    <SignIn.Root>
      <SignIn.Step name="start">
        <div className={`flex gap-3 ${className}`}>
          {providers?.map((provider) => {
            const config = providerConfig[provider];

            return (
              <SignIn.Strategy key={provider} name={`oauth_${provider}`}>
                <button
                  type="button"
                  title={`Sign in with ${config.name}`}
                  className="
                    w-12 h-12 rounded-full
                    flex items-center justify-center
                    bg-white border-2 border-gray-200
                    hover:border-gray-400 hover:scale-110
                    transition-all duration-200
                  "
                >
                  <span className="text-xl">{config.icon}</span>
                </button>
              </SignIn.Strategy>
            );
          })}
        </div>
      </SignIn.Step>
    </SignIn.Root>
  );
}
