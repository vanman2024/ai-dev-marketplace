---
name: testing-patterns
description: Testing patterns for Vercel AI SDK including mock providers, streaming tests, tool calling tests, snapshot testing, and test coverage strategies. Use when implementing tests, creating test suites, mocking AI providers, or when user mentions testing, mocks, test coverage, AI testing, streaming tests, or tool testing.
allowed-tools: Read, Write, Bash, Grep, Glob
---

# Testing Patterns for Vercel AI SDK

**Purpose:** Provide comprehensive testing templates, mock providers, and testing strategies for Vercel AI SDK applications.

**Activation Triggers:**
- Writing tests for AI features
- Creating mock AI providers
- Testing streaming responses
- Testing tool calling functionality
- Implementing test coverage
- Snapshot testing for AI outputs

**Key Resources:**
- `templates/mock-provider.ts` - Mock language model implementation
- `templates/streaming-test.ts` - Test streaming responses
- `templates/tool-calling-test.ts` - Test tool execution
- `templates/snapshot-test.ts` - Snapshot testing for outputs
- `scripts/generate-test-suite.sh` - Generate test scaffolds
- `scripts/run-coverage.sh` - Run tests with coverage
- `examples/` - Complete test suites for different features

## Mock Provider Pattern

**Template:** `templates/mock-provider.ts`

```typescript
import { createMockLanguageModelV1 } from 'ai/test'

const mockProvider = createMockLanguageModelV1({
  doGenerate: async ({ prompt, mode }) => ({
    text: 'Mocked response'
    finishReason: 'stop'
    usage: { promptTokens: 10, completionTokens: 20 }
  })
  doStream: async function* ({ prompt, mode }) {
    yield { type: 'text-delta', textDelta: 'Mocked ' }
    yield { type: 'text-delta', textDelta: 'streaming ' }
    yield { type: 'text-delta', textDelta: 'response' }
    yield {
      type: 'finish'
      finishReason: 'stop'
      usage: { promptTokens: 10, completionTokens: 20 }
    }
  }
})
```

## Testing Strategies

### 1. Unit Tests (Mock Providers)

Test AI functions without real API calls

### 2. Integration Tests (Real Providers)

Test with real providers in CI (with rate limits)

### 3. Snapshot Tests

Ensure consistent outputs over time

### 4. E2E Tests

Test complete user flows with mocks

## Test Coverage Goals

- Core Functions: >90%
- Error Handling: >80%
- Tool Calling: 100%
- Streaming: >85%

## Resources

**Templates:**
- `mock-provider.ts` - Complete mock implementation
- `streaming-test.ts` - Streaming test patterns
- `tool-calling-test.ts` - Tool execution tests
- `snapshot-test.ts` - Snapshot testing setup

**Scripts:**
- `generate-test-suite.sh` - Scaffold tests
- `run-coverage.sh` - Run with coverage

**Examples:**
- `complete-test-suite.test.ts` - Full test suite example

---

**Testing Frameworks:** Vitest, Jest, Node Test Runner
**SDK Version:** Vercel AI SDK 5+
**Coverage Tool:** c8, nyc, or built-in coverage

**Best Practice:** Use mock providers for fast, reliable tests
