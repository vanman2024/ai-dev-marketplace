#!/bin/bash
# Setup environment variables for AI Tech Stack 1 projects
# Works with: Website Builder, Next.js, FastAPI, Full-stack apps

set -e

PROJECT_DIR="${1:-.}"
PLUGIN_DIR="$(dirname "$(dirname "$(readlink -f "$0")")")"

echo "🔐 Setting up AI Tech Stack 1 environment variables"
echo "================================================"
echo "Project: $(basename "$PROJECT_DIR")"
echo ""

# Create .env from .env.example if it doesn't exist
if [ ! -f "$PROJECT_DIR/.env" ]; then
  if [ -f "$PLUGIN_DIR/.env.example" ]; then
    echo "📝 Copying .env.example to $PROJECT_DIR/.env"
    cp "$PLUGIN_DIR/.env.example" "$PROJECT_DIR/.env"
  else
    echo "❌ .env.example not found in plugin directory"
    exit 1
  fi
else
  echo "⚠️  .env already exists in $PROJECT_DIR"
  read -p "Do you want to overwrite it? (y/N) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    cp "$PLUGIN_DIR/.env.example" "$PROJECT_DIR/.env"
    echo "✅ Overwritten .env"
  fi
fi

# Check if we can load keys from bashrc project-specific config
if [ -f "$HOME/.bashrc" ]; then
  echo ""
  echo "🔍 Checking for project-specific keys in ~/.bashrc..."

  # Look for PROJECT_NAME_KEY pattern in bashrc
  PROJECT_NAME=$(basename "$PROJECT_DIR" | tr '[:lower:]' '[:upper:]' | tr '-' '_')

  # Function to try loading a key from bashrc
  load_key_from_bashrc() {
    local key_name=$1
    local env_var=$2

    # Try different patterns (project-specific, then AI Stack default, then bare name)
    for pattern in "${PROJECT_NAME}_${key_name}" "AI_STACK_${key_name}" "$key_name"; do
      if grep -q "export ${pattern}=" "$HOME/.bashrc" 2>/dev/null; then
        source "$HOME/.bashrc"
        local value=$(eval echo \$${pattern})
        if [ ! -z "$value" ]; then
          echo "  ✅ Found $key_name: $pattern"
          # Update .env file
          if grep -q "^${env_var}=" "$PROJECT_DIR/.env"; then
            sed -i "s|^${env_var}=.*|${env_var}=${value}|" "$PROJECT_DIR/.env"
          fi
          return 0
        fi
      fi
    done
    return 1
  }

  # Try loading common keys
  load_key_from_bashrc "ANTHROPIC_API_KEY" "ANTHROPIC_API_KEY" || echo "  ⚠️  ANTHROPIC_API_KEY not found in bashrc"
  load_key_from_bashrc "GOOGLE_API_KEY" "GOOGLE_API_KEY" || echo "  ⚠️  GOOGLE_API_KEY not found in bashrc"
  load_key_from_bashrc "SUPABASE_URL" "PUBLIC_SUPABASE_URL" || echo "  ⚠️  SUPABASE_URL not found in bashrc"
  load_key_from_bashrc "SUPABASE_ANON_KEY" "PUBLIC_SUPABASE_ANON_KEY" || echo "  ⚠️  SUPABASE_ANON_KEY not found in bashrc"
  load_key_from_bashrc "MEM0_API_KEY" "MEM0_API_KEY" || echo "  ⚠️  MEM0_API_KEY not found in bashrc"
fi

echo ""
echo "✅ Environment setup complete!"
echo ""
echo "Next steps:"
echo "1. Edit $PROJECT_DIR/.env and add your API keys"
echo "2. Make sure .env is in .gitignore (it should be by default)"
echo "3. Run 'source .env' to load variables (if needed)"
echo ""
echo "Required API keys:"
echo "  - ANTHROPIC_API_KEY (https://console.anthropic.com/settings/keys)"
echo "  - GOOGLE_API_KEY (https://aistudio.google.com/app/apikey)"
echo "  - PUBLIC_SUPABASE_URL (https://app.supabase.com/project/_/settings/api)"
echo "  - PUBLIC_SUPABASE_ANON_KEY (https://app.supabase.com/project/_/settings/api)"
echo ""
echo "Optional API keys:"
echo "  - MEM0_API_KEY (https://app.mem0.ai/dashboard/api-keys)"
echo "  - OPENAI_API_KEY (if using OpenAI models)"
