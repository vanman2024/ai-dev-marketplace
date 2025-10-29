#!/bin/bash
# validate-integration.sh - Validate component integration setup

set -e

echo "🔍 Validating component integration setup..."
echo ""

ERRORS=0
WARNINGS=0

# Function to check file exists
check_file() {
  if [ -f "$1" ]; then
    echo "✅ Found: $1"
    return 0
  else
    echo "❌ Missing: $1"
    ((ERRORS++))
    return 1
  fi
}

# Function to check directory exists
check_dir() {
  if [ -d "$1" ]; then
    echo "✅ Found: $1"
    return 0
  else
    echo "⚠️  Missing: $1"
    ((WARNINGS++))
    return 1
  fi
}

# Function to check package is installed
check_package() {
  if grep -q "\"$1\"" package.json 2>/dev/null; then
    echo "✅ Package installed: $1"
    return 0
  else
    echo "❌ Package missing: $1"
    ((ERRORS++))
    return 1
  fi
}

# Function to check config contains integration
check_integration() {
  CONFIG_FILE="astro.config.mjs"
  if [ -f "astro.config.ts" ]; then
    CONFIG_FILE="astro.config.ts"
  fi

  if grep -q "$1" "$CONFIG_FILE" 2>/dev/null; then
    echo "✅ Integration configured: $1"
    return 0
  else
    echo "⚠️  Integration not found in config: $1"
    ((WARNINGS++))
    return 1
  fi
}

echo "📋 Checking project structure..."
echo ""

# Check Astro project
if ! check_file "astro.config.mjs" && ! check_file "astro.config.ts"; then
  echo ""
  echo "❌ CRITICAL: Not an Astro project"
  echo "   astro.config.mjs or astro.config.ts not found"
  exit 1
fi

check_file "package.json"
check_file "tsconfig.json"

echo ""
echo "📦 Checking React integration..."
echo ""

check_package "react"
check_package "react-dom"
check_package "@astrojs/react"
check_package "@types/react"
check_integration "@astrojs/react"
check_dir "src/components"

echo ""
echo "📝 Checking MDX integration..."
echo ""

check_package "@astrojs/mdx"
check_integration "@astrojs/mdx"
check_dir "src/content"

# Check for common MDX plugins
if grep -q "remark-gfm" package.json 2>/dev/null; then
  echo "✅ remark-gfm installed"
else
  echo "⚠️  remark-gfm not installed (recommended)"
  ((WARNINGS++))
fi

if grep -q "rehype-slug" package.json 2>/dev/null; then
  echo "✅ rehype-slug installed"
else
  echo "⚠️  rehype-slug not installed (recommended)"
  ((WARNINGS++))
fi

echo ""
echo "🎨 Checking Tailwind CSS integration..."
echo ""

check_package "@astrojs/tailwind"
check_package "tailwindcss"
check_integration "@astrojs/tailwind"

if check_file "tailwind.config.mjs" || check_file "tailwind.config.ts"; then
  echo "✅ Tailwind config found"
else
  echo "❌ Tailwind config missing"
  ((ERRORS++))
fi

check_dir "src/styles"

# Check for Tailwind plugins
if grep -q "@tailwindcss/typography" package.json 2>/dev/null; then
  echo "✅ @tailwindcss/typography installed"
else
  echo "⚠️  @tailwindcss/typography not installed (recommended for prose)"
  ((WARNINGS++))
fi

echo ""
echo "🔧 Checking utility libraries..."
echo ""

# Check for CVA
if grep -q "class-variance-authority" package.json 2>/dev/null; then
  echo "✅ class-variance-authority installed"
else
  echo "⚠️  class-variance-authority not installed (recommended for variants)"
  ((WARNINGS++))
fi

# Check for clsx and tailwind-merge
if grep -q "clsx" package.json 2>/dev/null; then
  echo "✅ clsx installed"
else
  echo "⚠️  clsx not installed (recommended for class merging)"
  ((WARNINGS++))
fi

if grep -q "tailwind-merge" package.json 2>/dev/null; then
  echo "✅ tailwind-merge installed"
else
  echo "⚠️  tailwind-merge not installed (recommended for class merging)"
  ((WARNINGS++))
fi

echo ""
echo "📊 Validation Summary"
echo "===================="
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
  echo "✅ All checks passed! Component integration is properly configured."
  echo ""
  echo "🚀 You're ready to build components!"
  exit 0
elif [ $ERRORS -eq 0 ]; then
  echo "⚠️  Validation passed with $WARNINGS warnings"
  echo ""
  echo "   Your setup is functional but could be improved."
  echo "   Review warnings above for recommended packages."
  exit 0
else
  echo "❌ Validation failed with $ERRORS errors and $WARNINGS warnings"
  echo ""
  echo "   Please address the errors above before proceeding."
  echo ""
  echo "   Common fixes:"
  echo "   - Run setup scripts: setup-react.sh, setup-mdx.sh, setup-tailwind.sh"
  echo "   - Install missing packages: npm install <package-name>"
  echo "   - Add integrations to astro.config file"
  exit 1
fi
