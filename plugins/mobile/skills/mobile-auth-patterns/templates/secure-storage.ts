// Secure storage utilities
import * as SecureStore from 'expo-secure-store';

export async function saveSecure(key: string, value: string) {
  await SecureStore.setItemAsync(key, value);
}

export async function getSecure(key: string) {
  return await SecureStore.getItemAsync(key);
}

export async function deleteSecure(key: string) {
  await SecureStore.deleteItemAsync(key);
}

export const TokenStorage = {
  async setAccessToken(token: string) {
    await saveSecure('access_token', token);
  },
  async getAccessToken() {
    return await getSecure('access_token');
  },
  async clearTokens() {
    await deleteSecure('access_token');
    await deleteSecure('refresh_token');
  },
};
