import { createMockLanguageModelV1 } from 'ai/test'
import { generateText, streamText } from 'ai'

/**
 * Mock Language Model Provider Template
 *
 * This template shows how to create mock providers for testing
 * Vercel AI SDK applications without making real API calls.
 *
 * Usage in tests:
 * 1. Create mock provider with specific responses
 * 2. Use in generateText/streamText instead of real provider
 * 3. Assert on outputs and verify behavior
 */

// ============================================================================
// BASIC MOCK PROVIDER
// ============================================================================

export const basicMockProvider = createMockLanguageModelV1({
  doGenerate: async ({ prompt, mode }) => ({
    text: 'This is a mocked response',
    finishReason: 'stop',
    usage: {
      promptTokens: 10,
      completionTokens: 20
    }
  })
})

// Example test usage:
// const { text } = await generateText({
//   model: basicMockProvider,
//   prompt: 'Test prompt'
// })
// expect(text).toBe('This is a mocked response')

// ============================================================================
// STREAMING MOCK PROVIDER
// ============================================================================

export const streamingMockProvider = createMockLanguageModelV1({
  doStream: async function* ({ prompt, mode }) {
    // Simulate streaming chunks
    const chunks = ['Hello', ' ', 'world', '!']

    for (const chunk of chunks) {
      yield {
        type: 'text-delta' as const,
        textDelta: chunk
      }
    }

    // Finish stream
    yield {
      type: 'finish' as const,
      finishReason: 'stop' as const,
      usage: {
        promptTokens: 5,
        completionTokens: 4
      }
    }
  }
})

// Example test usage:
// const { textStream } = await streamText({
//   model: streamingMockProvider,
//   prompt: 'Test prompt'
// })
// const chunks = []
// for await (const chunk of textStream) {
//   chunks.push(chunk)
// }
// expect(chunks.join('')).toBe('Hello world!')

// ============================================================================
// TOOL-CALLING MOCK PROVIDER
// ============================================================================

export const toolCallingMockProvider = createMockLanguageModelV1({
  doGenerate: async ({ prompt, mode }) => ({
    text: null,
    toolCalls: [
      {
        toolCallType: 'function' as const,
        toolCallId: 'call_123',
        toolName: 'getWeather',
        args: JSON.stringify({ location: 'San Francisco' })
      }
    ],
    finishReason: 'tool-calls' as const,
    usage: {
      promptTokens: 15,
      completionTokens: 10
    }
  })
})

// Example test usage:
// const result = await generateText({
//   model: toolCallingMockProvider,
//   prompt: 'What is the weather?',
//   tools: {
//     getWeather: tool({
//       description: 'Get weather for location',
//       parameters: z.object({ location: z.string() }),
//       execute: async ({ location }) => ({ temp: 72 })
//     })
//   }
// })
// expect(result.toolCalls[0].toolName).toBe('getWeather')

// ============================================================================
// ERROR MOCK PROVIDER
// ============================================================================

export const errorMockProvider = createMockLanguageModelV1({
  doGenerate: async () => {
    throw new Error('API Error: Rate limit exceeded')
  }
})

// Example test usage:
// await expect(
//   generateText({
//     model: errorMockProvider,
//     prompt: 'Test'
//   })
// ).rejects.toThrow('API Error: Rate limit exceeded')

// ============================================================================
// CONFIGURABLE MOCK PROVIDER
// ============================================================================

export function createConfigurableMock(config: {
  response?: string
  streaming?: boolean
  delay?: number
  error?: Error
  toolCalls?: any[]
}) {
  const { response = 'Mock response', streaming = false, delay = 0, error, toolCalls } = config

  if (error) {
    return createMockLanguageModelV1({
      doGenerate: async () => {
        if (delay) await new Promise(r => setTimeout(r, delay))
        throw error
      }
    })
  }

  if (streaming) {
    return createMockLanguageModelV1({
      doStream: async function* () {
        if (delay) await new Promise(r => setTimeout(r, delay))

        const words = response.split(' ')
        for (const word of words) {
          yield { type: 'text-delta' as const, textDelta: word + ' ' }
        }

        yield {
          type: 'finish' as const,
          finishReason: 'stop' as const,
          usage: { promptTokens: 10, completionTokens: words.length }
        }
      }
    })
  }

  return createMockLanguageModelV1({
    doGenerate: async () => {
      if (delay) await new Promise(r => setTimeout(r, delay))

      return {
        text: toolCalls ? null : response,
        toolCalls: toolCalls || undefined,
        finishReason: toolCalls ? 'tool-calls' as const : 'stop' as const,
        usage: { promptTokens: 10, completionTokens: 20 }
      }
    }
  })
}

// Example test usage:
// const slowMock = createConfigurableMock({
//   response: 'Slow response',
//   delay: 1000
// })
//
// const errorMock = createConfigurableMock({
//   error: new Error('Custom error')
// })

// ============================================================================
// MOCK PROVIDER WITH STATE
// ============================================================================

export class StatefulMockProvider {
  private callCount = 0
  private responses: string[]

  constructor(responses: string[]) {
    this.responses = responses
  }

  getProvider() {
    return createMockLanguageModelV1({
      doGenerate: async () => {
        const response = this.responses[this.callCount % this.responses.length]
        this.callCount++

        return {
          text: response,
          finishReason: 'stop' as const,
          usage: { promptTokens: 10, completionTokens: 20 }
        }
      }
    })
  }

  getCallCount() {
    return this.callCount
  }

  reset() {
    this.callCount = 0
  }
}

// Example test usage:
// const stateful = new StatefulMockProvider([
//   'First response',
//   'Second response',
//   'Third response'
// ])
//
// const result1 = await generateText({ model: stateful.getProvider(), prompt: 'Test' })
// expect(result1.text).toBe('First response')
//
// const result2 = await generateText({ model: stateful.getProvider(), prompt: 'Test' })
// expect(result2.text).toBe('Second response')
//
// expect(stateful.getCallCount()).toBe(2)

// ============================================================================
// SNAPSHOT TESTING HELPER
// ============================================================================

export async function captureAIOutput(
  provider: any,
  prompt: string,
  options?: any
) {
  const result = await generateText({
    model: provider,
    prompt,
    ...options
  })

  return {
    text: result.text,
    finishReason: result.finishReason,
    usage: result.usage,
    toolCalls: result.toolCalls
  }
}

// Example test usage:
// const output = await captureAIOutput(mockProvider, 'Test prompt')
// expect(output).toMatchSnapshot()
