/**
 * Streaming A2A Executor
 *
 * Use for: Results that should be delivered incrementally
 * Examples: Text generation, real-time data, progressive results
 */

// Task and Result Types
interface A2ATask {
  id: string
  type: string
  parameters: Record<string, any>
}

interface StreamChunk {
  taskId: string
  index: number
  data: any
  done: boolean
}

// Streaming Executor
async function* executeStreamingTask(
  task: A2ATask
): AsyncGenerator<StreamChunk, void, unknown> {
  try {
    // Validate task
    if (!task.id || !task.type) {
      throw new Error('Invalid task structure')
    }

    // Stream based on task type
    switch (task.type) {
      case 'text-generation':
        yield* streamTextGeneration(task)
        break

      case 'data-processing':
        yield* streamDataProcessing(task)
        break

      case 'file-streaming':
        yield* streamFileData(task)
        break

      default:
        throw new Error(`Unsupported streaming task: ${task.type}`)
    }
  } catch (error) {
    // Send error chunk
    yield {
      taskId: task.id,
      index: -1,
      data: { error: error instanceof Error ? error.message : 'Unknown error' },
      done: true
    }
  }
}

// Example: Text Generation Streaming
async function* streamTextGeneration(
  task: A2ATask
): AsyncGenerator<StreamChunk, void, unknown> {
  const { prompt, maxTokens = 100 } = task.parameters

  // Simulate streaming text generation
  const text = 'This is a simulated streaming response from an LLM...'
  const words = text.split(' ')

  for (let i = 0; i < words.length; i++) {
    await new Promise(resolve => setTimeout(resolve, 100))

    yield {
      taskId: task.id,
      index: i,
      data: {
        text: words[i] + ' ',
        tokens: i + 1
      },
      done: false
    }
  }

  // Final chunk
  yield {
    taskId: task.id,
    index: words.length,
    data: {
      text: '',
      tokens: words.length,
      complete: true
    },
    done: true
  }
}

// Example: Data Processing Streaming
async function* streamDataProcessing(
  task: A2ATask
): AsyncGenerator<StreamChunk, void, unknown> {
  const { items } = task.parameters

  if (!Array.isArray(items)) {
    throw new Error('Items must be an array')
  }

  for (let i = 0; i < items.length; i++) {
    await new Promise(resolve => setTimeout(resolve, 50))

    const processed = await processItem(items[i])

    yield {
      taskId: task.id,
      index: i,
      data: {
        item: processed,
        progress: ((i + 1) / items.length) * 100
      },
      done: i === items.length - 1
    }
  }
}

// Example: File Streaming
async function* streamFileData(
  task: A2ATask
): AsyncGenerator<StreamChunk, void, unknown> {
  const { fileUrl, chunkSize = 1024 } = task.parameters

  // Simulate file streaming
  const totalChunks = 10
  for (let i = 0; i < totalChunks; i++) {
    await new Promise(resolve => setTimeout(resolve, 100))

    yield {
      taskId: task.id,
      index: i,
      data: {
        chunk: `Chunk ${i + 1}/${totalChunks}`,
        bytes: (i + 1) * chunkSize
      },
      done: i === totalChunks - 1
    }
  }
}

// Helper function
async function processItem(item: any): Promise<any> {
  // Simulate processing
  return { ...item, processed: true }
}

// HTTP Streaming Response (Express example)
function setupStreamingEndpoint(app: any) {
  app.post('/execute/stream', async (req: any, res: any) => {
    const task: A2ATask = req.body

    res.setHeader('Content-Type', 'text/event-stream')
    res.setHeader('Cache-Control', 'no-cache')
    res.setHeader('Connection', 'keep-alive')

    try {
      for await (const chunk of executeStreamingTask(task)) {
        res.write(`data: ${JSON.stringify(chunk)}\n\n`)

        if (chunk.done) {
          res.end()
          break
        }
      }
    } catch (error) {
      res.write(`data: ${JSON.stringify({
        error: error instanceof Error ? error.message : 'Stream error'
      })}\n\n`)
      res.end()
    }
  })
}

// WebSocket Streaming (alternative)
function handleWebSocketStreaming(ws: any, task: A2ATask) {
  (async () => {
    try {
      for await (const chunk of executeStreamingTask(task)) {
        ws.send(JSON.stringify(chunk))

        if (chunk.done) {
          ws.close()
          break
        }
      }
    } catch (error) {
      ws.send(JSON.stringify({
        error: error instanceof Error ? error.message : 'Stream error'
      }))
      ws.close()
    }
  })()
}

// Export
export {
  A2ATask,
  StreamChunk,
  executeStreamingTask,
  setupStreamingEndpoint,
  handleWebSocketStreaming
}

// Example Usage
if (require.main === module) {
  const exampleTask: A2ATask = {
    id: 'stream-task-001',
    type: 'text-generation',
    parameters: {
      prompt: 'Explain quantum computing',
      maxTokens: 100
    }
  }

  ;(async () => {
    console.log('Starting stream...\n')

    for await (const chunk of executeStreamingTask(exampleTask)) {
      console.log('Chunk:', JSON.stringify(chunk, null, 2))

      if (chunk.done) {
        console.log('\nStream complete!')
        break
      }
    }
  })()
}
