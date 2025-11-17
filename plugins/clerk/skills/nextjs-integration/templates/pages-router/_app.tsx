import { ClerkProvider } from '@clerk/nextjs'
import type { AppProps } from 'next/app'
import '@/styles/globals.css'

/**
 * Custom App component with ClerkProvider
 *
 * ClerkProvider must wrap your entire application to enable
 * authentication throughout your app.
 *
 * @see https://clerk.com/docs/components/clerk-provider
 */
function MyApp({ Component, pageProps }: AppProps) {
  return (
    <ClerkProvider {...pageProps}>
      <Component {...pageProps} />
    </ClerkProvider>
  )
}

export default MyApp
