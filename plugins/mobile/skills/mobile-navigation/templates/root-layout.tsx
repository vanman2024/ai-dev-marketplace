// Root layout with authentication flow (expo-router)
import { useAuth } from '@/hooks/useAuth';
import { Stack } from 'expo-router';

export default function RootLayout() {
  const { isAuthenticated, isLoading } = useAuth();

  if (isLoading) {
    return <SplashScreen />;
  }

  return (
    <Stack screenOptions={{ headerShown: false }}>
      {isAuthenticated ? (
        <Stack.Screen name="(tabs)" />
      ) : (
        <Stack.Screen name="auth" />
      )}
      <Stack.Screen name="modal" options={{ presentation: 'modal' }} />
    </Stack>
  );
}
