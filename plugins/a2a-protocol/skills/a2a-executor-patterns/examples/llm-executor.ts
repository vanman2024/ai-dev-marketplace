/**
 * LLM Executor Example
 *
 * Complete example of an A2A executor for LLM inference tasks
 * with streaming support, retry logic, and proper error handling
 */

interface A2ATask {
  id: string
  type: string
  parameters: {
    prompt: string
    model: string
    maxTokens?: number
    temperature?: number
    stream?: boolean
  }
  metadata?: Record<string, any>
}

interface A2AResult {
  taskId: string
  status: 'completed' | 'failed'
  result?: {
    text: string
    model: string
    tokens: number
    finishReason: string
  }
  error?: string
}

// LLM Executor with Streaming
async function executeLLMTask(task: A2ATask): Promise<A2AResult> {
  try {
    // Validate task
    validateLLMTask(task)

    // Check if streaming is requested
    if (task.parameters.stream) {
      throw new Error('Use executeLLMTaskStreaming for streaming tasks')
    }

    // Execute LLM inference
    const result = await callLLM(task.parameters)

    return {
      taskId: task.id,
      status: 'completed',
      result
    }
  } catch (error) {
    console.error('LLM task failed:', { taskId: task.id, error })

    return {
      taskId: task.id,
      status: 'failed',
      error: error instanceof Error ? error.message : 'Unknown error'
    }
  }
}

// Streaming LLM Executor
async function* executeLLMTaskStreaming(task: A2ATask) {
  try {
    validateLLMTask(task)

    // Stream LLM response
    for await (const chunk of callLLMStreaming(task.parameters)) {
      yield {
        taskId: task.id,
        chunk: chunk.text,
        tokens: chunk.tokens,
        done: chunk.done
      }
    }
  } catch (error) {
    yield {
      taskId: task.id,
      error: error instanceof Error ? error.message : 'Unknown error',
      done: true
    }
  }
}

// Validation
function validateLLMTask(task: A2ATask): void {
  if (!task.parameters.prompt) {
    throw new Error('Prompt is required')
  }

  if (!task.parameters.model) {
    throw new Error('Model is required')
  }

  const validModels = ['gpt-4', 'gpt-3.5-turbo', 'claude-3-opus', 'claude-3-sonnet']
  if (!validModels.includes(task.parameters.model)) {
    throw new Error(`Invalid model. Must be one of: ${validModels.join(', ')}`)
  }
}

// Mock LLM Call (replace with actual API)
async function callLLM(parameters: A2ATask['parameters']) {
  // Simulate API call
  await new Promise(resolve => setTimeout(resolve, 1000))

  return {
    text: 'This is a simulated LLM response to: ' + parameters.prompt,
    model: parameters.model,
    tokens: 50,
    finishReason: 'stop'
  }
}

// Mock Streaming LLM Call
async function* callLLMStreaming(parameters: A2ATask['parameters']) {
  const response = 'This is a simulated streaming LLM response.'
  const words = response.split(' ')

  for (let i = 0; i < words.length; i++) {
    await new Promise(resolve => setTimeout(resolve, 100))

    yield {
      text: words[i] + ' ',
      tokens: i + 1,
      done: i === words.length - 1
    }
  }
}

// Export
export {
  executeLLMTask,
  executeLLMTaskStreaming,
  A2ATask,
  A2AResult
}

// Example Usage
if (require.main === module) {
  const task: A2ATask = {
    id: 'llm-task-001',
    type: 'llm-inference',
    parameters: {
      prompt: 'Explain quantum computing in simple terms',
      model: 'gpt-4',
      maxTokens: 200,
      temperature: 0.7
    }
  }

  // Non-streaming example
  console.log('Non-streaming execution:')
  executeLLMTask(task)
    .then(result => {
      console.log('Result:', JSON.stringify(result, null, 2))
    })

  // Streaming example
  console.log('\nStreaming execution:')
  const streamingTask = { ...task, parameters: { ...task.parameters, stream: true } }

  ;(async () => {
    for await (const chunk of executeLLMTaskStreaming(streamingTask)) {
      console.log('Chunk:', chunk)
    }
  })()
}
