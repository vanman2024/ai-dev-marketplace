/**
 * Component with Context Template
 *
 * React Context pattern for sharing state across component trees
 * without prop drilling. Includes provider and consumer components.
 */

import { createContext, useContext, useState, type ReactNode } from 'react';

// ============================================================================
// Context Definition
// ============================================================================

interface ${COMPONENT_NAME}State {
  theme: 'light' | 'dark';
  language: string;
  user: { name: string; email: string } | null;
}

interface ${COMPONENT_NAME}ContextValue {
  state: ${COMPONENT_NAME}State;
  setTheme: (theme: 'light' | 'dark') => void;
  setLanguage: (language: string) => void;
  setUser: (user: ${COMPONENT_NAME}State['user']) => void;
}

const ${COMPONENT_NAME}Context = createContext<${COMPONENT_NAME}ContextValue | undefined>(
  undefined
);

// ============================================================================
// Context Hook
// ============================================================================

/**
 * Hook to access context values
 * Throws error if used outside provider
 */
export function use${COMPONENT_NAME}() {
  const context = useContext(${COMPONENT_NAME}Context);

  if (context === undefined) {
    throw new Error(
      'use${COMPONENT_NAME} must be used within ${COMPONENT_NAME}Provider'
    );
  }

  return context;
}

// ============================================================================
// Provider Component
// ============================================================================

interface ${COMPONENT_NAME}ProviderProps {
  children: ReactNode;
  initialTheme?: 'light' | 'dark';
  initialLanguage?: string;
}

/**
 * Provider component that wraps your app/component tree
 */
export function ${COMPONENT_NAME}Provider({
  children,
  initialTheme = 'light',
  initialLanguage = 'en',
}: ${COMPONENT_NAME}ProviderProps) {
  const [state, setState] = useState<${COMPONENT_NAME}State>({
    theme: initialTheme,
    language: initialLanguage,
    user: null,
  });

  const setTheme = (theme: 'light' | 'dark') => {
    setState((prev) => ({ ...prev, theme }));
  };

  const setLanguage = (language: string) => {
    setState((prev) => ({ ...prev, language }));
  };

  const setUser = (user: ${COMPONENT_NAME}State['user']) => {
    setState((prev) => ({ ...prev, user }));
  };

  const value: ${COMPONENT_NAME}ContextValue = {
    state,
    setTheme,
    setLanguage,
    setUser,
  };

  return (
    <${COMPONENT_NAME}Context.Provider value={value}>
      {children}
    </${COMPONENT_NAME}Context.Provider>
  );
}

// ============================================================================
// Example Consumer Components
// ============================================================================

/**
 * Theme toggle component that uses context
 */
export function ThemeToggle() {
  const { state, setTheme } = use${COMPONENT_NAME}();

  return (
    <button
      onClick={() => setTheme(state.theme === 'light' ? 'dark' : 'light')}
      className="btn btn-secondary"
    >
      {state.theme === 'light' ? '🌙' : '☀️'} Toggle Theme
    </button>
  );
}

/**
 * Language selector component
 */
export function LanguageSelector() {
  const { state, setLanguage } = use${COMPONENT_NAME}();

  return (
    <select
      value={state.language}
      onChange={(e) => setLanguage(e.target.value)}
      className="px-3 py-2 border rounded-md"
    >
      <option value="en">English</option>
      <option value="es">Español</option>
      <option value="fr">Français</option>
    </select>
  );
}

/**
 * User profile display component
 */
export function UserProfile() {
  const { state } = use${COMPONENT_NAME}();

  if (!state.user) {
    return (
      <div className="text-gray-500">
        Not logged in
      </div>
    );
  }

  return (
    <div className="flex items-center space-x-2">
      <div className="w-10 h-10 bg-primary-500 rounded-full flex items-center justify-center text-white font-bold">
        {state.user.name.charAt(0).toUpperCase()}
      </div>
      <div>
        <div className="font-medium">{state.user.name}</div>
        <div className="text-sm text-gray-500">{state.user.email}</div>
      </div>
    </div>
  );
}

/**
 * Main demo component showing context usage
 */
export default function ${COMPONENT_NAME}Demo() {
  const { state, setUser } = use${COMPONENT_NAME}();

  const handleLogin = () => {
    setUser({
      name: 'John Doe',
      email: 'john@example.com',
    });
  };

  const handleLogout = () => {
    setUser(null);
  };

  return (
    <div
      className={`min-h-screen p-8 ${
        state.theme === 'dark' ? 'bg-gray-900 text-white' : 'bg-white text-gray-900'
      }`}
    >
      <div className="max-w-2xl mx-auto space-y-6">
        <h1 className="text-3xl font-bold mb-8">Context Demo</h1>

        <div className="card space-y-4">
          <h2 className="text-xl font-semibold">Theme & Language</h2>
          <div className="flex gap-4">
            <ThemeToggle />
            <LanguageSelector />
          </div>
          <p className="text-sm text-gray-600">
            Current theme: <strong>{state.theme}</strong> |
            Language: <strong>{state.language}</strong>
          </p>
        </div>

        <div className="card space-y-4">
          <h2 className="text-xl font-semibold">User Profile</h2>
          <UserProfile />
          <div className="flex gap-2">
            {!state.user ? (
              <button onClick={handleLogin} className="btn btn-primary">
                Login
              </button>
            ) : (
              <button onClick={handleLogout} className="btn btn-secondary">
                Logout
              </button>
            )}
          </div>
        </div>

        <div className="card">
          <h3 className="font-semibold mb-2">Context State:</h3>
          <pre className="bg-gray-100 dark:bg-gray-800 p-4 rounded-md overflow-auto">
            {JSON.stringify(state, null, 2)}
          </pre>
        </div>
      </div>
    </div>
  );
}

/**
 * Usage in Astro:
 *
 * ---
 * import { ${COMPONENT_NAME}Provider } from '@/components/react/${COMPONENT_NAME}';
 * import ${COMPONENT_NAME}Demo from '@/components/react/${COMPONENT_NAME}';
 * ---
 *
 * <${COMPONENT_NAME}Provider client:load initialTheme="light">
 *   <${COMPONENT_NAME}Demo />
 * </${COMPONENT_NAME}Provider>
 *
 * Important:
 * - The Provider must wrap all components that use the context
 * - Use client:load on the Provider to ensure all children are hydrated
 * - Individual consumer components can use their own client directives
 *
 * Multi-file usage:
 * 1. Export provider and hook from this file
 * 2. Import use${COMPONENT_NAME}() in other components
 * 3. Ensure all consuming components are children of the Provider
 */
