/**
 * Function Executor Example
 *
 * Complete example of an A2A executor for function/tool calling
 * with dynamic function registration and parameter validation
 */

interface A2ATask {
  id: string
  type: string
  parameters: {
    function: string
    arguments: Record<string, any>
  }
}

interface A2AResult {
  taskId: string
  status: 'completed' | 'failed'
  result?: any
  error?: string
}

type FunctionHandler = (args: Record<string, any>) => Promise<any>

// Function Registry
class FunctionRegistry {
  private functions = new Map<string, FunctionHandler>()

  register(name: string, handler: FunctionHandler): void {
    this.functions.set(name, handler)
  }

  has(name: string): boolean {
    return this.functions.has(name)
  }

  async execute(name: string, args: Record<string, any>): Promise<any> {
    const handler = this.functions.get(name)
    if (!handler) {
      throw new Error(`Function not found: ${name}`)
    }
    return handler(args)
  }

  list(): string[] {
    return Array.from(this.functions.keys())
  }
}

// Global registry
const registry = new FunctionRegistry()

// Function Executor
async function executeFunctionTask(task: A2ATask): Promise<A2AResult> {
  try {
    // Validate task
    if (!task.parameters.function) {
      throw new Error('Function name is required')
    }

    if (!registry.has(task.parameters.function)) {
      throw new Error(`Function not registered: ${task.parameters.function}`)
    }

    // Execute function
    const result = await registry.execute(
      task.parameters.function,
      task.parameters.arguments || {}
    )

    return {
      taskId: task.id,
      status: 'completed',
      result
    }
  } catch (error) {
    console.error('Function execution failed:', {
      taskId: task.id,
      function: task.parameters.function,
      error
    })

    return {
      taskId: task.id,
      status: 'failed',
      error: error instanceof Error ? error.message : 'Unknown error'
    }
  }
}

// Example Functions

// Calculate function
registry.register('calculate', async (args) => {
  const { operation, values } = args

  if (!operation || !values) {
    throw new Error('Missing required parameters: operation, values')
  }

  switch (operation) {
    case 'sum':
      return values.reduce((a: number, b: number) => a + b, 0)
    case 'multiply':
      return values.reduce((a: number, b: number) => a * b, 1)
    case 'average':
      return values.reduce((a: number, b: number) => a + b, 0) / values.length
    default:
      throw new Error(`Unsupported operation: ${operation}`)
  }
})

// Search function
registry.register('search', async (args) => {
  const { query, limit = 10 } = args

  if (!query) {
    throw new Error('Query is required')
  }

  // Simulate search
  await new Promise(resolve => setTimeout(resolve, 500))

  return {
    query,
    results: Array.from({ length: Math.min(limit, 5) }, (_, i) => ({
      id: i + 1,
      title: `Result ${i + 1} for "${query}"`,
      score: 0.9 - i * 0.1
    }))
  }
})

// Data transformation function
registry.register('transform', async (args) => {
  const { data, transformType } = args

  if (!data) {
    throw new Error('Data is required')
  }

  switch (transformType) {
    case 'uppercase':
      return typeof data === 'string' ? data.toUpperCase() : data
    case 'lowercase':
      return typeof data === 'string' ? data.toLowerCase() : data
    case 'reverse':
      return typeof data === 'string' ? data.split('').reverse().join('') : data
    default:
      throw new Error(`Unsupported transform: ${transformType}`)
  }
})

// API call function
registry.register('api-call', async (args) => {
  const { endpoint, method = 'GET', body } = args

  if (!endpoint) {
    throw new Error('Endpoint is required')
  }

  // Simulate API call
  await new Promise(resolve => setTimeout(resolve, 800))

  return {
    status: 200,
    data: { message: 'Success', endpoint, method }
  }
})

// Export
export {
  executeFunctionTask,
  registry,
  A2ATask,
  A2AResult
}

// Example Usage
if (require.main === module) {
  const tasks: A2ATask[] = [
    {
      id: 'func-001',
      type: 'function-call',
      parameters: {
        function: 'calculate',
        arguments: {
          operation: 'sum',
          values: [1, 2, 3, 4, 5]
        }
      }
    },
    {
      id: 'func-002',
      type: 'function-call',
      parameters: {
        function: 'search',
        arguments: {
          query: 'quantum computing',
          limit: 5
        }
      }
    },
    {
      id: 'func-003',
      type: 'function-call',
      parameters: {
        function: 'transform',
        arguments: {
          data: 'Hello World',
          transformType: 'uppercase'
        }
      }
    }
  ]

  console.log('Available functions:', registry.list())
  console.log('\nExecuting tasks...\n')

  Promise.all(tasks.map(task => executeFunctionTask(task)))
    .then(results => {
      results.forEach((result, i) => {
        console.log(`Task ${i + 1}:`, JSON.stringify(result, null, 2))
      })
    })
}
