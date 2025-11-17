'use client'

import { useSignIn, useSignUp } from '@clerk/nextjs'
import { OAuthStrategy } from '@clerk/types'
import { useState } from 'react'

/**
 * Social Authentication Buttons Example
 *
 * This example demonstrates:
 * - OAuth provider buttons (Google, GitHub, Discord, Microsoft, Facebook, Apple)
 * - Custom styling and branding
 * - Loading states during OAuth flow
 * - Error handling for OAuth failures
 * - Redirect configuration
 */

interface SocialButtonProps {
  strategy: OAuthStrategy
  icon: React.ReactNode
  label: string
  className?: string
}

export function SocialAuthButtons() {
  const { signIn } = useSignIn()
  const { signUp } = useSignUp()
  const [isLoading, setIsLoading] = useState<OAuthStrategy | null>(null)
  const [error, setError] = useState<string | null>(null)

  const signInWith = async (strategy: OAuthStrategy) => {
    if (!signIn || !signUp) return

    setIsLoading(strategy)
    setError(null)

    try {
      await signIn.authenticateWithRedirect({
        strategy,
        redirectUrl: '/sso-callback',
        redirectUrlComplete: '/dashboard'
      })
    } catch (err: any) {
      console.error('OAuth error:', err)
      setError(err?.errors?.[0]?.message || 'Authentication failed. Please try again.')
      setIsLoading(null)
    }
  }

  const providers: SocialButtonProps[] = [
    {
      strategy: 'oauth_google',
      icon: <GoogleIcon />,
      label: 'Continue with Google',
      className: 'hover:bg-blue-50'
    },
    {
      strategy: 'oauth_github',
      icon: <GithubIcon />,
      label: 'Continue with GitHub',
      className: 'hover:bg-gray-50'
    },
    {
      strategy: 'oauth_discord',
      icon: <DiscordIcon />,
      label: 'Continue with Discord',
      className: 'hover:bg-indigo-50'
    },
    {
      strategy: 'oauth_microsoft',
      icon: <MicrosoftIcon />,
      label: 'Continue with Microsoft',
      className: 'hover:bg-blue-50'
    },
    {
      strategy: 'oauth_facebook',
      icon: <FacebookIcon />,
      label: 'Continue with Facebook',
      className: 'hover:bg-blue-50'
    },
    {
      strategy: 'oauth_apple',
      icon: <AppleIcon />,
      label: 'Continue with Apple',
      className: 'hover:bg-gray-50'
    }
  ]

  return (
    <div className="w-full max-w-md space-y-4">
      {error && (
        <div className="p-4 bg-red-50 border border-red-200 rounded-lg">
          <p className="text-sm text-red-800">{error}</p>
        </div>
      )}

      {providers.map((provider) => (
        <SocialButton
          key={provider.strategy}
          strategy={provider.strategy}
          icon={provider.icon}
          label={provider.label}
          className={provider.className}
          isLoading={isLoading === provider.strategy}
          onClick={() => signInWith(provider.strategy)}
        />
      ))}
    </div>
  )
}

function SocialButton({ strategy, icon, label, className, isLoading, onClick }: SocialButtonProps & {
  isLoading: boolean
  onClick: () => void
}) {
  return (
    <button
      onClick={onClick}
      disabled={isLoading}
      className={`w-full flex items-center justify-center gap-3 px-4 py-3 border-2 border-gray-300 rounded-lg transition-all disabled:opacity-50 disabled:cursor-not-allowed ${className}`}
    >
      {isLoading ? (
        <div className="h-5 w-5 animate-spin rounded-full border-2 border-gray-300 border-t-gray-600" />
      ) : (
        icon
      )}
      <span className="font-medium text-gray-700">{label}</span>
    </button>
  )
}

// Compact version for header/navbar
export function CompactSocialButtons() {
  const { signIn } = useSignIn()
  const [isLoading, setIsLoading] = useState(false)

  const signInWith = async (strategy: OAuthStrategy) => {
    if (!signIn) return
    setIsLoading(true)

    try {
      await signIn.authenticateWithRedirect({
        strategy,
        redirectUrl: '/sso-callback',
        redirectUrlComplete: '/dashboard'
      })
    } catch (err) {
      console.error('OAuth error:', err)
      setIsLoading(false)
    }
  }

  return (
    <div className="flex items-center gap-2">
      <button
        onClick={() => signInWith('oauth_google')}
        disabled={isLoading}
        className="p-2 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors disabled:opacity-50"
        title="Sign in with Google"
      >
        <GoogleIcon />
      </button>
      <button
        onClick={() => signInWith('oauth_github')}
        disabled={isLoading}
        className="p-2 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors disabled:opacity-50"
        title="Sign in with GitHub"
      >
        <GithubIcon />
      </button>
    </div>
  )
}

// Grid layout for multiple providers
export function SocialButtonGrid() {
  const { signIn } = useSignIn()
  const [isLoading, setIsLoading] = useState<OAuthStrategy | null>(null)

  const signInWith = async (strategy: OAuthStrategy) => {
    if (!signIn) return
    setIsLoading(strategy)

    try {
      await signIn.authenticateWithRedirect({
        strategy,
        redirectUrl: '/sso-callback',
        redirectUrlComplete: '/dashboard'
      })
    } catch (err) {
      console.error('OAuth error:', err)
      setIsLoading(null)
    }
  }

  const providers = [
    { strategy: 'oauth_google' as OAuthStrategy, icon: <GoogleIcon />, name: 'Google' },
    { strategy: 'oauth_github' as OAuthStrategy, icon: <GithubIcon />, name: 'GitHub' },
    { strategy: 'oauth_discord' as OAuthStrategy, icon: <DiscordIcon />, name: 'Discord' },
    { strategy: 'oauth_microsoft' as OAuthStrategy, icon: <MicrosoftIcon />, name: 'Microsoft' }
  ]

  return (
    <div className="grid grid-cols-2 gap-3">
      {providers.map((provider) => (
        <button
          key={provider.strategy}
          onClick={() => signInWith(provider.strategy)}
          disabled={isLoading === provider.strategy}
          className="flex items-center justify-center gap-2 px-4 py-3 border-2 border-gray-300 rounded-lg hover:border-gray-400 transition-all disabled:opacity-50"
        >
          {isLoading === provider.strategy ? (
            <div className="h-5 w-5 animate-spin rounded-full border-2 border-gray-300 border-t-gray-600" />
          ) : (
            provider.icon
          )}
          <span className="font-medium text-gray-700 text-sm">{provider.name}</span>
        </button>
      ))}
    </div>
  )
}

// Icon components
function GoogleIcon() {
  return (
    <svg className="w-5 h-5" viewBox="0 0 24 24">
      <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
      <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
      <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
      <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
    </svg>
  )
}

function GithubIcon() {
  return (
    <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
      <path fillRule="evenodd" d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z" clipRule="evenodd" />
    </svg>
  )
}

function DiscordIcon() {
  return (
    <svg className="w-5 h-5" fill="#5865F2" viewBox="0 0 24 24">
      <path d="M20.317 4.37a19.791 19.791 0 0 0-4.885-1.515.074.074 0 0 0-.079.037c-.21.375-.444.864-.608 1.25a18.27 18.27 0 0 0-5.487 0 12.64 12.64 0 0 0-.617-1.25.077.077 0 0 0-.079-.037A19.736 19.736 0 0 0 3.677 4.37a.07.07 0 0 0-.032.027C.533 9.046-.32 13.58.099 18.057a.082.082 0 0 0 .031.057 19.9 19.9 0 0 0 5.993 3.03.078.078 0 0 0 .084-.028c.462-.63.874-1.295 1.226-1.994a.076.076 0 0 0-.041-.106 13.107 13.107 0 0 1-1.872-.892.077.077 0 0 1-.008-.128 10.2 10.2 0 0 0 .372-.292.074.074 0 0 1 .077-.01c3.928 1.793 8.18 1.793 12.062 0a.074.074 0 0 1 .078.01c.12.098.246.198.373.292a.077.077 0 0 1-.006.127 12.299 12.299 0 0 1-1.873.892.077.077 0 0 0-.041.107c.36.698.772 1.362 1.225 1.993a.076.076 0 0 0 .084.028 19.839 19.839 0 0 0 6.002-3.03.077.077 0 0 0 .032-.054c.5-5.177-.838-9.674-3.549-13.66a.061.061 0 0 0-.031-.03zM8.02 15.33c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.956-2.419 2.157-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.956 2.418-2.157 2.418zm7.975 0c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.955-2.419 2.157-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.946 2.418-2.157 2.418z"/>
    </svg>
  )
}

function MicrosoftIcon() {
  return (
    <svg className="w-5 h-5" viewBox="0 0 24 24">
      <path fill="#f25022" d="M1 1h10v10H1z"/>
      <path fill="#00a4ef" d="M13 1h10v10H13z"/>
      <path fill="#7fba00" d="M1 13h10v10H1z"/>
      <path fill="#ffb900" d="M13 13h10v10H13z"/>
    </svg>
  )
}

function FacebookIcon() {
  return (
    <svg className="w-5 h-5" fill="#1877F2" viewBox="0 0 24 24">
      <path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/>
    </svg>
  )
}

function AppleIcon() {
  return (
    <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
      <path d="M17.05 20.28c-.98.95-2.05.8-3.08.35-1.09-.46-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.35C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.54 4.09l.01-.01zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z"/>
    </svg>
  )
}
