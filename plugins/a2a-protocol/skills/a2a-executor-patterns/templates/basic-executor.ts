/**
 * Basic A2A Executor - Synchronous Pattern
 *
 * Use for: Simple, fast tasks with immediate results
 * Examples: Validation, quick transformations, data formatting
 */

// Task and Result Types
interface A2ATask {
  id: string
  type: string
  parameters: Record<string, any>
  metadata?: Record<string, any>
}

interface A2AResult {
  taskId: string
  status: 'completed' | 'failed'
  result?: any
  error?: string
  metadata?: Record<string, any>
}

// Error Classes
class ValidationError extends Error {
  constructor(message: string) {
    super(message)
    this.name = 'ValidationError'
  }
}

class ExecutionError extends Error {
  constructor(message: string) {
    super(message)
    this.name = 'ExecutionError'
  }
}

// Task Validation
function validateTask(task: A2ATask): void {
  if (!task.id) {
    throw new ValidationError('Task ID is required')
  }

  if (!task.type) {
    throw new ValidationError('Task type is required')
  }

  if (!task.parameters || typeof task.parameters !== 'object') {
    throw new ValidationError('Task parameters must be an object')
  }
}

// Main Executor Function
async function executeTask(task: A2ATask): Promise<A2AResult> {
  try {
    // Step 1: Validate input
    validateTask(task)

    // Step 2: Process task based on type
    let result: any

    switch (task.type) {
      case 'validate-data':
        result = await validateData(task.parameters)
        break

      case 'transform-data':
        result = await transformData(task.parameters)
        break

      case 'compute-result':
        result = await computeResult(task.parameters)
        break

      default:
        throw new ExecutionError(`Unsupported task type: ${task.type}`)
    }

    // Step 3: Return successful result
    return {
      taskId: task.id,
      status: 'completed',
      result,
      metadata: {
        executedAt: new Date().toISOString(),
        executionTime: 0 // Add timing if needed
      }
    }
  } catch (error) {
    // Error handling
    console.error('Task execution failed:', {
      taskId: task.id,
      error: error instanceof Error ? error.message : 'Unknown error'
    })

    return {
      taskId: task.id,
      status: 'failed',
      error: error instanceof Error ? error.message : 'Unknown error',
      metadata: {
        failedAt: new Date().toISOString()
      }
    }
  }
}

// Example Task Handlers
async function validateData(parameters: Record<string, any>): Promise<any> {
  // Implement validation logic
  const { data, schema } = parameters

  // Example: simple validation
  if (!data) {
    throw new ValidationError('Data is required')
  }

  return {
    valid: true,
    data
  }
}

async function transformData(parameters: Record<string, any>): Promise<any> {
  // Implement transformation logic
  const { input, transformType } = parameters

  // Example: simple transformation
  return {
    transformed: input,
    type: transformType
  }
}

async function computeResult(parameters: Record<string, any>): Promise<any> {
  // Implement computation logic
  const { values, operation } = parameters

  // Example: simple computation
  return {
    result: values,
    operation
  }
}

// Export
export {
  A2ATask,
  A2AResult,
  executeTask,
  validateTask,
  ValidationError,
  ExecutionError
}

// Example Usage
if (require.main === module) {
  const exampleTask: A2ATask = {
    id: 'task-001',
    type: 'validate-data',
    parameters: {
      data: { name: 'test', value: 42 },
      schema: {}
    }
  }

  executeTask(exampleTask)
    .then(result => {
      console.log('Result:', JSON.stringify(result, null, 2))
    })
    .catch(error => {
      console.error('Error:', error)
    })
}
