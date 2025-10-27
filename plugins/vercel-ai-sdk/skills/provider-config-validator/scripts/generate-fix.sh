#!/bin/bash
# Fix Generator
# Generates code snippets and configuration fixes for common provider issues

set -e

ISSUE_TYPE=${1:-""}
PROVIDER=${2:-"openai"}
PROJECT_ROOT=${3:-.}

if [ -z "$ISSUE_TYPE" ]; then
    echo "Usage: $0 <issue-type> [provider] [project-root]"
    echo ""
    echo "Available issue types:"
    echo "  - missing-api-key      Create .env with API key"
    echo "  - wrong-format         Show correct key format"
    echo "  - missing-package      Generate install commands"
    echo "  - model-compatibility  Suggest compatible models"
    echo "  - rate-limiting        Add retry logic"
    echo "  - import-error         Fix import statements"
    exit 1
fi

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Detect project type
if [ -f "$PROJECT_ROOT/package.json" ]; then
    PROJECT_TYPE="node"
    if grep -q '"type": "module"' "$PROJECT_ROOT/package.json"; then
        MODULE_TYPE="esm"
    else
        MODULE_TYPE="commonjs"
    fi
elif [ -f "$PROJECT_ROOT/tsconfig.json" ]; then
    PROJECT_TYPE="typescript"
    MODULE_TYPE="esm"
elif [ -f "$PROJECT_ROOT/requirements.txt" ] || [ -f "$PROJECT_ROOT/pyproject.toml" ]; then
    PROJECT_TYPE="python"
else
    PROJECT_TYPE="node"
    MODULE_TYPE="esm"
fi

echo -e "${BLUE}🔧 Generating fix for: $ISSUE_TYPE${NC}"
echo "   Provider: $PROVIDER"
echo "   Project type: $PROJECT_TYPE"
echo ""

case "$ISSUE_TYPE" in
    missing-api-key)
        echo -e "${GREEN}📝 Creating .env file with API key template${NC}"
        echo ""

        case "$PROVIDER" in
            openai)
                ENV_VAR="OPENAI_API_KEY"
                EXAMPLE="sk-proj-abc123..."
                DOCS="https://platform.openai.com/api-keys"
                ;;
            anthropic)
                ENV_VAR="ANTHROPIC_API_KEY"
                EXAMPLE="sk-ant-abc123..."
                DOCS="https://console.anthropic.com/"
                ;;
            google)
                ENV_VAR="GOOGLE_GENERATIVE_AI_API_KEY"
                EXAMPLE="AIza..."
                DOCS="https://makersuite.google.com/app/apikey"
                ;;
            xai)
                ENV_VAR="XAI_API_KEY"
                EXAMPLE="xai-abc123..."
                DOCS="https://console.x.ai/"
                ;;
            *)
                ENV_VAR="${PROVIDER^^}_API_KEY"
                EXAMPLE="your-api-key-here"
                DOCS="Check your provider console"
                ;;
        esac

        cat > "$PROJECT_ROOT/.env" << EOF
# Vercel AI SDK - Provider API Keys
# DO NOT commit this file to git!

# $PROVIDER API Key
$ENV_VAR=$EXAMPLE

# Get your API key from: $DOCS
EOF

        # Add to .gitignore if it exists
        if [ -f "$PROJECT_ROOT/.gitignore" ]; then
            if ! grep -q "^\.env$" "$PROJECT_ROOT/.gitignore"; then
                echo ".env" >> "$PROJECT_ROOT/.gitignore"
                echo "✅ Added .env to .gitignore"
            fi
        else
            echo ".env" > "$PROJECT_ROOT/.gitignore"
            echo "✅ Created .gitignore with .env"
        fi

        echo "✅ Created .env file at: $PROJECT_ROOT/.env"
        echo ""
        echo -e "${YELLOW}⚠️  IMPORTANT: Replace the placeholder with your actual API key${NC}"
        echo "   Get your key from: $DOCS"
        ;;

    wrong-format)
        echo -e "${GREEN}📋 Correct API key format for $PROVIDER:${NC}"
        echo ""

        case "$PROVIDER" in
            openai)
                echo "Format: sk-proj-XXXXXXXX..."
                echo "Length: ~48-56 characters"
                echo "Prefix: sk-proj- (new keys) or sk- (legacy)"
                echo ""
                echo "Example: sk-proj-abc123def456..."
                ;;
            anthropic)
                echo "Format: sk-ant-api03-XXXXXXXX..."
                echo "Length: ~108 characters"
                echo "Prefix: sk-ant-"
                echo ""
                echo "Example: sk-ant-api03-abc123..."
                ;;
            google)
                echo "Format: AIzaXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
                echo "Length: 39 characters"
                echo "Prefix: AIza"
                ;;
            xai)
                echo "Format: xai-XXXXXXXX..."
                echo "Prefix: xai-"
                ;;
        esac

        echo ""
        echo "Get valid key from provider console:"
        case "$PROVIDER" in
            openai) echo "https://platform.openai.com/api-keys" ;;
            anthropic) echo "https://console.anthropic.com/" ;;
            google) echo "https://makersuite.google.com/app/apikey" ;;
            xai) echo "https://console.x.ai/" ;;
        esac
        ;;

    missing-package)
        echo -e "${GREEN}📦 Installing missing provider package${NC}"
        echo ""

        if [ "$PROJECT_TYPE" = "python" ]; then
            case "$PROVIDER" in
                openai) PKG="openai" ;;
                anthropic) PKG="anthropic" ;;
                google) PKG="google-generativeai" ;;
                *) PKG="$PROVIDER" ;;
            esac

            echo "Command: pip install $PKG"
            echo ""
            read -p "Install now? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                pip install "$PKG"
                echo "✅ Package installed"
            fi
        else
            # Node.js/TypeScript
            case "$PROVIDER" in
                openai) PKG="@ai-sdk/openai" ;;
                anthropic) PKG="@ai-sdk/anthropic" ;;
                google) PKG="@ai-sdk/google" ;;
                xai) PKG="@ai-sdk/xai" ;;
                groq) PKG="@ai-sdk/groq" ;;
                *) PKG="@ai-sdk/$PROVIDER" ;;
            esac

            echo "Commands:"
            echo "  npm install ai $PKG"
            echo "  # or"
            echo "  pnpm add ai $PKG"
            echo "  # or"
            echo "  yarn add ai $PKG"
            echo ""
            read -p "Install with npm? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                npm install ai "$PKG"
                echo "✅ Packages installed"
            fi
        fi
        ;;

    model-compatibility)
        echo -e "${GREEN}🤖 Recommended models for $PROVIDER:${NC}"
        echo ""

        case "$PROVIDER" in
            openai)
                echo "Recommended:"
                echo "  • gpt-4o (best overall, vision support)"
                echo "  • gpt-4o-mini (fast, cost-effective)"
                echo "  • gpt-4-turbo (previous gen, reliable)"
                echo ""
                echo "All models:"
                echo "  • gpt-4o, gpt-4o-mini"
                echo "  • gpt-4, gpt-4-turbo"
                echo "  • gpt-3.5-turbo"
                echo "  • o1-preview, o1-mini (reasoning)"
                ;;
            anthropic)
                echo "Recommended:"
                echo "  • claude-3-5-sonnet-20241022 (best, computer use)"
                echo "  • claude-3-5-haiku-20241022 (fast, affordable)"
                echo ""
                echo "All models:"
                echo "  • claude-3-5-sonnet-20241022"
                echo "  • claude-3-5-haiku-20241022"
                echo "  • claude-3-opus-20240229"
                echo "  • claude-3-sonnet-20240229"
                echo "  • claude-3-haiku-20240307"
                ;;
            google)
                echo "Recommended:"
                echo "  • gemini-1.5-pro (2M context)"
                echo "  • gemini-1.5-flash (fast)"
                echo ""
                echo "All models:"
                echo "  • gemini-1.5-pro"
                echo "  • gemini-1.5-flash"
                echo "  • gemini-2.0-flash-exp (experimental)"
                ;;
            xai)
                echo "Available models:"
                echo "  • grok-beta"
                echo "  • grok-vision-beta (vision support)"
                echo "  • grok-2-latest"
                ;;
        esac
        ;;

    rate-limiting)
        echo -e "${GREEN}🔄 Adding retry logic with exponential backoff${NC}"
        echo ""

        if [ "$PROJECT_TYPE" = "python" ]; then
            cat > "$PROJECT_ROOT/retry_helper.py" << 'EOF'
"""Retry helper with exponential backoff for rate limiting"""
import time
from typing import Callable, TypeVar, Any

T = TypeVar('T')

async def retry_with_backoff(
    fn: Callable[..., T],
    max_retries: int = 3,
    base_delay: float = 1.0,
    *args: Any,
    **kwargs: Any
) -> T:
    """
    Retry a function with exponential backoff on rate limit errors.

    Args:
        fn: Async function to retry
        max_retries: Maximum number of retry attempts
        base_delay: Base delay in seconds (doubles each retry)
        *args, **kwargs: Arguments to pass to fn

    Returns:
        Result from fn

    Raises:
        Last exception if all retries fail
    """
    for attempt in range(max_retries):
        try:
            return await fn(*args, **kwargs)
        except Exception as e:
            # Check if it's a rate limit error (429)
            if hasattr(e, 'status_code') and e.status_code == 429:
                if attempt < max_retries - 1:
                    delay = base_delay * (2 ** attempt)
                    print(f"Rate limited. Retrying in {delay}s... (attempt {attempt + 1}/{max_retries})")
                    time.sleep(delay)
                    continue
            raise e

    raise Exception(f"Failed after {max_retries} retries")

# Usage example:
# from openai import AsyncOpenAI
#
# async def generate():
#     client = AsyncOpenAI()
#     return await retry_with_backoff(
#         client.chat.completions.create,
#         model="gpt-4",
#         messages=[{"role": "user", "content": "Hello"}]
#     )
EOF
            echo "✅ Created retry_helper.py"
        else
            # TypeScript/JavaScript
            if [ "$PROJECT_TYPE" = "typescript" ]; then
                EXT="ts"
            else
                EXT="js"
            fi

            cat > "$PROJECT_ROOT/retryHelper.$EXT" << 'EOF'
/**
 * Retry helper with exponential backoff for rate limiting
 */
export async function retryWithBackoff<T>(
  fn: () => Promise<T>,
  maxRetries: number = 3,
  baseDelay: number = 1000
): Promise<T> {
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error: any) {
      // Check if it's a rate limit error (429)
      if (error.status === 429 || error.statusCode === 429) {
        if (attempt < maxRetries - 1) {
          const delay = baseDelay * Math.pow(2, attempt);
          console.log(`Rate limited. Retrying in ${delay}ms... (attempt ${attempt + 1}/${maxRetries})`);
          await new Promise(resolve => setTimeout(resolve, delay));
          continue;
        }
      }
      throw error;
    }
  }
  throw new Error(`Failed after ${maxRetries} retries`);
}

// Usage example:
// import { generateText } from 'ai';
// import { openai } from '@ai-sdk/openai';
//
// const result = await retryWithBackoff(() =>
//   generateText({
//     model: openai('gpt-4'),
//     prompt: 'Hello',
//   })
// );
EOF
            echo "✅ Created retryHelper.$EXT"
        fi

        echo ""
        echo "Import and use in your code to handle rate limiting automatically"
        ;;

    import-error)
        echo -e "${GREEN}📥 Correct import statements for $PROVIDER${NC}"
        echo ""

        if [ "$PROJECT_TYPE" = "python" ]; then
            case "$PROVIDER" in
                openai)
                    cat << 'EOF'
# Python - OpenAI with Vercel AI SDK
from openai import AsyncOpenAI

client = AsyncOpenAI()

# Or for streaming:
from openai import OpenAI
client = OpenAI()
EOF
                    ;;
                anthropic)
                    cat << 'EOF'
# Python - Anthropic
from anthropic import Anthropic

client = Anthropic()
EOF
                    ;;
            esac
        else
            # TypeScript/JavaScript
            if [ "$MODULE_TYPE" = "esm" ]; then
                case "$PROVIDER" in
                    openai)
                        cat << 'EOF'
// ESM - OpenAI with Vercel AI SDK
import { openai } from '@ai-sdk/openai';
import { generateText, streamText } from 'ai';

const result = await generateText({
  model: openai('gpt-4'),
  prompt: 'Hello',
});
EOF
                        ;;
                    anthropic)
                        cat << 'EOF'
// ESM - Anthropic with Vercel AI SDK
import { anthropic } from '@ai-sdk/anthropic';
import { generateText } from 'ai';

const result = await generateText({
  model: anthropic('claude-3-5-sonnet-20241022'),
  prompt: 'Hello',
});
EOF
                        ;;
                    google)
                        cat << 'EOF'
// ESM - Google with Vercel AI SDK
import { google } from '@ai-sdk/google';
import { generateText } from 'ai';

const result = await generateText({
  model: google('gemini-1.5-pro'),
  prompt: 'Hello',
});
EOF
                        ;;
                esac
            else
                echo "// CommonJS imports not recommended for AI SDK"
                echo "// Consider using ESM (type: \"module\" in package.json)"
            fi
        fi
        ;;

    *)
        echo "Unknown issue type: $ISSUE_TYPE"
        echo ""
        echo "Available types: missing-api-key, wrong-format, missing-package, model-compatibility, rate-limiting, import-error"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}✅ Fix generated successfully${NC}"
