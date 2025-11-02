#!/bin/bash
# Provider Connection Tester
# Tests actual connection to AI provider API

set -e

PROVIDER=${1:-"openai"}
PROJECT_ROOT=${2:-.}

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔌 Testing connection to $PROVIDER...${NC}"
echo ""

# Load environment variables from .env
if [ -f "$PROJECT_ROOT/.env" ]; then
    export $(cat "$PROJECT_ROOT/.env" | grep -v '^#' | xargs)
fi

# Detect project type
if [ -f "$PROJECT_ROOT/package.json" ]; then
    PROJECT_TYPE="node"
elif [ -f "$PROJECT_ROOT/requirements.txt" ] || [ -f "$PROJECT_ROOT/pyproject.toml" ]; then
    PROJECT_TYPE="python"
else
    echo -e "${RED}❌ Could not detect project type${NC}"
    exit 1
fi

# Create test file based on provider and project type
if [ "$PROJECT_TYPE" = "node" ]; then
    TEST_FILE="$PROJECT_ROOT/.provider-test.mjs"

    case "$PROVIDER" in
        openai)
            cat > "$TEST_FILE" << 'EOF'
import { openai } from '@ai-sdk/openai';
import { generateText } from 'ai';

try {
  console.log('🔄 Testing OpenAI connection...');
  const result = await generateText({
    model: openai('gpt-3.5-turbo'),
    prompt: 'Say "Connection successful!" in exactly 3 words.',
    maxTokens: 10,
  });
  console.log('✅ Connection successful!');
  console.log('Response:', result.text);
  process.exit(0);
} catch (error) {
  console.error('❌ Connection failed:', error.message);
  if (error.statusCode === 401) {
    console.error('   Invalid API key. Check your OPENAI_API_KEY');
  } else if (error.statusCode === 429) {
    console.error('   Rate limited. Try again later or upgrade your API tier');
  }
  process.exit(1);
}
EOF
            ;;
        anthropic)
            cat > "$TEST_FILE" << 'EOF'
import { anthropic } from '@ai-sdk/anthropic';
import { generateText } from 'ai';

try {
  console.log('🔄 Testing Anthropic connection...');
  const result = await generateText({
    model: anthropic('claude-haiku-4-20250514'),
    prompt: 'Say "Connection successful!" in exactly 3 words.',
    maxTokens: 10,
  });
  console.log('✅ Connection successful!');
  console.log('Response:', result.text);
  process.exit(0);
} catch (error) {
  console.error('❌ Connection failed:', error.message);
  if (error.status === 401) {
    console.error('   Invalid API key. Check your ANTHROPIC_API_KEY');
  } else if (error.status === 429) {
    console.error('   Rate limited. Try again later');
  }
  process.exit(1);
}
EOF
            ;;
        google)
            cat > "$TEST_FILE" << 'EOF'
import { google } from '@ai-sdk/google';
import { generateText } from 'ai';

try {
  console.log('🔄 Testing Google connection...');
  const result = await generateText({
    model: google('gemini-1.5-flash'),
    prompt: 'Say "Connection successful!" in exactly 3 words.',
    maxTokens: 10,
  });
  console.log('✅ Connection successful!');
  console.log('Response:', result.text);
  process.exit(0);
} catch (error) {
  console.error('❌ Connection failed:', error.message);
  if (error.statusCode === 401) {
    console.error('   Invalid API key. Check your GOOGLE_GENERATIVE_AI_API_KEY');
  }
  process.exit(1);
}
EOF
            ;;
        xai)
            cat > "$TEST_FILE" << 'EOF'
import { xai } from '@ai-sdk/xai';
import { generateText } from 'ai';

try {
  console.log('🔄 Testing xAI connection...');
  const result = await generateText({
    model: xai('grok-beta'),
    prompt: 'Say "Connection successful!" in exactly 3 words.',
    maxTokens: 10,
  });
  console.log('✅ Connection successful!');
  console.log('Response:', result.text);
  process.exit(0);
} catch (error) {
  console.error('❌ Connection failed:', error.message);
  if (error.statusCode === 401) {
    console.error('   Invalid API key. Check your XAI_API_KEY');
  }
  process.exit(1);
}
EOF
            ;;
    esac

    echo "Running connection test..."
    if node "$TEST_FILE"; then
        echo ""
        echo -e "${GREEN}✅ Provider connection test passed!${NC}"
        rm -f "$TEST_FILE"
        exit 0
    else
        echo ""
        echo -e "${RED}❌ Provider connection test failed${NC}"
        rm -f "$TEST_FILE"
        exit 1
    fi

elif [ "$PROJECT_TYPE" = "python" ]; then
    TEST_FILE="$PROJECT_ROOT/.provider_test.py"

    case "$PROVIDER" in
        openai)
            cat > "$TEST_FILE" << 'EOF'
import os
from openai import OpenAI

try:
    print("🔄 Testing OpenAI connection...")
    client = OpenAI()
    response = client.chat.completions.create(
        model="gpt-3.5-turbo",
        messages=[{"role": "user", "content": "Say 'Connection successful!' in exactly 3 words."}],
        max_tokens=10
    )
    print("✅ Connection successful!")
    print("Response:", response.choices[0].message.content)
except Exception as e:
    print(f"❌ Connection failed: {str(e)}")
    if "401" in str(e):
        print("   Invalid API key. Check your OPENAI_API_KEY")
    elif "429" in str(e):
        print("   Rate limited. Try again later")
    exit(1)
EOF
            ;;
        anthropic)
            cat > "$TEST_FILE" << 'EOF'
import os
from anthropic import Anthropic

try:
    print("🔄 Testing Anthropic connection...")
    client = Anthropic()
    response = client.messages.create(
        model="claude-haiku-4-20250514",
        max_tokens=10,
        messages=[{"role": "user", "content": "Say 'Connection successful!' in exactly 3 words."}]
    )
    print("✅ Connection successful!")
    print("Response:", response.content[0].text)
except Exception as e:
    print(f"❌ Connection failed: {str(e)}")
    if "401" in str(e):
        print("   Invalid API key. Check your ANTHROPIC_API_KEY")
    exit(1)
EOF
            ;;
    esac

    echo "Running connection test..."
    if python3 "$TEST_FILE"; then
        echo ""
        echo -e "${GREEN}✅ Provider connection test passed!${NC}"
        rm -f "$TEST_FILE"
        exit 0
    else
        echo ""
        echo -e "${RED}❌ Provider connection test failed${NC}"
        rm -f "$TEST_FILE"
        exit 1
    fi
fi
