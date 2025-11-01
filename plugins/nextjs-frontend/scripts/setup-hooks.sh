#!/bin/bash
# Setup lifecycle hooks for Next.js Frontend plugin

set -e

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_ROOT="${1:-.}"

echo "🔧 Setting up Next.js Frontend lifecycle hooks..."

# Check if we're in a git repository
if [ ! -d "$PROJECT_ROOT/.git" ]; then
  echo "❌ Not a git repository: $PROJECT_ROOT"
  echo "   Initialize git first: git init"
  exit 1
fi

# Create hooks directory if it doesn't exist
mkdir -p "$PROJECT_ROOT/.git/hooks"

# Install pre-commit hook
echo "📋 Installing pre-commit hook..."
cp "$PLUGIN_DIR/hooks/pre-commit.sh" "$PROJECT_ROOT/.git/hooks/pre-commit"
chmod +x "$PROJECT_ROOT/.git/hooks/pre-commit"

echo "✅ Hooks installed successfully!"
echo ""
echo "Installed hooks:"
echo "  - pre-commit: Validates design system before commits"
echo ""
echo "To test the pre-commit hook:"
echo "  1. Make changes to a component"
echo "  2. git add <file>"
echo "  3. git commit -m \"test\""
echo ""
echo "To bypass hooks (not recommended):"
echo "  git commit --no-verify"

exit 0
