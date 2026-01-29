---
name: mobile-auth-patterns
description: Mobile authentication patterns with Clerk, Supabase, and custom auth including biometrics, secure storage, and social login. Use when implementing authentication, managing tokens, or setting up biometric unlock.
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, WebFetch
---

# Mobile Auth Patterns

Comprehensive skill for implementing authentication in React Native/Expo mobile apps.

## Overview

Mobile authentication requires special considerations:

- Secure token storage (not AsyncStorage)
- Biometric authentication for quick access
- Social login providers (Apple, Google)
- Session management across app states
- Refresh token handling

## Use When

This skill is automatically invoked when:

- Setting up authentication flows
- Implementing biometric unlock
- Integrating social login providers
- Managing secure token storage
- Handling session persistence

## Auth Provider Templates

### Clerk Integration

```typescript
// providers/ClerkProvider.tsx
import { ClerkProvider, useAuth } from '@clerk/clerk-expo';
import * as SecureStore from 'expo-secure-store';

const tokenCache = {
  async getToken(key: string) {
    return await SecureStore.getItemAsync(key);
  },
  async saveToken(key: string, value: string) {
    await SecureStore.setItemAsync(key, value);
  },
  async clearToken(key: string) {
    await SecureStore.deleteItemAsync(key);
  },
};

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const publishableKey = process.env.EXPO_PUBLIC_CLERK_PUBLISHABLE_KEY!;

  return (
    <ClerkProvider publishableKey={publishableKey} tokenCache={tokenCache}>
      {children}
    </ClerkProvider>
  );
}

// hooks/useAuthenticatedUser.ts
import { useUser, useAuth } from '@clerk/clerk-expo';

export function useAuthenticatedUser() {
  const { user, isLoaded } = useUser();
  const { isSignedIn, signOut, getToken } = useAuth();

  return {
    user,
    isLoaded,
    isSignedIn,
    signOut,
    getToken,
    fullName: user?.fullName,
    email: user?.primaryEmailAddress?.emailAddress,
    avatar: user?.imageUrl,
  };
}
```

### Supabase Auth

```typescript
// lib/supabase.ts
import 'react-native-url-polyfill/auto';
import { createClient } from '@supabase/supabase-js';
import * as SecureStore from 'expo-secure-store';
import { Platform } from 'react-native';

const ExpoSecureStoreAdapter = {
  getItem: async (key: string) => {
    return await SecureStore.getItemAsync(key);
  },
  setItem: async (key: string, value: string) => {
    await SecureStore.setItemAsync(key, value);
  },
  removeItem: async (key: string) => {
    await SecureStore.deleteItemAsync(key);
  },
};

const supabaseUrl = process.env.EXPO_PUBLIC_SUPABASE_URL!;
const supabaseAnonKey = process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY!;

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    storage: ExpoSecureStoreAdapter,
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: false,
  },
});

// hooks/useSupabaseAuth.ts
import { useEffect, useState } from 'react';
import { supabase } from '@/lib/supabase';
import { Session, User } from '@supabase/supabase-js';

export function useSupabaseAuth() {
  const [session, setSession] = useState<Session | null>(null);
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    // Get initial session
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session);
      setUser(session?.user ?? null);
      setIsLoading(false);
    });

    // Listen for auth changes
    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session);
      setUser(session?.user ?? null);
    });

    return () => subscription.unsubscribe();
  }, []);

  const signIn = async (email: string, password: string) => {
    const { error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });
    if (error) throw error;
  };

  const signUp = async (email: string, password: string) => {
    const { error } = await supabase.auth.signUp({ email, password });
    if (error) throw error;
  };

  const signOut = async () => {
    const { error } = await supabase.auth.signOut();
    if (error) throw error;
  };

  return {
    session,
    user,
    isLoading,
    isAuthenticated: !!session,
    signIn,
    signUp,
    signOut,
  };
}
```

### Biometric Authentication

```typescript
// lib/biometrics.ts
import * as LocalAuthentication from 'expo-local-authentication';
import * as SecureStore from 'expo-secure-store';

export interface BiometricCapabilities {
  isAvailable: boolean;
  biometryType: 'fingerprint' | 'face' | 'iris' | null;
  isEnrolled: boolean;
}

export async function getBiometricCapabilities(): Promise<BiometricCapabilities> {
  const hasHardware = await LocalAuthentication.hasHardwareAsync();
  const isEnrolled = await LocalAuthentication.isEnrolledAsync();
  const supportedTypes =
    await LocalAuthentication.supportedAuthenticationTypesAsync();

  let biometryType: BiometricCapabilities['biometryType'] = null;
  if (
    supportedTypes.includes(
      LocalAuthentication.AuthenticationType.FACIAL_RECOGNITION
    )
  ) {
    biometryType = 'face';
  } else if (
    supportedTypes.includes(LocalAuthentication.AuthenticationType.FINGERPRINT)
  ) {
    biometryType = 'fingerprint';
  } else if (
    supportedTypes.includes(LocalAuthentication.AuthenticationType.IRIS)
  ) {
    biometryType = 'iris';
  }

  return {
    isAvailable: hasHardware && isEnrolled,
    biometryType,
    isEnrolled,
  };
}

export async function authenticateWithBiometrics(
  promptMessage = 'Authenticate to continue'
): Promise<boolean> {
  try {
    const result = await LocalAuthentication.authenticateAsync({
      promptMessage,
      cancelLabel: 'Cancel',
      disableDeviceFallback: false,
      fallbackLabel: 'Use passcode',
    });
    return result.success;
  } catch (error) {
    console.error('Biometric authentication error:', error);
    return false;
  }
}

// Biometric-protected secure storage
export const BiometricSecureStore = {
  async setItem(key: string, value: string): Promise<void> {
    await SecureStore.setItemAsync(key, value, {
      requireAuthentication: true,
      authenticationPrompt: 'Authenticate to save credentials',
    });
  },

  async getItem(key: string): Promise<string | null> {
    try {
      return await SecureStore.getItemAsync(key, {
        requireAuthentication: true,
        authenticationPrompt: 'Authenticate to access credentials',
      });
    } catch {
      return null;
    }
  },
};
```

### Social Login (Apple & Google)

```typescript
// lib/socialAuth.ts
import * as AppleAuthentication from 'expo-apple-authentication';
import * as Google from 'expo-auth-session/providers/google';
import { supabase } from './supabase';

// Apple Sign In
export async function signInWithApple() {
  try {
    const credential = await AppleAuthentication.signInAsync({
      requestedScopes: [
        AppleAuthentication.AppleAuthenticationScope.FULL_NAME,
        AppleAuthentication.AppleAuthenticationScope.EMAIL,
      ],
    });

    if (credential.identityToken) {
      const { data, error } = await supabase.auth.signInWithIdToken({
        provider: 'apple',
        token: credential.identityToken,
      });

      if (error) throw error;
      return data;
    }
  } catch (e: any) {
    if (e.code === 'ERR_REQUEST_CANCELED') {
      // User cancelled
      return null;
    }
    throw e;
  }
}

// Google Sign In (with Clerk)
import { useOAuth } from '@clerk/clerk-expo';
import * as WebBrowser from 'expo-web-browser';
import * as Linking from 'expo-linking';

WebBrowser.maybeCompleteAuthSession();

export function useGoogleAuth() {
  const { startOAuthFlow } = useOAuth({ strategy: 'oauth_google' });

  const signInWithGoogle = async () => {
    try {
      const { createdSessionId, setActive } = await startOAuthFlow({
        redirectUrl: Linking.createURL('/oauth-callback'),
      });

      if (createdSessionId && setActive) {
        await setActive({ session: createdSessionId });
        return true;
      }
      return false;
    } catch (error) {
      console.error('Google sign in error:', error);
      throw error;
    }
  };

  return { signInWithGoogle };
}
```

### Complete Auth Context

```typescript
// contexts/AuthContext.tsx
import React, { createContext, useContext, useEffect, useState } from 'react';
import { supabase } from '@/lib/supabase';
import { getBiometricCapabilities, authenticateWithBiometrics } from '@/lib/biometrics';
import * as SecureStore from 'expo-secure-store';

interface AuthContextType {
  user: User | null;
  isLoading: boolean;
  isAuthenticated: boolean;
  biometricsEnabled: boolean;
  biometricType: string | null;
  signIn: (email: string, password: string) => Promise<void>;
  signUp: (email: string, password: string) => Promise<void>;
  signOut: () => Promise<void>;
  signInWithBiometrics: () => Promise<boolean>;
  enableBiometrics: () => Promise<void>;
  disableBiometrics: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [biometricsEnabled, setBiometricsEnabled] = useState(false);
  const [biometricType, setBiometricType] = useState<string | null>(null);

  useEffect(() => {
    initializeAuth();
  }, []);

  async function initializeAuth() {
    // Check session
    const { data: { session } } = await supabase.auth.getSession();
    setUser(session?.user ?? null);

    // Check biometric status
    const capabilities = await getBiometricCapabilities();
    setBiometricType(capabilities.biometryType);

    const enabled = await SecureStore.getItemAsync('biometrics_enabled');
    setBiometricsEnabled(enabled === 'true');

    setIsLoading(false);

    // Listen for changes
    supabase.auth.onAuthStateChange((_event, session) => {
      setUser(session?.user ?? null);
    });
  }

  async function signIn(email: string, password: string) {
    const { error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) throw error;
  }

  async function signUp(email: string, password: string) {
    const { error } = await supabase.auth.signUp({ email, password });
    if (error) throw error;
  }

  async function signOut() {
    await supabase.auth.signOut();
    await SecureStore.deleteItemAsync('biometric_session');
    setBiometricsEnabled(false);
  }

  async function signInWithBiometrics() {
    if (!biometricsEnabled) return false;

    const authenticated = await authenticateWithBiometrics();
    if (authenticated) {
      const sessionToken = await SecureStore.getItemAsync('biometric_session');
      if (sessionToken) {
        const { error } = await supabase.auth.setSession(JSON.parse(sessionToken));
        return !error;
      }
    }
    return false;
  }

  async function enableBiometrics() {
    const { data } = await supabase.auth.getSession();
    if (data.session) {
      await SecureStore.setItemAsync('biometric_session', JSON.stringify(data.session));
      await SecureStore.setItemAsync('biometrics_enabled', 'true');
      setBiometricsEnabled(true);
    }
  }

  async function disableBiometrics() {
    await SecureStore.deleteItemAsync('biometric_session');
    await SecureStore.setItemAsync('biometrics_enabled', 'false');
    setBiometricsEnabled(false);
  }

  return (
    <AuthContext.Provider
      value={{
        user,
        isLoading,
        isAuthenticated: !!user,
        biometricsEnabled,
        biometricType,
        signIn,
        signUp,
        signOut,
        signInWithBiometrics,
        enableBiometrics,
        disableBiometrics,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return context;
}
```

## Best Practices

1. **Token Storage**
   - Always use SecureStore, never AsyncStorage for tokens
   - Implement secure token refresh logic
   - Clear tokens on sign out

2. **Biometrics**
   - Check capabilities before showing option
   - Provide fallback authentication
   - Store session encrypted, not credentials

3. **Social Login**
   - Use native sign-in where available (Apple)
   - Handle deep link callbacks properly
   - Request minimal scopes

4. **Security**
   - Implement certificate pinning for production
   - Use HTTPS for all API calls
   - Validate tokens server-side
