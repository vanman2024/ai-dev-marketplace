/**
 * Async A2A Executor - Long-Running Pattern
 *
 * Use for: Tasks that take time and need status updates
 * Examples: LLM inference, file processing, data analysis
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
  status: 'pending' | 'running' | 'completed' | 'failed'
  result?: any
  error?: string
  progress?: number
  metadata?: Record<string, any>
}

interface TaskState {
  task: A2ATask
  status: A2AResult['status']
  result?: any
  error?: string
  progress: number
  startTime: Date
  endTime?: Date
}

// Task Store
class TaskStore {
  private tasks = new Map<string, TaskState>()

  createTask(task: A2ATask): TaskState {
    const state: TaskState = {
      task,
      status: 'pending',
      progress: 0,
      startTime: new Date()
    }
    this.tasks.set(task.id, state)
    return state
  }

  updateTask(taskId: string, update: Partial<TaskState>): void {
    const state = this.tasks.get(taskId)
    if (state) {
      Object.assign(state, update)
    }
  }

  getTask(taskId: string): TaskState | undefined {
    return this.tasks.get(taskId)
  }

  deleteTask(taskId: string): void {
    this.tasks.delete(taskId)
  }
}

// Global task store
const taskStore = new TaskStore()

// Async Executor
async function submitTask(task: A2ATask): Promise<A2AResult> {
  // Create task state
  taskStore.createTask(task)

  // Start async execution (don't await)
  executeTaskAsync(task).catch(error => {
    console.error('Async execution error:', error)
    taskStore.updateTask(task.id, {
      status: 'failed',
      error: error.message,
      endTime: new Date()
    })
  })

  // Return immediate response
  return {
    taskId: task.id,
    status: 'pending',
    progress: 0,
    metadata: {
      submittedAt: new Date().toISOString()
    }
  }
}

async function executeTaskAsync(task: A2ATask): Promise<void> {
  try {
    // Update to running
    taskStore.updateTask(task.id, {
      status: 'running',
      progress: 10
    })

    // Execute task
    const result = await processLongRunningTask(task, (progress) => {
      taskStore.updateTask(task.id, { progress })
    })

    // Update to completed
    taskStore.updateTask(task.id, {
      status: 'completed',
      result,
      progress: 100,
      endTime: new Date()
    })

    // Optional: Send callback notification
    await sendCallback(task, result)
  } catch (error) {
    taskStore.updateTask(task.id, {
      status: 'failed',
      error: error instanceof Error ? error.message : 'Unknown error',
      endTime: new Date()
    })
  }
}

async function processLongRunningTask(
  task: A2ATask,
  onProgress: (progress: number) => void
): Promise<any> {
  // Simulate long-running task with progress updates
  const steps = 10
  for (let i = 0; i < steps; i++) {
    await new Promise(resolve => setTimeout(resolve, 500))
    onProgress(10 + (i + 1) * 8) // Progress from 10% to 90%
  }

  // Return result based on task type
  switch (task.type) {
    case 'llm-inference':
      return await runLLMInference(task.parameters)

    case 'file-processing':
      return await processFile(task.parameters)

    case 'data-analysis':
      return await analyzeData(task.parameters)

    default:
      throw new Error(`Unsupported task type: ${task.type}`)
  }
}

// Get Task Status
function getTaskStatus(taskId: string): A2AResult | null {
  const state = taskStore.getTask(taskId)
  if (!state) {
    return null
  }

  return {
    taskId,
    status: state.status,
    result: state.result,
    error: state.error,
    progress: state.progress,
    metadata: {
      startTime: state.startTime.toISOString(),
      endTime: state.endTime?.toISOString()
    }
  }
}

// Cancel Task
async function cancelTask(taskId: string): Promise<boolean> {
  const state = taskStore.getTask(taskId)
  if (!state || state.status === 'completed' || state.status === 'failed') {
    return false
  }

  taskStore.updateTask(taskId, {
    status: 'failed',
    error: 'Task cancelled',
    endTime: new Date()
  })

  return true
}

// Example Task Processors
async function runLLMInference(parameters: Record<string, any>): Promise<any> {
  // Implement LLM inference
  const { prompt, model } = parameters
  // Call LLM API here
  return {
    response: 'Generated response',
    model,
    tokens: 100
  }
}

async function processFile(parameters: Record<string, any>): Promise<any> {
  // Implement file processing
  const { fileUrl, operation } = parameters
  // Process file here
  return {
    processed: true,
    operation,
    fileUrl
  }
}

async function analyzeData(parameters: Record<string, any>): Promise<any> {
  // Implement data analysis
  const { data, analysisType } = parameters
  // Analyze data here
  return {
    analysis: 'Results',
    type: analysisType
  }
}

// Optional: Callback notification
async function sendCallback(task: A2ATask, result: any): Promise<void> {
  const callbackUrl = task.metadata?.callbackUrl
  if (!callbackUrl) return

  try {
    await fetch(callbackUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        taskId: task.id,
        status: 'completed',
        result
      })
    })
  } catch (error) {
    console.error('Callback failed:', error)
  }
}

// Export
export {
  A2ATask,
  A2AResult,
  submitTask,
  getTaskStatus,
  cancelTask,
  taskStore
}

// Example Usage
if (require.main === module) {
  const exampleTask: A2ATask = {
    id: 'async-task-001',
    type: 'llm-inference',
    parameters: {
      prompt: 'Explain quantum computing',
      model: 'gpt-4'
    }
  }

  submitTask(exampleTask)
    .then(result => {
      console.log('Task submitted:', result)

      // Poll for status
      const interval = setInterval(() => {
        const status = getTaskStatus(exampleTask.id)
        console.log('Status:', status)

        if (status?.status === 'completed' || status?.status === 'failed') {
          clearInterval(interval)
        }
      }, 1000)
    })
}
