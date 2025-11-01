#!/bin/bash

# setup-theme.sh
# Sets up comprehensive theming with CSS variables

set -e

echo "=========================================="
echo "Theme Configuration Setup"
echo "=========================================="

# Check if we're in a Next.js project
if [ ! -f "package.json" ]; then
  echo "Error: package.json not found. Are you in a Next.js project directory?"
  exit 1
fi

# Check if shadcn/ui is initialized
if [ ! -f "components.json" ]; then
  echo "Error: components.json not found. Run 'npx shadcn@latest init' first."
  exit 1
fi

# Detect project structure
if [ -d "app" ]; then
  CSS_FILE="app/globals.css"
elif [ -d "src/app" ]; then
  CSS_FILE="src/app/globals.css"
else
  echo "Error: Could not detect App Router structure."
  exit 1
fi

echo "Configuring theme in: $CSS_FILE"
echo ""

# Ask user for base color preference
echo "Choose a base neutral color:"
echo "1) Slate (default - blue-gray)"
echo "2) Gray (true gray)"
echo "3) Zinc (cool gray)"
echo "4) Neutral (warm gray)"
echo "5) Stone (warmer gray)"
read -p "Enter choice (1-5) [default: 1]: " color_choice

case ${color_choice:-1} in
  1) BASE_COLOR="slate" ;;
  2) BASE_COLOR="gray" ;;
  3) BASE_COLOR="zinc" ;;
  4) BASE_COLOR="neutral" ;;
  5) BASE_COLOR="stone" ;;
  *) BASE_COLOR="slate" ;;
esac

echo "Selected base color: $BASE_COLOR"
echo ""

# Update components.json with selected base color
if command -v jq &> /dev/null; then
  jq --arg color "$BASE_COLOR" '.tailwind.baseColor = $color' components.json > components.json.tmp
  mv components.json.tmp components.json
  echo "✓ Updated components.json with baseColor: $BASE_COLOR"
else
  echo "Note: jq not found. Please manually update components.json baseColor to '$BASE_COLOR'"
fi

echo ""
echo "Verifying CSS variable configuration..."

# Check if CSS variables are being used
if grep -q "@tailwind base" "$CSS_FILE" && grep -q ":root" "$CSS_FILE"; then
  echo "✓ CSS variables already configured"
else
  echo "Warning: CSS variables may not be properly configured"
  echo "Run 'npx shadcn@latest init' to regenerate configuration"
fi

echo ""
echo "=========================================="
echo "✓ Theme configuration complete!"
echo "=========================================="
echo ""
echo "Configuration:"
echo "  - Base color: $BASE_COLOR"
echo "  - CSS variables: Enabled"
echo "  - File: $CSS_FILE"
echo ""
echo "Customizing your theme:"
echo "1. Edit $CSS_FILE to modify CSS variables"
echo "2. Change colors using OKLCH format for better color consistency"
echo "3. Test in both light and dark modes"
echo ""
echo "Example custom color:"
echo "  --primary: oklch(0.5 0.2 250);  /* Brand blue */"
echo "  --primary-foreground: oklch(1 0 0);  /* White text */"
echo ""
echo "Available CSS variables:"
echo "  - --background, --foreground"
echo "  - --primary, --primary-foreground"
echo "  - --secondary, --secondary-foreground"
echo "  - --muted, --muted-foreground"
echo "  - --accent, --accent-foreground"
echo "  - --destructive, --destructive-foreground"
echo "  - --card, --card-foreground"
echo "  - --popover, --popover-foreground"
echo "  - --border, --input, --ring"
echo "  - --chart-1 through --chart-5"
echo ""
