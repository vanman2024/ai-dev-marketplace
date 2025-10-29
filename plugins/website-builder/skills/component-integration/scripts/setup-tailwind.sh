#!/bin/bash
# setup-tailwind.sh - Install and configure Tailwind CSS

set -e

echo "🎨 Setting up Tailwind CSS for Astro..."

# Check if we're in an Astro project
if [ ! -f "astro.config.mjs" ] && [ ! -f "astro.config.ts" ]; then
  echo "❌ Error: Not in an Astro project directory"
  exit 1
fi

# Install Tailwind CSS and Astro Tailwind integration
echo "📦 Installing Tailwind CSS dependencies..."
npm install @astrojs/tailwind tailwindcss
npm install --save-dev autoprefixer postcss

# Install additional Tailwind utilities
echo "📦 Installing Tailwind utilities..."
npm install --save-dev @tailwindcss/typography @tailwindcss/forms @tailwindcss/container-queries

# Optional: Install CVA for variant management
echo "📦 Installing class-variance-authority..."
npm install class-variance-authority clsx tailwind-merge

# Check if @astrojs/tailwind is already in config
CONFIG_FILE="astro.config.mjs"
if [ -f "astro.config.ts" ]; then
  CONFIG_FILE="astro.config.ts"
fi

if grep -q "@astrojs/tailwind" "$CONFIG_FILE"; then
  echo "✅ Tailwind integration already configured in $CONFIG_FILE"
else
  echo "⚙️  Adding Tailwind integration to $CONFIG_FILE..."
  echo ""
  echo "⚠️  Manual step required:"
  echo "   Add '@astrojs/tailwind' to integrations array in $CONFIG_FILE"
  echo ""
  echo "   Example:"
  echo "   import tailwind from '@astrojs/tailwind';"
  echo "   export default defineConfig({"
  echo "     integrations: [tailwind({ applyBaseStyles: true })]"
  echo "   });"
fi

# Create Tailwind config if it doesn't exist
if [ ! -f "tailwind.config.mjs" ] && [ ! -f "tailwind.config.ts" ]; then
  echo "⚙️  Creating tailwind.config.mjs..."
  cat > tailwind.config.mjs << 'EOF'
/** @type {import('tailwindcss').Config} */
export default {
  content: ['./src/**/*.{astro,html,js,jsx,md,mdx,svelte,ts,tsx,vue}'],
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#f0f9ff',
          100: '#e0f2fe',
          200: '#bae6fd',
          300: '#7dd3fc',
          400: '#38bdf8',
          500: '#0ea5e9',
          600: '#0284c7',
          700: '#0369a1',
          800: '#075985',
          900: '#0c4a6e',
          950: '#082f49',
        },
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        mono: ['Fira Code', 'monospace'],
      },
    },
  },
  plugins: [
    require('@tailwindcss/typography'),
    require('@tailwindcss/forms'),
    require('@tailwindcss/container-queries'),
  ],
}
EOF
  echo "✅ Created tailwind.config.mjs"
else
  echo "✅ Tailwind config already exists"
fi

# Create base CSS file
if [ ! -d "src/styles" ]; then
  mkdir -p src/styles
  echo "📁 Created src/styles directory"
fi

if [ ! -f "src/styles/global.css" ]; then
  cat > src/styles/global.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
    --color-primary: 0 107 179;
    --color-secondary: 100 116 139;
    --color-accent: 236 72 153;

    --font-sans: 'Inter', system-ui, sans-serif;
    --font-mono: 'Fira Code', monospace;
  }

  html {
    font-family: var(--font-sans);
  }

  body {
    @apply bg-white text-gray-900 dark:bg-gray-950 dark:text-gray-100;
  }
}

@layer components {
  .btn {
    @apply px-4 py-2 rounded-md font-medium transition-colors;
  }

  .btn-primary {
    @apply bg-primary-600 text-white hover:bg-primary-700;
  }

  .btn-secondary {
    @apply bg-gray-200 text-gray-900 hover:bg-gray-300;
  }

  .card {
    @apply bg-white dark:bg-gray-900 rounded-lg shadow-md p-6;
  }
}

@layer utilities {
  .text-balance {
    text-wrap: balance;
  }

  .animate-fade-in {
    animation: fadeIn 0.5s ease-in;
  }

  @keyframes fadeIn {
    from {
      opacity: 0;
    }
    to {
      opacity: 1;
    }
  }
}
EOF
  echo "✅ Created src/styles/global.css"
else
  echo "✅ Global CSS file already exists"
fi

# Create utility functions file
cat > src/lib/utils.ts << 'EOF'
import { type ClassValue, clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

/**
 * Merge Tailwind CSS classes with clsx and tailwind-merge
 * Useful for conditional classes and avoiding conflicts
 */
export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
EOF

if [ ! -d "src/lib" ]; then
  mkdir -p src/lib
fi

echo "✅ Created src/lib/utils.ts"

echo ""
echo "✅ Tailwind CSS setup complete!"
echo ""
echo "📝 Next steps:"
echo "   1. Verify @astrojs/tailwind is in integrations array"
echo "   2. Import global.css in your main layout:"
echo "      import '@/styles/global.css';"
echo "   3. Customize tailwind.config.mjs with your design tokens"
echo "   4. Use Tailwind utilities in components"
echo ""
echo "Example usage:"
echo "   <div class=\"container mx-auto px-4\">"
echo "     <h1 class=\"text-4xl font-bold text-primary-600\">"
echo "       Hello Tailwind!"
echo "     </h1>"
echo "   </div>"
