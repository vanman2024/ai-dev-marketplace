# Basic React Component Integration in Astro

This example demonstrates how to integrate React components into an Astro project using the islands architecture for optimal performance.

## Prerequisites

- Astro project initialized
- React integration configured (`npx astro add react`)
- TypeScript enabled

## Step 1: Create a Simple React Component

```typescript
// src/components/Counter.tsx
import { useState } from 'react';

interface CounterProps {
  initialCount?: number;
}

export function Counter({ initialCount = 0 }: CounterProps) {
  const [count, setCount] = useState(initialCount);

  return (
    <div className="flex flex-col items-center gap-4 p-6 border rounded-lg">
      <p className="text-2xl font-bold">Count: {count}</p>
      <div className="flex gap-2">
        <button
          onClick={() => setCount(count - 1)}
          className="px-4 py-2 bg-red-500 text-white rounded hover:bg-red-600"
        >
          Decrement
        </button>
        <button
          onClick={() => setCount(count + 1)}
          className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600"
        >
          Increment
        </button>
        <button
          onClick={() => setCount(0)}
          className="px-4 py-2 bg-gray-500 text-white rounded hover:bg-gray-600"
        >
          Reset
        </button>
      </div>
    </div>
  );
}
```

## Step 2: Use Component in Astro Page

### Server-Rendered (No Hydration)

```astro
---
// src/pages/index.astro
import { Counter } from '@/components/Counter';
---

<html>
  <head>
    <title>React in Astro</title>
  </head>
  <body>
    <h1>Static React Component</h1>
    <!-- This renders to static HTML, no interactivity -->
    <Counter initialCount={0} />
  </body>
</html>
```

### Client-Side Interactive (with Hydration)

```astro
---
// src/pages/interactive.astro
import { Counter } from '@/components/Counter';
---

<html>
  <head>
    <title>Interactive React in Astro</title>
  </head>
  <body>
    <h1>Interactive React Component</h1>

    <!-- Load immediately on page load -->
    <Counter client:load initialCount={0} />

    <!-- Load when component becomes visible -->
    <Counter client:visible initialCount={10} />

    <!-- Load when browser is idle -->
    <Counter client:idle initialCount={20} />

    <!-- Load only when media query matches -->
    <Counter client:media="(min-width: 768px)" initialCount={30} />
  </body>
</html>
```

## Step 3: Client Directive Comparison

| Directive | When to Use | Performance Impact |
|-----------|-------------|-------------------|
| `client:load` | Critical interactive components | Highest - loads immediately |
| `client:idle` | Important but not critical | Medium - loads after page interactive |
| `client:visible` | Below-the-fold components | Low - loads only when in viewport |
| `client:media` | Responsive components | Low - loads based on breakpoint |
| `client:only="react"` | React-specific code | Variable - skips server rendering |

## Step 4: Passing Props from Astro to React

```astro
---
// src/pages/props-demo.astro
import { Counter } from '@/components/Counter';

// Server-side data fetching
const posts = await fetch('https://api.example.com/posts').then(r => r.json());
const config = {
  theme: 'dark',
  maxCount: 100
};
---

<html>
  <body>
    <!-- Pass server data to React component -->
    <Counter
      client:load
      initialCount={posts.length}
      config={config}
    />
  </body>
</html>
```

## Step 5: Component with TypeScript Types

```typescript
// src/components/Card.tsx
import type { ReactNode } from 'react';

interface CardProps {
  title: string;
  description?: string;
  children?: ReactNode;
  variant?: 'default' | 'outlined' | 'elevated';
  onClick?: () => void;
}

export function Card({
  title,
  description,
  children,
  variant = 'default',
  onClick
}: CardProps) {
  const variantClasses = {
    default: 'bg-white border border-gray-200',
    outlined: 'bg-transparent border-2 border-gray-300',
    elevated: 'bg-white shadow-lg'
  };

  return (
    <div
      className={`rounded-lg p-6 ${variantClasses[variant]}`}
      onClick={onClick}
    >
      <h3 className="text-xl font-bold mb-2">{title}</h3>
      {description && <p className="text-gray-600 mb-4">{description}</p>}
      {children}
    </div>
  );
}
```

## Step 6: Using the Card Component

```astro
---
// src/pages/cards.astro
import { Card } from '@/components/Card';
---

<html>
  <body>
    <div class="grid grid-cols-3 gap-4 p-8">
      <Card
        client:visible
        title="Default Card"
        description="A simple card component"
      />

      <Card
        client:visible
        title="Outlined Card"
        description="With outlined variant"
        variant="outlined"
      />

      <Card
        client:load
        title="Elevated Card"
        variant="elevated"
      >
        <p>Custom children content goes here</p>
        <button class="mt-4 px-4 py-2 bg-blue-500 text-white rounded">
          Action Button
        </button>
      </Card>
    </div>
  </body>
</html>
```

## Step 7: Shared State Between Components

```typescript
// src/components/ThemeProvider.tsx
import { createContext, useContext, useState, type ReactNode } from 'react';

type Theme = 'light' | 'dark';

const ThemeContext = createContext<{
  theme: Theme;
  toggleTheme: () => void;
} | null>(null);

export function ThemeProvider({ children }: { children: ReactNode }) {
  const [theme, setTheme] = useState<Theme>('light');

  const toggleTheme = () => {
    setTheme(theme === 'light' ? 'dark' : 'light');
  };

  return (
    <ThemeContext.Provider value={{ theme, toggleTheme }}>
      <div className={theme === 'dark' ? 'dark' : ''}>
        {children}
      </div>
    </ThemeContext.Provider>
  );
}

export function useTheme() {
  const context = useContext(ThemeContext);
  if (!context) {
    throw new Error('useTheme must be used within ThemeProvider');
  }
  return context;
}
```

```typescript
// src/components/ThemeToggle.tsx
import { useTheme } from './ThemeProvider';

export function ThemeToggle() {
  const { theme, toggleTheme } = useTheme();

  return (
    <button
      onClick={toggleTheme}
      className="px-4 py-2 bg-gray-200 dark:bg-gray-800 rounded"
    >
      Current theme: {theme}
    </button>
  );
}
```

```astro
---
// src/pages/theme-demo.astro
import { ThemeProvider } from '@/components/ThemeProvider';
import { ThemeToggle } from '@/components/ThemeToggle';
---

<html>
  <body>
    <!-- Wrap components that need shared state in provider -->
    <ThemeProvider client:load>
      <div class="p-8">
        <h1>Theme Demo</h1>
        <ThemeToggle />
      </div>
    </ThemeProvider>
  </body>
</html>
```

## Best Practices

### 1. Choose the Right Hydration Strategy

```astro
<!-- ❌ Bad: Everything loads immediately -->
<Counter client:load />
<Card client:load />
<ThemeToggle client:load />

<!-- ✅ Good: Prioritize based on importance -->
<ThemeToggle client:load />  <!-- Critical for UX -->
<Card client:idle />          <!-- Can wait until idle -->
<Counter client:visible />    <!-- Load when scrolled to -->
```

### 2. Minimize JavaScript Bundle Size

```astro
<!-- ❌ Bad: Entire React component loads for static content -->
<Card client:load title="Static Card" />

<!-- ✅ Good: Use Astro component for static content -->
<div class="card">
  <h3>Static Card</h3>
</div>
```

### 3. Type Safety with Props

```typescript
// ❌ Bad: No type safety
export function Button({ label, onClick }) {
  return <button onClick={onClick}>{label}</button>;
}

// ✅ Good: Full type safety
interface ButtonProps {
  label: string;
  onClick: () => void;
  variant?: 'primary' | 'secondary';
  disabled?: boolean;
}

export function Button({
  label,
  onClick,
  variant = 'primary',
  disabled = false
}: ButtonProps) {
  return <button onClick={onClick} disabled={disabled}>{label}</button>;
}
```

### 4. Performance Monitoring

```bash
# Build and check bundle sizes
npm run build

# Check which components are hydrated
# Look for client:* directives in compiled output
```

## Troubleshooting

### React Hooks Not Working?

Make sure you're using `client:*` directive:

```astro
<!-- ❌ Won't work - no hydration -->
<Counter />

<!-- ✅ Works - component is hydrated -->
<Counter client:load />
```

### Props Not Updating?

Props are passed at build time for static generation:

```astro
---
const count = 10; // This value is set at build time
---

<!-- This will always show 10 -->
<Counter initialCount={count} />
```

For dynamic values, fetch them client-side or use SSR.

### Styles Not Applying?

Ensure Tailwind is configured in `astro.config.mjs`:

```javascript
import { defineConfig } from 'astro/config';
import react from '@astrojs/react';
import tailwind from '@astrojs/tailwind';

export default defineConfig({
  integrations: [react(), tailwind()]
});
```

## Summary

- Use `client:load` for critical interactive components
- Use `client:visible` for below-the-fold content
- Use `client:idle` for non-critical features
- Keep static content in Astro components
- Use TypeScript for type safety
- Share state with Context API when needed
