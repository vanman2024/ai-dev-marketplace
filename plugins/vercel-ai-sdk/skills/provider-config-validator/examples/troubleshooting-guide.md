# Provider Configuration Troubleshooting Guide

Quick reference for common Vercel AI SDK provider configuration issues and their solutions.

## Quick Diagnostics

```bash
# Run full provider validation
./scripts/validate-provider.sh openai

# Check model compatibility
./scripts/check-model-compatibility.sh anthropic claude-3-opus

# Test provider connection
./scripts/test-provider-connection.sh google

# Generate fix for specific issue
./scripts/generate-fix.sh missing-api-key openai
```

## Common Issues

### 1. Missing API Key Error

**Error Message:**
```
Error: Missing OPENAI_API_KEY environment variable
```

**Cause:** No .env file or API key not set

**Quick Fix:**
```bash
./scripts/generate-fix.sh missing-api-key openai
```

**Manual Fix:**
1. Create `.env` file in project root
2. Add: `OPENAI_API_KEY=sk-proj-your-actual-key`
3. Get key from: https://platform.openai.com/api-keys
4. Ensure `.env` is in `.gitignore`

---

### 2. Invalid API Key Format

**Error Message:**
```
401 Unauthorized - Invalid API key
```

**Cause:** API key has wrong format

**Check Format:**
```bash
./scripts/generate-fix.sh wrong-format anthropic
```

**Valid Formats:**
- **OpenAI**: `sk-proj-...` or `sk-...` (48-56 chars)
- **Anthropic**: `sk-ant-api03-...` (~108 chars)
- **Google**: `AIza...` (39 chars)
- **xAI**: `xai-...`
- **Groq**: `gsk_...`

---

### 3. Package Not Installed

**Error Message:**
```
Cannot find module '@ai-sdk/openai'
```

**Quick Fix:**
```bash
./scripts/generate-fix.sh missing-package openai
```

**Manual Fix:**
```bash
npm install ai @ai-sdk/openai
# or for Python
pip install openai
```

**Verify Installation:**
```bash
# Node.js
npm ls @ai-sdk/openai

# Python
pip show openai
```

---

### 4. Invalid Model Name

**Error Message:**
```
404 Model not found: claude-v3-opus
```

**Check Valid Models:**
```bash
./scripts/check-model-compatibility.sh anthropic claude-v3-opus
```

**Common Mistakes:**
- ❌ `claude-v3-opus` → ✅ `claude-3-opus-20240229`
- ❌ `gpt4` → ✅ `gpt-4`
- ❌ `gemini-pro` → ✅ `gemini-1.5-pro`

**See All Valid Models:**
```bash
./scripts/generate-fix.sh model-compatibility openai
```

---

### 5. Rate Limiting (429 Error)

**Error Message:**
```
429 Too Many Requests - Rate limit exceeded
```

**Quick Fix - Add Retry Logic:**
```bash
./scripts/generate-fix.sh rate-limiting
```

This creates a retry helper with exponential backoff.

**Other Solutions:**
1. Wait and try again later
2. Upgrade your API tier for higher limits
3. Implement request queuing
4. Use multiple API keys with load balancing

---

### 6. Wrong Import Statements

**Error Message:**
```
SyntaxError: Cannot use import statement outside a module
```

**Quick Fix:**
```bash
./scripts/generate-fix.sh import-error openai
```

**For ESM (package.json with "type": "module"):**
```typescript
import { openai } from '@ai-sdk/openai';
import { generateText } from 'ai';
```

**Ensure package.json has:**
```json
{
  "type": "module"
}
```

---

### 7. Environment Variables Not Loading

**Symptoms:**
- API key is in .env but still shows as undefined
- Works locally but not in production

**Solutions:**

**Node.js/TypeScript:**
```typescript
// At top of entry file
import 'dotenv/config';

// Or explicitly
import dotenv from 'dotenv';
dotenv.config();
```

**Next.js:**
- Prefix browser variables with `NEXT_PUBLIC_`
- Server variables don't need prefix
- Never expose API keys to browser!

**Vercel/Deployment:**
1. Go to project settings
2. Add environment variables
3. Redeploy

---

### 8. CORS Errors (Browser)

**Error Message:**
```
CORS policy: No 'Access-Control-Allow-Origin' header
```

**Cause:** Trying to call AI provider from browser (frontend)

**Solution:**
- ✅ Call AI providers from server/API routes only
- ❌ Never call AI providers directly from browser
- ❌ Never expose API keys in client-side code

**Correct Pattern (Next.js):**
```typescript
// app/api/chat/route.ts (SERVER)
import { openai } from '@ai-sdk/openai';
import { streamText } from 'ai';

export async function POST(req: Request) {
  const { messages } = await req.json();

  const result = streamText({
    model: openai('gpt-4')
    messages
  });

  return result.toDataStreamResponse();
}
```

```typescript
// app/page.tsx (CLIENT)
import { useChat } from 'ai/react';

export default function Chat() {
  const { messages, input, handleSubmit } = useChat({
    api: '/api/chat', // Calls your API route, not provider directly
  });
  // ...
}
```

---

### 9. Streaming Not Working

**Symptoms:**
- No chunks received
- Response comes all at once
- Blank screen during generation

**Checks:**
```typescript
// Ensure using streamText, not generateText
import { streamText } from 'ai';

const result = streamText({ // ✅ Stream
  model: openai('gpt-4')
  prompt: 'Write a story'
});

// For UI hooks
const { messages } = useChat(); // ✅ Handles streaming
```

**Verify Response Headers:**
```typescript
// API Route should return streaming response
return result.toDataStreamResponse();
```

---

### 10. TypeScript Errors

**Error Message:**
```
Type 'string' is not assignable to type 'LanguageModel'
```

**Cause:** Missing types or wrong SDK version

**Fix:**
```bash
# Ensure latest SDK
npm install ai@latest @ai-sdk/openai@latest

# Check TypeScript config
npx tsc --noEmit
```

**tsconfig.json should have:**
```json
{
  "compilerOptions": {
    "module": "ESNext"
    "moduleResolution": "bundler"
    "esModuleInterop": true
  }
}
```

---

## Provider-Specific Issues

### OpenAI

**Invalid Organization ID:**
```
Error: Invalid organization ID
```

**Fix:** Remove organization ID or verify it's correct:
```typescript
import { createOpenAI } from '@ai-sdk/openai';

const openai = createOpenAI({
  apiKey: process.env.OPENAI_API_KEY
  // organization: 'org-...' // Optional, remove if causing issues
});
```

### Anthropic

**Prompt Too Long:**
```
Error: Prompt exceeds maximum context length
```

**Fix:** Claude 3.5 Sonnet supports 200K tokens. Reduce prompt or use truncation:
```typescript
const result = await generateText({
  model: anthropic('claude-sonnet-4-5-20250929')
  prompt: truncatePrompt(longPrompt, 180000), // Leave buffer
});
```

### Google Gemini

**Safety Settings Block:**
```
Error: Response blocked due to safety settings
```

**Fix:** Adjust safety settings:
```typescript
import { google } from '@ai-sdk/google';

const result = await generateText({
  model: google('gemini-1.5-pro', {
    safetySettings: [
      { category: 'HARM_CATEGORY_HARASSMENT', threshold: 'BLOCK_NONE' }
    ]
  })
  prompt: 'Your prompt'
});
```

### xAI Grok

**Beta Access Required:**
```
Error: Model not available
```

**Fix:** Grok is in beta. Request access at https://console.x.ai/

---

## Validation Workflow

**Full diagnostic workflow:**

```bash
# 1. Validate provider configuration
./scripts/validate-provider.sh openai

# 2. If errors found, generate fixes
./scripts/generate-fix.sh missing-api-key openai

# 3. Verify model compatibility
./scripts/check-model-compatibility.sh openai gpt-4o

# 4. Test actual connection
./scripts/test-provider-connection.sh openai

# 5. Run your application
npm run dev
```

---

## Getting Help

If issues persist:

1. **Check SDK version:** `npm ls ai`
2. **Check provider status:** Provider status pages
3. **Review docs:** https://ai-sdk.dev/docs
4. **GitHub issues:** https://github.com/vercel/ai/issues
5. **Discord:** Vercel AI SDK Discord community

---

**Last Updated:** January 2025
**SDK Version:** Vercel AI SDK 5+
