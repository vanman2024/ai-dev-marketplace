import { generateText, tool } from 'ai'
import { openai } from '@ai-sdk/openai'
import { z } from 'zod'

/**
 * ReAct Agent Pattern Template
 *
 * ReAct = Reasoning + Acting
 *
 * This pattern alternates between reasoning (thinking) and acting (using tools)
 * to solve complex problems through iterative refinement.
 *
 * Use when:
 * - Problem requires multi-step reasoning
 * - Need to verify/validate intermediate results
 * - Uncertainty about tool order
 * - Complex research or analysis tasks
 */

interface ReActConfig {
  maxIterations?: number
  maxTokens?: number
  maxDuration?: number
  verboseLogging?: boolean
}

interface ReActResult {
  answer: string
  steps: Array<{
    iteration: number
    thought: string
    action?: { tool: string; args: any }
    observation?: any
  }>
  iterations: number
  tokenUsage: { prompt: number; completion: number }
}

export async function reactAgent(
  task: string,
  tools: Record<string, any>,
  config: ReActConfig = {}
): Promise<ReActResult> {
  const {
    maxIterations = 10,
    maxTokens = 50000,
    maxDuration = 60000, // 60 seconds
    verboseLogging = false
  } = config

  const startTime = Date.now()
  const steps: ReActResult['steps'] = []
  let totalTokens = { prompt: 0, completion: 0 }
  let iteration = 0

  // System prompt for ReAct pattern
  const systemPrompt = `You are an expert problem solver using the ReAct (Reasoning + Acting) framework.

For each step:
1. THOUGHT: Explain your reasoning about what to do next
2. ACTION: Choose and use a tool (if needed)
3. OBSERVATION: Analyze the tool result
4. Repeat until you can answer the question

When you have enough information, provide a FINAL ANSWER.

Available tools:
${Object.entries(tools).map(([name, t]) => `- ${name}: ${t.description}`).join('\n')}

Format:
THOUGHT: <your reasoning>
ACTION: <tool name and parameters>
OBSERVATION: <what you learned>
... (repeat as needed)
FINAL ANSWER: <complete answer to the original question>`

  const messages: Array<{ role: 'system' | 'user' | 'assistant'; content: string }> = [
    { role: 'system', content: systemPrompt },
    { role: 'user', content: `Task: ${task}` }
  ]

  while (iteration < maxIterations) {
    iteration++

    // Check timeout
    if (Date.now() - startTime > maxDuration) {
      throw new Error('ReAct agent exceeded time limit')
    }

    // Check token limit
    if (totalTokens.prompt + totalTokens.completion > maxTokens) {
      throw new Error('ReAct agent exceeded token limit')
    }

    // Generate next step
    const result = await generateText({
      model: openai('gpt-4o'),
      messages,
      tools,
      maxToolRoundtrips: 1
    })

    // Update token usage
    totalTokens.prompt += result.usage?.promptTokens || 0
    totalTokens.completion += result.usage?.completionTokens || 0

    // Parse response
    const text = result.text
    const toolCalls = result.toolCalls

    // Check for final answer
    if (text.includes('FINAL ANSWER:')) {
      const answer = text.split('FINAL ANSWER:')[1].trim()

      if (verboseLogging) {
        console.log(`\n[Iteration ${iteration}] FINAL ANSWER`)
        console.log(answer)
      }

      return {
        answer,
        steps,
        iterations: iteration,
        tokenUsage: totalTokens
      }
    }

    // Extract thought
    const thoughtMatch = text.match(/THOUGHT:(.+?)(?=ACTION:|OBSERVATION:|FINAL ANSWER:|$)/s)
    const thought = thoughtMatch ? thoughtMatch[1].trim() : text

    // Record step
    const step: ReActResult['steps'][0] = {
      iteration,
      thought
    }

    if (verboseLogging) {
      console.log(`\n[Iteration ${iteration}]`)
      console.log('THOUGHT:', thought)
    }

    // Handle tool calls
    if (toolCalls && toolCalls.length > 0) {
      const toolCall = toolCalls[0]

      step.action = {
        tool: toolCall.toolName,
        args: toolCall.args
      }

      if (verboseLogging) {
        console.log('ACTION:', toolCall.toolName, toolCall.args)
      }

      // Execute tool (handled by SDK)
      // Observation will be in next iteration via tool results
    }

    steps.push(step)

    // Add assistant message to conversation
    messages.push({
      role: 'assistant',
      content: text
    })

    // Add tool results if any
    if (result.toolResults && result.toolResults.length > 0) {
      const observation = result.toolResults[0].result

      if (verboseLogging) {
        console.log('OBSERVATION:', observation)
      }

      // Update last step with observation
      steps[steps.length - 1].observation = observation
    }
  }

  // Max iterations reached
  throw new Error(`ReAct agent exceeded maximum iterations (${maxIterations})`)
}

// ============================================================================
// EXAMPLE USAGE
// ============================================================================

/**
 * Example: Math Problem Solver
 */
export async function mathProblemSolver(problem: string) {
  const tools = {
    calculate: tool({
      description: 'Perform mathematical calculations',
      parameters: z.object({
        expression: z.string().describe('Mathematical expression to evaluate')
      }),
      execute: async ({ expression }) => {
        try {
          // Safe eval using Function constructor (for demo only - use math library in production)
          const result = eval(expression)
          return { result, expression }
        } catch (error) {
          return { error: 'Invalid expression' }
        }
      }
    }),

    verify: tool({
      description: 'Verify a mathematical result',
      parameters: z.object({
        result: z.number(),
        originalProblem: z.string()
      }),
      execute: async ({ result, originalProblem }) => {
        // Verification logic
        return { verified: true, result }
      }
    })
  }

  return await reactAgent(problem, tools, {
    maxIterations: 5,
    verboseLogging: true
  })
}

/**
 * Example: Research Agent
 */
export async function researchAgent(question: string) {
  const tools = {
    search: tool({
      description: 'Search for information on the web',
      parameters: z.object({
        query: z.string().describe('Search query')
      }),
      execute: async ({ query }) => {
        // Implement actual search (web scraping, API, etc.)
        return {
          results: [
            { title: 'Result 1', snippet: 'Information about...' },
            { title: 'Result 2', snippet: 'More information...' }
          ]
        }
      }
    }),

    readArticle: tool({
      description: 'Read and extract content from an article',
      parameters: z.object({
        url: z.string().describe('Article URL')
      }),
      execute: async ({ url }) => {
        // Implement article reading
        return { content: 'Article content...' }
      }
    }),

    synthesize: tool({
      description: 'Synthesize information from multiple sources',
      parameters: z.object({
        sources: z.array(z.string())
      }),
      execute: async ({ sources }) => {
        return { synthesis: 'Combined insights from sources...' }
      }
    })
  }

  return await reactAgent(question, tools, {
    maxIterations: 10,
    verboseLogging: true
  })
}

/**
 * Example: Code Debugging Agent
 */
export async function debuggingAgent(code: string, error: string) {
  const tools = {
    analyzeError: tool({
      description: 'Analyze error message and stack trace',
      parameters: z.object({
        error: z.string()
      }),
      execute: async ({ error }) => {
        return {
          errorType: 'TypeError',
          line: 42,
          suggestion: 'Check variable type'
        }
      }
    }),

    checkSyntax: tool({
      description: 'Check code syntax',
      parameters: z.object({
        code: z.string()
      }),
      execute: async ({ code }) => {
        return { syntaxValid: true, issues: [] }
      }
    }),

    suggestFix: tool({
      description: 'Suggest code fix',
      parameters: z.object({
        issue: z.string(),
        code: z.string()
      }),
      execute: async ({ issue, code }) => {
        return {
          fixedCode: '// Fixed code here',
          explanation: 'Changed X to Y because...'
        }
      }
    })
  }

  return await reactAgent(
    `Debug this code:\n${code}\n\nError: ${error}`,
    tools,
    {
      maxIterations: 8,
      verboseLogging: true
    }
  )
}

// ============================================================================
// ADVANCED: ReAct with Memory
// ============================================================================

export class ReActAgentWithMemory {
  private memory: Array<{ task: string; result: ReActResult }> = []

  async execute(task: string, tools: Record<string, any>) {
    // Check if similar task was solved before
    const similar = this.findSimilarTask(task)

    if (similar) {
      console.log('Found similar task in memory, using previous approach...')
      // Could prime the agent with previous successful steps
    }

    const result = await reactAgent(task, tools, {
      maxIterations: 10,
      verboseLogging: true
    })

    // Store successful result
    this.memory.push({ task, result })

    return result
  }

  private findSimilarTask(task: string) {
    // Implement similarity matching (e.g., embedding similarity)
    return this.memory.find(m => m.task.includes(task.split(' ')[0]))
  }

  getMemory() {
    return this.memory
  }

  clearMemory() {
    this.memory = []
  }
}
