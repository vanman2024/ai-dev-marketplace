# Component Library Integration (shadcn/ui)

This example demonstrates how to integrate shadcn/ui components into an Astro project with React, providing a complete design system with accessible, customizable components.

## Prerequisites

- Astro project with React integration
- Tailwind CSS configured
- Node.js 18+

## Why shadcn/ui?

- **Copy-paste components** - Own the code, no npm dependency
- **Accessible by default** - Built on Radix UI primitives
- **Customizable** - Full control over styling with Tailwind
- **Type-safe** - Full TypeScript support
- **Production-ready** - Battle-tested components

## Step 1: Install shadcn/ui CLI

```bash
npx shadcn@latest init
```

Answer the prompts:

```
✔ Preflight checks
✔ Verifying framework. Found Astro.
✔ Validating Tailwind CSS. Found Tailwind CSS.
✔ Would you like to use TypeScript (recommended)? yes
✔ Where is your global CSS file? › src/styles/global.css
✔ Would you like to use CSS variables for theming? yes
✔ Where is your tailwind.config located? › tailwind.config.mjs
✔ Configure the import alias for components: › @/components
✔ Configure the import alias for utils: › @/lib/utils
✔ Write configuration to components.json. Proceed? yes
```

## Step 2: Update Tailwind Config

```typescript
// tailwind.config.mjs
import defaultTheme from 'tailwindcss/defaultTheme';

/** @type {import('tailwindcss').Config} */
export default {
  darkMode: ['class']
  content: ['./src/**/*.{astro,html,js,jsx,md,mdx,svelte,ts,tsx,vue}']
  theme: {
    container: {
      center: true
      padding: '2rem'
      screens: {
        '2xl': '1400px'
      }
    }
    extend: {
      colors: {
        border: 'hsl(var(--border))'
        input: 'hsl(var(--input))'
        ring: 'hsl(var(--ring))'
        background: 'hsl(var(--background))'
        foreground: 'hsl(var(--foreground))'
        primary: {
          DEFAULT: 'hsl(var(--primary))'
          foreground: 'hsl(var(--primary-foreground))'
        }
        secondary: {
          DEFAULT: 'hsl(var(--secondary))'
          foreground: 'hsl(var(--secondary-foreground))'
        }
        destructive: {
          DEFAULT: 'hsl(var(--destructive))'
          foreground: 'hsl(var(--destructive-foreground))'
        }
        muted: {
          DEFAULT: 'hsl(var(--muted))'
          foreground: 'hsl(var(--muted-foreground))'
        }
        accent: {
          DEFAULT: 'hsl(var(--accent))'
          foreground: 'hsl(var(--accent-foreground))'
        }
        popover: {
          DEFAULT: 'hsl(var(--popover))'
          foreground: 'hsl(var(--popover-foreground))'
        }
        card: {
          DEFAULT: 'hsl(var(--card))'
          foreground: 'hsl(var(--card-foreground))'
        }
      }
      borderRadius: {
        lg: 'var(--radius)'
        md: 'calc(var(--radius) - 2px)'
        sm: 'calc(var(--radius) - 4px)'
      }
      fontFamily: {
        sans: ['Inter', ...defaultTheme.fontFamily.sans]
      }
    }
  }
  plugins: [require('tailwindcss-animate')]
};
```

## Step 3: Add Components

Add individual components as needed:

```bash
# Add button component
npx shadcn@latest add button

# Add multiple components
npx shadcn@latest add card dialog dropdown-menu input label select

# Add all components (not recommended for production)
npx shadcn@latest add --all
```

## Step 4: Use Components in Astro Pages

### Simple Button Example

```astro
---
// src/pages/index.astro
import { Button } from '@/components/ui/button';
---

<html>
  <body>
    <div class="container py-8">
      <h1 class="text-4xl font-bold mb-8">shadcn/ui in Astro</h1>

      <!-- Static buttons (no interactivity needed) -->
      <div class="flex gap-2">
        <Button>Default Button</Button>
        <Button variant="secondary">Secondary</Button>
        <Button variant="outline">Outline</Button>
        <Button variant="ghost">Ghost</Button>
        <Button variant="destructive">Destructive</Button>
      </div>

      <!-- Interactive button (needs client hydration) -->
      <Button
        client:load
        onClick={() => alert('Clicked!')}
      >
        Click Me
      </Button>
    </div>
  </body>
</html>
```

### Card Grid Example

```astro
---
// src/pages/products.astro
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from '@/components/ui/card';
import { Button } from '@/components/ui/button';

const products = [
  { id: 1, name: 'Product 1', description: 'Amazing product', price: '$99' }
  { id: 2, name: 'Product 2', description: 'Great value', price: '$149' }
  { id: 3, name: 'Product 3', description: 'Best seller', price: '$199' }
];
---

<html>
  <body>
    <div class="container py-8">
      <h1 class="text-4xl font-bold mb-8">Products</h1>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {products.map((product) => (
          <Card>
            <CardHeader>
              <CardTitle>{product.name}</CardTitle>
              <CardDescription>{product.description}</CardDescription>
            </CardHeader>
            <CardContent>
              <p class="text-3xl font-bold">{product.price}</p>
            </CardContent>
            <CardFooter>
              <Button class="w-full" client:load>
                Add to Cart
              </Button>
            </CardFooter>
          </Card>
        ))}
      </div>
    </div>
  </body>
</html>
```

### Form Example with Dialog

```typescript
// src/components/ContactForm.tsx
import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import {
  Dialog
  DialogContent
  DialogDescription
  DialogHeader
  DialogTitle
  DialogTrigger
  DialogFooter
} from '@/components/ui/dialog';

export function ContactForm() {
  const [open, setOpen] = useState(false);
  const [formData, setFormData] = useState({
    name: ''
    email: ''
    message: ''
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    // Submit form data
    const response = await fetch('/api/contact', {
      method: 'POST'
      headers: { 'Content-Type': 'application/json' }
      body: JSON.stringify(formData)
    });

    if (response.ok) {
      setOpen(false);
      setFormData({ name: '', email: '', message: '' });
      alert('Message sent successfully!');
    }
  };

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button>Contact Us</Button>
      </DialogTrigger>
      <DialogContent className="sm:max-w-[425px]">
        <form onSubmit={handleSubmit}>
          <DialogHeader>
            <DialogTitle>Contact Us</DialogTitle>
            <DialogDescription>
              Send us a message and we'll get back to you as soon as possible.
            </DialogDescription>
          </DialogHeader>

          <div className="grid gap-4 py-4">
            <div className="grid gap-2">
              <Label htmlFor="name">Name</Label>
              <Input
                id="name"
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                required
              />
            </div>

            <div className="grid gap-2">
              <Label htmlFor="email">Email</Label>
              <Input
                id="email"
                type="email"
                value={formData.email}
                onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                required
              />
            </div>

            <div className="grid gap-2">
              <Label htmlFor="message">Message</Label>
              <Textarea
                id="message"
                value={formData.message}
                onChange={(e) => setFormData({ ...formData, message: e.target.value })}
                required
              />
            </div>
          </div>

          <DialogFooter>
            <Button type="submit">Send Message</Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
```

```astro
---
// src/pages/contact.astro
import { ContactForm } from '@/components/ContactForm';
---

<html>
  <body>
    <div class="container py-8">
      <h1 class="text-4xl font-bold mb-8">Get in Touch</h1>
      <ContactForm client:load />
    </div>
  </body>
</html>
```

### Data Table Example

```typescript
// src/components/UsersTable.tsx
import {
  Table
  TableBody
  TableCaption
  TableCell
  TableHead
  TableHeader
  TableRow
} from '@/components/ui/table';
import { Button } from '@/components/ui/button';
import {
  DropdownMenu
  DropdownMenuContent
  DropdownMenuItem
  DropdownMenuLabel
  DropdownMenuSeparator
  DropdownMenuTrigger
} from '@/components/ui/dropdown-menu';

interface User {
  id: string;
  name: string;
  email: string;
  role: string;
  status: 'active' | 'inactive';
}

interface UsersTableProps {
  users: User[];
}

export function UsersTable({ users }: UsersTableProps) {
  return (
    <Table>
      <TableCaption>A list of your team members</TableCaption>
      <TableHeader>
        <TableRow>
          <TableHead>Name</TableHead>
          <TableHead>Email</TableHead>
          <TableHead>Role</TableHead>
          <TableHead>Status</TableHead>
          <TableHead className="text-right">Actions</TableHead>
        </TableRow>
      </TableHeader>
      <TableBody>
        {users.map((user) => (
          <TableRow key={user.id}>
            <TableCell className="font-medium">{user.name}</TableCell>
            <TableCell>{user.email}</TableCell>
            <TableCell>{user.role}</TableCell>
            <TableCell>
              <span
                className={`inline-flex items-center rounded-full px-2 py-1 text-xs font-medium ${
                  user.status === 'active'
                    ? 'bg-green-50 text-green-700'
                    : 'bg-gray-50 text-gray-700'
                }`}
              >
                {user.status}
              </span>
            </TableCell>
            <TableCell className="text-right">
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button variant="ghost" size="sm">
                    Actions
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end">
                  <DropdownMenuLabel>Actions</DropdownMenuLabel>
                  <DropdownMenuItem>View profile</DropdownMenuItem>
                  <DropdownMenuItem>Edit user</DropdownMenuItem>
                  <DropdownMenuSeparator />
                  <DropdownMenuItem className="text-red-600">
                    Delete user
                  </DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
            </TableCell>
          </TableRow>
        ))}
      </TableBody>
    </Table>
  );
}
```

## Step 5: Dark Mode Support

```typescript
// src/components/ThemeToggle.tsx
import { useEffect, useState } from 'react';
import { Button } from '@/components/ui/button';

export function ThemeToggle() {
  const [theme, setTheme] = useState<'light' | 'dark'>('light');

  useEffect(() => {
    // Check localStorage or system preference
    const stored = localStorage.getItem('theme');
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    const initialTheme = stored === 'dark' || (!stored && prefersDark) ? 'dark' : 'light';

    setTheme(initialTheme);
    document.documentElement.classList.toggle('dark', initialTheme === 'dark');
  }, []);

  const toggleTheme = () => {
    const newTheme = theme === 'light' ? 'dark' : 'light';
    setTheme(newTheme);
    localStorage.setItem('theme', newTheme);
    document.documentElement.classList.toggle('dark', newTheme === 'dark');
  };

  return (
    <Button variant="ghost" size="icon" onClick={toggleTheme}>
      {theme === 'light' ? '🌙' : '☀️'}
    </Button>
  );
}
```

## Step 6: Custom Theme Colors

```css
/* src/styles/global.css */
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
    --background: 0 0% 100%;
    --foreground: 222.2 84% 4.9%;
    --card: 0 0% 100%;
    --card-foreground: 222.2 84% 4.9%;
    --popover: 0 0% 100%;
    --popover-foreground: 222.2 84% 4.9%;
    --primary: 222.2 47.4% 11.2%;
    --primary-foreground: 210 40% 98%;
    --secondary: 210 40% 96.1%;
    --secondary-foreground: 222.2 47.4% 11.2%;
    --muted: 210 40% 96.1%;
    --muted-foreground: 215.4 16.3% 46.9%;
    --accent: 210 40% 96.1%;
    --accent-foreground: 222.2 47.4% 11.2%;
    --destructive: 0 84.2% 60.2%;
    --destructive-foreground: 210 40% 98%;
    --border: 214.3 31.8% 91.4%;
    --input: 214.3 31.8% 91.4%;
    --ring: 222.2 84% 4.9%;
    --radius: 0.5rem;
  }

  .dark {
    --background: 222.2 84% 4.9%;
    --foreground: 210 40% 98%;
    --card: 222.2 84% 4.9%;
    --card-foreground: 210 40% 98%;
    --popover: 222.2 84% 4.9%;
    --popover-foreground: 210 40% 98%;
    --primary: 210 40% 98%;
    --primary-foreground: 222.2 47.4% 11.2%;
    --secondary: 217.2 32.6% 17.5%;
    --secondary-foreground: 210 40% 98%;
    --muted: 217.2 32.6% 17.5%;
    --muted-foreground: 215 20.2% 65.1%;
    --accent: 217.2 32.6% 17.5%;
    --accent-foreground: 210 40% 98%;
    --destructive: 0 62.8% 30.6%;
    --destructive-foreground: 210 40% 98%;
    --border: 217.2 32.6% 17.5%;
    --input: 217.2 32.6% 17.5%;
    --ring: 212.7 26.8% 83.9%;
  }
}
```

## Common Components to Add

```bash
# Essential components
npx shadcn@latest add button card input label

# Forms
npx shadcn@latest add form select textarea checkbox radio-group switch

# Navigation
npx shadcn@latest add dropdown-menu navigation-menu tabs

# Feedback
npx shadcn@latest add alert dialog toast

# Data Display
npx shadcn@latest add table badge avatar

# Layout
npx shadcn@latest add accordion separator sheet
```

## Best Practices

### 1. Component Organization

```
src/
├── components/
│   ├── ui/           # shadcn/ui components
│   ├── layout/       # Layout components
│   ├── features/     # Feature-specific components
│   └── shared/       # Shared custom components
```

### 2. Use Composition

```typescript
// ❌ Bad: Everything in one component
<Button onClick={handleSubmit} disabled={loading} className="w-full bg-blue-500">
  {loading ? 'Loading...' : 'Submit'}
</Button>

// ✅ Good: Compose smaller pieces
<Button onClick={handleSubmit} disabled={loading} className="w-full">
  {loading && <Spinner className="mr-2" />}
  {loading ? 'Loading...' : 'Submit'}
</Button>
```

### 3. Client Directives

```astro
<!-- Static (no JS needed) -->
<Card>
  <CardHeader><CardTitle>Static Card</CardTitle></CardHeader>
</Card>

<!-- Interactive (needs JS) -->
<Dialog client:load>
  <DialogTrigger>Open</DialogTrigger>
  <DialogContent>...</DialogContent>
</Dialog>
```

### 4. TypeScript Types

```typescript
import type { ButtonProps } from '@/components/ui/button';

interface CustomButtonProps extends ButtonProps {
  isLoading?: boolean;
}

export function CustomButton({ isLoading, children, ...props }: CustomButtonProps) {
  return (
    <Button {...props} disabled={isLoading || props.disabled}>
      {isLoading && <Spinner />}
      {children}
    </Button>
  );
}
```

## Troubleshooting

### Components not styled correctly?

Ensure Tailwind is processing the component files:

```javascript
// tailwind.config.mjs
export default {
  content: [
    './src/**/*.{astro,html,js,jsx,md,mdx,ts,tsx}'
    './components/**/*.{js,jsx,ts,tsx}' // Add this
  ]
};
```

### Dark mode not working?

Make sure the `dark` class is toggled on `<html>`:

```javascript
document.documentElement.classList.toggle('dark', isDark);
```

### Components not interactive?

Add `client:load` or `client:visible`:

```astro
<Dialog client:load>...</Dialog>
```

## Summary

shadcn/ui provides production-ready, accessible components that you can customize and own. Perfect for building modern web applications with Astro and React.
