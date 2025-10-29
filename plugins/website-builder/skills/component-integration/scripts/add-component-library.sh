#!/bin/bash
# add-component-library.sh - Integrate shadcn/ui or other component libraries

set -e

LIBRARY="${1:-shadcn-ui}"

echo "📦 Adding $LIBRARY component library..."
echo ""

case "$LIBRARY" in
  shadcn-ui|shadcn)
    echo "Setting up shadcn/ui for Astro..."
    echo ""

    # Check prerequisites
    if [ ! -f "tailwind.config.mjs" ] && [ ! -f "tailwind.config.ts" ]; then
      echo "❌ Error: Tailwind CSS not configured"
      echo "   Run: bash scripts/setup-tailwind.sh"
      exit 1
    fi

    # Install shadcn/ui dependencies
    echo "📦 Installing shadcn/ui dependencies..."
    npm install --save-dev @radix-ui/react-slot
    npm install class-variance-authority clsx tailwind-merge
    npm install lucide-react

    # Create components.json for shadcn/ui
    if [ ! -f "components.json" ]; then
      cat > components.json << 'EOF'
{
  "$schema": "https://ui.shadcn.com/schema.json",
  "style": "default",
  "rsc": false,
  "tsx": true,
  "tailwind": {
    "config": "tailwind.config.mjs",
    "css": "src/styles/global.css",
    "baseColor": "slate",
    "cssVariables": true,
    "prefix": ""
  },
  "aliases": {
    "components": "@/components",
    "utils": "@/lib/utils"
  }
}
EOF
      echo "✅ Created components.json"
    fi

    # Create lib/utils.ts if not exists
    mkdir -p src/lib
    if [ ! -f "src/lib/utils.ts" ]; then
      cat > src/lib/utils.ts << 'EOF'
import { type ClassValue, clsx } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}
EOF
      echo "✅ Created src/lib/utils.ts"
    fi

    echo ""
    echo "✅ shadcn/ui setup complete!"
    echo ""
    echo "📝 Next steps:"
    echo "   1. Add components: npx shadcn-ui@latest add button"
    echo "   2. Available components: button, card, dialog, form, input, etc."
    echo "   3. Documentation: https://ui.shadcn.com/docs/components"
    echo ""
    echo "Example usage:"
    echo "   import { Button } from '@/components/ui/button';"
    echo "   <Button variant=\"default\" size=\"lg\">Click me</Button>"
    ;;

  radix|radix-ui)
    echo "Setting up Radix UI..."
    echo ""

    echo "📦 Installing Radix UI primitives..."
    npm install @radix-ui/react-dialog @radix-ui/react-dropdown-menu
    npm install @radix-ui/react-popover @radix-ui/react-tabs
    npm install @radix-ui/react-tooltip @radix-ui/react-accordion

    echo ""
    echo "✅ Radix UI installed!"
    echo ""
    echo "📝 Next steps:"
    echo "   1. Import primitives: import * as Dialog from '@radix-ui/react-dialog';"
    echo "   2. Build custom components using Radix primitives"
    echo "   3. Style with Tailwind CSS"
    echo "   4. Documentation: https://www.radix-ui.com/primitives"
    ;;

  headless-ui|headlessui)
    echo "Setting up Headless UI..."
    echo ""

    echo "📦 Installing Headless UI..."
    npm install @headlessui/react

    echo ""
    echo "✅ Headless UI installed!"
    echo ""
    echo "📝 Next steps:"
    echo "   1. Import components: import { Dialog, Menu } from '@headlessui/react';"
    echo "   2. Use with Tailwind CSS for styling"
    echo "   3. Documentation: https://headlessui.com/"
    echo ""
    echo "Example usage:"
    echo "   import { Dialog } from '@headlessui/react';"
    echo "   <Dialog open={isOpen} onClose={() => setIsOpen(false)}>"
    echo "     <Dialog.Panel>...</Dialog.Panel>"
    echo "   </Dialog>"
    ;;

  react-icons)
    echo "Setting up React Icons..."
    echo ""

    echo "📦 Installing React Icons..."
    npm install react-icons

    echo ""
    echo "✅ React Icons installed!"
    echo ""
    echo "📝 Usage:"
    echo "   import { FaReact } from 'react-icons/fa';"
    echo "   import { AiOutlineHome } from 'react-icons/ai';"
    echo "   import { MdEmail } from 'react-icons/md';"
    echo ""
    echo "   <FaReact className=\"text-4xl text-blue-500\" />"
    echo ""
    echo "   Available icon packs: Font Awesome, Ant Design, Material Design, and more"
    echo "   Documentation: https://react-icons.github.io/react-icons/"
    ;;

  framer-motion)
    echo "Setting up Framer Motion..."
    echo ""

    echo "📦 Installing Framer Motion..."
    npm install framer-motion

    echo ""
    echo "✅ Framer Motion installed!"
    echo ""
    echo "📝 Usage:"
    echo "   import { motion } from 'framer-motion';"
    echo ""
    echo "   <motion.div"
    echo "     initial={{ opacity: 0 }}"
    echo "     animate={{ opacity: 1 }}"
    echo "     transition={{ duration: 0.5 }}"
    echo "   >"
    echo "     Content"
    echo "   </motion.div>"
    echo ""
    echo "   Documentation: https://www.framer.com/motion/"
    ;;

  *)
    echo "❌ Error: Unknown library: $LIBRARY"
    echo ""
    echo "Available libraries:"
    echo "  shadcn-ui        - shadcn/ui component library"
    echo "  radix-ui         - Radix UI primitives"
    echo "  headless-ui      - Headless UI components"
    echo "  react-icons      - Icon library"
    echo "  framer-motion    - Animation library"
    echo ""
    echo "Usage:"
    echo "  bash scripts/add-component-library.sh shadcn-ui"
    exit 1
    ;;
esac

echo ""
echo "💡 Pro tip: Use these libraries with Astro islands for optimal performance"
echo "   Example: <MyComponent client:visible />"
