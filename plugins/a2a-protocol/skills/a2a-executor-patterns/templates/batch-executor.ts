/**
 * Batch A2A Executor
 *
 * Use for: Processing multiple related tasks efficiently
 * Examples: Bulk operations, parallel processing, resource optimization
 */

// Task and Result Types
interface A2ATask {
  id: string
  type: string
  parameters: Record<string, any>
}

interface A2AResult {
  taskId: string
  status: 'completed' | 'failed'
  result?: any
  error?: string
}

interface BatchResult {
  batchId: string
  totalTasks: number
  completedTasks: number
  failedTasks: number
  results: A2AResult[]
  duration: number
}

// Batch Configuration
interface BatchConfig {
  maxBatchSize: number
  maxConcurrency: number
  timeout: number
  retryFailures: boolean
}

const DEFAULT_BATCH_CONFIG: BatchConfig = {
  maxBatchSize: 100,
  maxConcurrency: 10,
  timeout: 30000,
  retryFailures: true
}

// Batch Executor
async function executeBatch(
  tasks: A2ATask[],
  config: Partial<BatchConfig> = {}
): Promise<BatchResult> {
  const cfg = { ...DEFAULT_BATCH_CONFIG, ...config }
  const batchId = generateBatchId()
  const startTime = Date.now()

  console.log(`Starting batch ${batchId} with ${tasks.length} tasks`)

  // Validate batch size
  if (tasks.length > cfg.maxBatchSize) {
    throw new Error(`Batch size ${tasks.length} exceeds maximum ${cfg.maxBatchSize}`)
  }

  // Execute tasks in parallel batches
  const results = await executeInBatches(tasks, cfg)

  const duration = Date.now() - startTime
  const completedTasks = results.filter(r => r.status === 'completed').length
  const failedTasks = results.filter(r => r.status === 'failed').length

  console.log(`Batch ${batchId} completed: ${completedTasks} succeeded, ${failedTasks} failed`)

  return {
    batchId,
    totalTasks: tasks.length,
    completedTasks,
    failedTasks,
    results,
    duration
  }
}

// Execute tasks in controlled batches
async function executeInBatches(
  tasks: A2ATask[],
  config: BatchConfig
): Promise<A2AResult[]> {
  const results: A2AResult[] = []
  const chunks = chunkArray(tasks, config.maxConcurrency)

  for (let i = 0; i < chunks.length; i++) {
    console.log(`Processing batch chunk ${i + 1}/${chunks.length}`)

    const chunkResults = await Promise.all(
      chunks[i].map(task => executeTaskWithTimeout(task, config.timeout))
    )

    results.push(...chunkResults)
  }

  return results
}

// Execute single task with timeout
async function executeTaskWithTimeout(
  task: A2ATask,
  timeout: number
): Promise<A2AResult> {
  try {
    const result = await Promise.race([
      executeTask(task),
      new Promise<never>((_, reject) =>
        setTimeout(() => reject(new Error('Task timeout')), timeout)
      )
    ])

    return {
      taskId: task.id,
      status: 'completed',
      result
    }
  } catch (error) {
    return {
      taskId: task.id,
      status: 'failed',
      error: error instanceof Error ? error.message : 'Unknown error'
    }
  }
}

// Execute single task
async function executeTask(task: A2ATask): Promise<any> {
  // Simulate task execution
  await new Promise(resolve => setTimeout(resolve, Math.random() * 1000))

  switch (task.type) {
    case 'process-data':
      return processData(task.parameters)

    case 'validate-item':
      return validateItem(task.parameters)

    case 'transform-item':
      return transformItem(task.parameters)

    default:
      throw new Error(`Unsupported task type: ${task.type}`)
  }
}

// Optimized batch processing with grouping
async function executeBatchWithGrouping(
  tasks: A2ATask[],
  config: Partial<BatchConfig> = {}
): Promise<BatchResult> {
  const cfg = { ...DEFAULT_BATCH_CONFIG, ...config }

  // Group tasks by type for optimized processing
  const groupedTasks = groupTasksByType(tasks)

  const allResults: A2AResult[] = []
  let completedCount = 0
  let failedCount = 0

  // Process each group
  for (const [type, typeTasks] of Object.entries(groupedTasks)) {
    console.log(`Processing ${typeTasks.length} tasks of type: ${type}`)

    const results = await executeInBatches(typeTasks, cfg)
    allResults.push(...results)

    completedCount += results.filter(r => r.status === 'completed').length
    failedCount += results.filter(r => r.status === 'failed').length
  }

  return {
    batchId: generateBatchId(),
    totalTasks: tasks.length,
    completedTasks: completedCount,
    failedTasks: failedCount,
    results: allResults,
    duration: 0
  }
}

// Helper: Group tasks by type
function groupTasksByType(tasks: A2ATask[]): Record<string, A2ATask[]> {
  return tasks.reduce((groups, task) => {
    const type = task.type
    if (!groups[type]) {
      groups[type] = []
    }
    groups[type].push(task)
    return groups
  }, {} as Record<string, A2ATask[]>)
}

// Helper: Chunk array
function chunkArray<T>(array: T[], size: number): T[][] {
  const chunks: T[][] = []
  for (let i = 0; i < array.length; i += size) {
    chunks.push(array.slice(i, i + size))
  }
  return chunks
}

// Helper: Generate batch ID
function generateBatchId(): string {
  return `batch-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`
}

// Example task handlers
async function processData(parameters: Record<string, any>): Promise<any> {
  return { processed: true, data: parameters.data }
}

async function validateItem(parameters: Record<string, any>): Promise<any> {
  return { valid: true, item: parameters.item }
}

async function transformItem(parameters: Record<string, any>): Promise<any> {
  return { transformed: true, item: parameters.item }
}

// Export
export {
  A2ATask,
  A2AResult,
  BatchResult,
  BatchConfig,
  executeBatch,
  executeBatchWithGrouping
}

// Example Usage
if (require.main === module) {
  const exampleTasks: A2ATask[] = Array.from({ length: 25 }, (_, i) => ({
    id: `task-${i + 1}`,
    type: i % 3 === 0 ? 'process-data' : i % 3 === 1 ? 'validate-item' : 'transform-item',
    parameters: { data: `Item ${i + 1}` }
  }))

  executeBatch(exampleTasks, {
    maxConcurrency: 5,
    timeout: 5000
  })
    .then(result => {
      console.log('\nBatch Result:', JSON.stringify(result, null, 2))
    })
    .catch(error => {
      console.error('Batch Error:', error)
    })
}
