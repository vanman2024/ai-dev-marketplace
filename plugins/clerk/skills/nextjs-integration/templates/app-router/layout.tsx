import { ClerkProvider } from '@clerk/nextjs'
import { Inter } from 'next/font/google'
import type { Metadata } from 'next'
import './globals.css'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: 'My App - Powered by Clerk',
  description: 'Next.js application with Clerk authentication',
}

/**
 * Root layout with ClerkProvider
 *
 * ClerkProvider must wrap your entire application to enable
 * authentication throughout your app.
 *
 * @see https://clerk.com/docs/components/clerk-provider
 */
export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <ClerkProvider>
      <html lang="en" suppressHydrationWarning>
        <body className={inter.className}>
          {children}
        </body>
      </html>
    </ClerkProvider>
  )
}
