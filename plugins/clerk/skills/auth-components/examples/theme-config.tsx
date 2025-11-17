import { Appearance } from '@clerk/types'
import { dark, neobrutalist, shadesOfPurple } from '@clerk/themes'

/**
 * Complete Theme Configuration Examples for Clerk
 *
 * This file demonstrates:
 * - Pre-built themes from @clerk/themes
 * - Custom light theme with brand colors
 * - Custom dark theme
 * - Element-specific styling
 * - CSS variables customization
 * - Layout configuration
 * - Responsive design considerations
 */

// ===========================
// 1. DEFAULT LIGHT THEME
// ===========================
export const lightTheme: Appearance = {
  layout: {
    shimmer: true,
    logoPlacement: 'inside',
    socialButtonsPlacement: 'bottom',
    socialButtonsVariant: 'blockButton'
  },
  variables: {
    // Colors
    colorPrimary: '#6366f1',
    colorBackground: '#ffffff',
    colorText: '#1f2937',
    colorTextSecondary: '#6b7280',
    colorDanger: '#ef4444',
    colorSuccess: '#10b981',
    colorWarning: '#f59e0b',

    // Typography
    fontFamily: 'system-ui, -apple-system, "Segoe UI", Roboto, sans-serif',
    fontSize: '1rem',
    fontWeight: {
      normal: 400,
      medium: 500,
      semibold: 600,
      bold: 700
    },

    // Spacing
    spacingUnit: '1rem',
    borderRadius: '0.5rem'
  },
  elements: {
    // Container elements
    rootBox: 'shadow-lg',
    card: 'border border-gray-200 shadow-xl',

    // Header elements
    headerTitle: 'text-2xl font-bold text-gray-900',
    headerSubtitle: 'text-gray-600 mt-1',

    // Form elements
    formButtonPrimary: 'bg-blue-600 hover:bg-blue-700 transition-all duration-200 font-semibold shadow-sm hover:shadow-md',
    formFieldInput: 'border-gray-300 focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 transition-all',
    formFieldLabel: 'text-gray-700 font-medium',

    // Social buttons
    socialButtonsBlockButton: 'border-2 border-gray-300 hover:border-gray-400 transition-all duration-200',

    // Footer elements
    footerActionLink: 'text-blue-600 hover:text-blue-700 font-medium'
  }
}

// ===========================
// 2. CUSTOM DARK THEME
// ===========================
export const darkTheme: Appearance = {
  baseTheme: dark,
  layout: {
    shimmer: true,
    logoPlacement: 'inside'
  },
  variables: {
    // Dark mode colors
    colorPrimary: '#818cf8',
    colorBackground: '#111827',
    colorText: '#f9fafb',
    colorTextSecondary: '#9ca3af',
    colorDanger: '#f87171',
    colorSuccess: '#34d399',

    // Dark mode spacing
    borderRadius: '0.75rem',
    fontFamily: 'system-ui, -apple-system, sans-serif'
  },
  elements: {
    card: 'bg-gray-900 border border-gray-800 shadow-2xl',
    headerTitle: 'text-white',
    formButtonPrimary: 'bg-indigo-500 hover:bg-indigo-600',
    formFieldInput: 'bg-gray-800 border-gray-700 text-white focus:border-indigo-500',
    socialButtonsBlockButton: 'border-gray-700 hover:border-gray-600 bg-gray-800 hover:bg-gray-750',
    footerActionLink: 'text-indigo-400 hover:text-indigo-300'
  }
}

// ===========================
// 3. BRAND THEME (Custom Colors)
// ===========================
export const brandTheme: Appearance = {
  variables: {
    colorPrimary: '#8b5cf6',  // Purple brand color
    colorBackground: '#ffffff',
    colorText: '#1e293b',
    colorTextSecondary: '#64748b',
    colorDanger: '#dc2626',
    colorSuccess: '#059669',

    borderRadius: '0.5rem',
    fontFamily: '"Inter", system-ui, sans-serif'
  },
  elements: {
    rootBox: 'mx-auto max-w-md',
    card: 'shadow-2xl border border-purple-100 bg-white',

    headerTitle: 'text-3xl font-extrabold bg-gradient-to-r from-purple-600 to-pink-600 bg-clip-text text-transparent',
    headerSubtitle: 'text-slate-600',

    formButtonPrimary: 'bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700 text-white font-semibold shadow-lg hover:shadow-xl transition-all duration-300 transform hover:scale-105',

    formFieldInput: 'border-slate-300 focus:border-purple-500 focus:ring-2 focus:ring-purple-500/20',

    socialButtonsBlockButton: 'border-2 border-slate-200 hover:border-purple-300 hover:bg-purple-50 transition-all',

    footerActionLink: 'text-purple-600 hover:text-purple-700 font-semibold'
  }
}

// ===========================
// 4. MINIMAL THEME
// ===========================
export const minimalTheme: Appearance = {
  variables: {
    colorPrimary: '#000000',
    colorBackground: '#ffffff',
    colorText: '#000000',
    colorTextSecondary: '#666666',

    borderRadius: '0.25rem',
    fontFamily: '"Helvetica Neue", Arial, sans-serif'
  },
  elements: {
    card: 'border border-gray-300',
    headerTitle: 'font-light text-3xl',
    formButtonPrimary: 'bg-black hover:bg-gray-800 font-normal',
    formFieldInput: 'border-gray-400 focus:border-black',
    socialButtonsBlockButton: 'border border-gray-400 hover:bg-gray-50'
  }
}

// ===========================
// 5. NEOBRUTALIST THEME
// ===========================
export const neobrutalistTheme: Appearance = {
  baseTheme: neobrutalist,
  variables: {
    colorPrimary: '#000000',
    borderRadius: '0rem',  // No rounded corners
    fontFamily: '"Space Grotesk", monospace'
  },
  elements: {
    card: 'border-4 border-black shadow-[8px_8px_0px_0px_rgba(0,0,0,1)]',
    formButtonPrimary: 'border-4 border-black shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] hover:translate-x-1 hover:translate-y-1 hover:shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]',
    formFieldInput: 'border-4 border-black',
    socialButtonsBlockButton: 'border-4 border-black'
  }
}

// ===========================
// 6. SHADES OF PURPLE THEME
// ===========================
export const purpleTheme: Appearance = {
  baseTheme: shadesOfPurple,
  variables: {
    colorPrimary: '#a78bfa',
    borderRadius: '0.5rem'
  }
}

// ===========================
// 7. GLASSMORPHISM THEME
// ===========================
export const glassMorphismTheme: Appearance = {
  variables: {
    colorPrimary: '#3b82f6',
    colorBackground: 'rgba(255, 255, 255, 0.8)',
    colorText: '#1f2937',

    borderRadius: '1rem',
    fontFamily: 'system-ui, sans-serif'
  },
  elements: {
    card: 'backdrop-blur-xl bg-white/80 border border-white/20 shadow-2xl',
    formButtonPrimary: 'bg-blue-500/90 hover:bg-blue-600/90 backdrop-blur-sm',
    formFieldInput: 'bg-white/50 backdrop-blur-sm border-white/30 focus:bg-white/70',
    socialButtonsBlockButton: 'backdrop-blur-sm bg-white/50 border-white/30 hover:bg-white/70'
  }
}

// ===========================
// 8. RESPONSIVE THEME
// ===========================
export const responsiveTheme: Appearance = {
  layout: {
    shimmer: true,
    logoPlacement: 'inside'
  },
  variables: {
    colorPrimary: '#6366f1',
    colorBackground: '#ffffff',
    colorText: '#1f2937',
    borderRadius: '0.5rem'
  },
  elements: {
    rootBox: 'w-full max-w-md mx-auto px-4 sm:px-0',
    card: 'shadow-lg sm:shadow-xl border border-gray-200',

    headerTitle: 'text-xl sm:text-2xl font-bold',

    formButtonPrimary: 'py-2.5 sm:py-3 text-sm sm:text-base',
    formFieldInput: 'py-2 sm:py-3 text-sm sm:text-base',

    socialButtonsBlockButton: 'py-2.5 sm:py-3 text-sm sm:text-base'
  }
}

// ===========================
// 9. APPLYING THEMES
// ===========================

// Global application (app/layout.tsx):
/*
import { ClerkProvider } from '@clerk/nextjs'
import { lightTheme } from '@/lib/clerk-themes'

export default function RootLayout({ children }) {
  return (
    <ClerkProvider appearance={lightTheme}>
      <html>
        <body>{children}</body>
      </html>
    </ClerkProvider>
  )
}
*/

// Component-specific:
/*
import { SignIn } from '@clerk/nextjs'
import { darkTheme } from '@/lib/clerk-themes'

export default function SignInPage() {
  return <SignIn appearance={darkTheme} />
}
*/

// Dynamic theme switching:
/*
'use client'

import { ClerkProvider } from '@clerk/nextjs'
import { lightTheme, darkTheme } from '@/lib/clerk-themes'
import { useTheme } from 'next-themes'

export function ThemeAwareClerkProvider({ children }) {
  const { theme } = useTheme()

  return (
    <ClerkProvider appearance={theme === 'dark' ? darkTheme : lightTheme}>
      {children}
    </ClerkProvider>
  )
}
*/

// Tailwind CSS v4 integration:
/*
<ClerkProvider
  appearance={{
    ...lightTheme,
    cssLayerName: 'clerk'  // Ensures Tailwind utilities override
  }}
>
  {children}
</ClerkProvider>
*/
