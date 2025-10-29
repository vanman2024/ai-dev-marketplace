#!/bin/bash
# Validate Astro project structure follows best practices

set -e

PROJECT_ROOT="${1:-.}"

echo "Validating Astro project structure..."
echo ""

ERRORS=0
WARNINGS=0

# Check for Astro project
if [ ! -f "$PROJECT_ROOT/astro.config.mjs" ] && [ ! -f "$PROJECT_ROOT/astro.config.ts" ]; then
  echo "❌ ERROR: No astro.config file found. Is this an Astro project?"
  ERRORS=$((ERRORS + 1))
else
  echo "✅ Astro config file found"
fi

# Check package.json
if [ ! -f "$PROJECT_ROOT/package.json" ]; then
  echo "❌ ERROR: No package.json found"
  ERRORS=$((ERRORS + 1))
else
  echo "✅ package.json found"

  # Check for Astro dependency
  if ! grep -q '"astro"' "$PROJECT_ROOT/package.json"; then
    echo "❌ ERROR: Astro not found in package.json dependencies"
    ERRORS=$((ERRORS + 1))
  fi
fi

# Check directory structure
echo ""
echo "Checking directory structure..."

if [ -d "$PROJECT_ROOT/src" ]; then
  echo "✅ src/ directory exists"
else
  echo "❌ ERROR: src/ directory missing"
  ERRORS=$((ERRORS + 1))
fi

if [ -d "$PROJECT_ROOT/src/pages" ]; then
  echo "✅ src/pages/ directory exists"
else
  echo "⚠️  WARNING: src/pages/ directory missing"
  WARNINGS=$((WARNINGS + 1))
fi

if [ -d "$PROJECT_ROOT/src/components" ]; then
  echo "✅ src/components/ directory exists"
else
  echo "⚠️  WARNING: src/components/ directory missing"
  WARNINGS=$((WARNINGS + 1))
fi

if [ -d "$PROJECT_ROOT/src/layouts" ]; then
  echo "✅ src/layouts/ directory exists"
else
  echo "⚠️  WARNING: src/layouts/ directory missing"
  WARNINGS=$((WARNINGS + 1))
fi

# Check for essential files
echo ""
echo "Checking essential files..."

if [ -f "$PROJECT_ROOT/src/pages/index.astro" ]; then
  echo "✅ index.astro exists"
else
  echo "⚠️  WARNING: No index.astro found in src/pages/"
  WARNINGS=$((WARNINGS + 1))
fi

if [ -f "$PROJECT_ROOT/src/pages/404.astro" ]; then
  echo "✅ Custom 404 page exists"
else
  echo "⚠️  WARNING: No custom 404.astro page"
  WARNINGS=$((WARNINGS + 1))
fi

if [ -f "$PROJECT_ROOT/tsconfig.json" ]; then
  echo "✅ tsconfig.json exists"
else
  echo "⚠️  WARNING: No tsconfig.json found (recommended for TypeScript)"
  WARNINGS=$((WARNINGS + 1))
fi

if [ -f "$PROJECT_ROOT/public/robots.txt" ]; then
  echo "✅ robots.txt exists"
else
  echo "⚠️  WARNING: No robots.txt found in public/"
  WARNINGS=$((WARNINGS + 1))
fi

# Check for layout
if [ -f "$PROJECT_ROOT/src/layouts/Layout.astro" ]; then
  echo "✅ Base layout exists"
else
  echo "⚠️  WARNING: No base Layout.astro found"
  WARNINGS=$((WARNINGS + 1))
fi

# Summary
echo ""
echo "================================"
echo "Validation Summary"
echo "================================"
echo "Errors: $ERRORS"
echo "Warnings: $WARNINGS"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
  echo "✅ Project structure is valid!"
  exit 0
elif [ $ERRORS -eq 0 ]; then
  echo "⚠️  Project structure is valid with warnings"
  exit 0
else
  echo "❌ Project structure has errors that need to be fixed"
  exit 1
fi
