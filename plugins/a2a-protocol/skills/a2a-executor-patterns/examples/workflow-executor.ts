/**
 * Workflow Executor Example
 *
 * Complete example of an A2A executor for multi-step workflows
 * with state management, conditional branching, and error recovery
 */

interface A2ATask {
  id: string
  type: string
  parameters: {
    workflow: string
    input: Record<string, any>
  }
}

interface A2AResult {
  taskId: string
  status: 'completed' | 'failed'
  result?: {
    steps: StepResult[]
    finalOutput: any
    duration: number
  }
  error?: string
}

interface WorkflowStep {
  name: string
  action: (input: any, context: WorkflowContext) => Promise<any>
  condition?: (context: WorkflowContext) => boolean
  onError?: 'stop' | 'continue' | 'retry'
}

interface StepResult {
  step: string
  status: 'completed' | 'failed' | 'skipped'
  output?: any
  error?: string
  duration: number
}

interface WorkflowContext {
  input: any
  state: Record<string, any>
  stepResults: StepResult[]
}

// Workflow Definition
interface Workflow {
  name: string
  steps: WorkflowStep[]
}

// Workflow Registry
class WorkflowRegistry {
  private workflows = new Map<string, Workflow>()

  register(workflow: Workflow): void {
    this.workflows.set(workflow.name, workflow)
  }

  get(name: string): Workflow | undefined {
    return this.workflows.get(name)
  }

  list(): string[] {
    return Array.from(this.workflows.keys())
  }
}

const registry = new WorkflowRegistry()

// Workflow Executor
async function executeWorkflowTask(task: A2ATask): Promise<A2AResult> {
  const startTime = Date.now()

  try {
    const workflow = registry.get(task.parameters.workflow)
    if (!workflow) {
      throw new Error(`Workflow not found: ${task.parameters.workflow}`)
    }

    const context: WorkflowContext = {
      input: task.parameters.input,
      state: {},
      stepResults: []
    }

    // Execute workflow steps
    for (const step of workflow.steps) {
      const stepResult = await executeStep(step, context)
      context.stepResults.push(stepResult)

      if (stepResult.status === 'failed' && step.onError === 'stop') {
        break
      }
    }

    const duration = Date.now() - startTime
    const finalOutput = context.state.output || context.state

    return {
      taskId: task.id,
      status: 'completed',
      result: {
        steps: context.stepResults,
        finalOutput,
        duration
      }
    }
  } catch (error) {
    return {
      taskId: task.id,
      status: 'failed',
      error: error instanceof Error ? error.message : 'Unknown error'
    }
  }
}

// Execute single step
async function executeStep(
  step: WorkflowStep,
  context: WorkflowContext
): Promise<StepResult> {
  const startTime = Date.now()

  try {
    // Check condition
    if (step.condition && !step.condition(context)) {
      return {
        step: step.name,
        status: 'skipped',
        duration: 0
      }
    }

    // Execute step action
    const output = await step.action(context.input, context)

    // Update context state
    context.state[step.name] = output

    return {
      step: step.name,
      status: 'completed',
      output,
      duration: Date.now() - startTime
    }
  } catch (error) {
    return {
      step: step.name,
      status: 'failed',
      error: error instanceof Error ? error.message : 'Unknown error',
      duration: Date.now() - startTime
    }
  }
}

// Example Workflows

// Data Processing Workflow
registry.register({
  name: 'data-processing',
  steps: [
    {
      name: 'validate',
      action: async (input) => {
        if (!input.data) throw new Error('Data is required')
        return { valid: true }
      },
      onError: 'stop'
    },
    {
      name: 'transform',
      action: async (input) => {
        return {
          transformed: input.data.map((item: any) => ({
            ...item,
            processed: true
          }))
        }
      }
    },
    {
      name: 'analyze',
      action: async (input, context) => {
        const transformed = context.state.transform.transformed
        return {
          count: transformed.length,
          summary: 'Analysis complete'
        }
      }
    },
    {
      name: 'output',
      action: async (input, context) => {
        context.state.output = {
          original: input.data,
          transformed: context.state.transform.transformed,
          analysis: context.state.analyze
        }
        return context.state.output
      }
    }
  ]
})

// Approval Workflow
registry.register({
  name: 'approval',
  steps: [
    {
      name: 'check-amount',
      action: async (input) => {
        return { amount: input.amount, needsApproval: input.amount > 1000 }
      }
    },
    {
      name: 'request-approval',
      condition: (context) => context.state['check-amount']?.needsApproval,
      action: async (input) => {
        // Simulate approval request
        await new Promise(resolve => setTimeout(resolve, 500))
        return { approved: true, approver: 'manager' }
      }
    },
    {
      name: 'process',
      action: async (input, context) => {
        const needsApproval = context.state['check-amount']?.needsApproval
        const approved = context.state['request-approval']?.approved

        if (needsApproval && !approved) {
          throw new Error('Approval required but not granted')
        }

        return { processed: true, amount: input.amount }
      }
    }
  ]
})

// ETL Workflow
registry.register({
  name: 'etl',
  steps: [
    {
      name: 'extract',
      action: async (input) => {
        // Simulate data extraction
        return { records: [{ id: 1 }, { id: 2 }, { id: 3 }] }
      }
    },
    {
      name: 'transform',
      action: async (input, context) => {
        const records = context.state.extract.records
        return {
          transformed: records.map((r: any) => ({
            ...r,
            enriched: true
          }))
        }
      }
    },
    {
      name: 'load',
      action: async (input, context) => {
        const data = context.state.transform.transformed
        // Simulate loading to database
        await new Promise(resolve => setTimeout(resolve, 300))
        return { loaded: data.length, success: true }
      }
    }
  ]
})

// Export
export {
  executeWorkflowTask,
  registry,
  A2ATask,
  A2AResult,
  Workflow
}

// Example Usage
if (require.main === module) {
  console.log('Available workflows:', registry.list())
  console.log('\nExecuting workflows...\n')

  const tasks: A2ATask[] = [
    {
      id: 'workflow-001',
      type: 'workflow',
      parameters: {
        workflow: 'data-processing',
        input: {
          data: [
            { id: 1, value: 'A' },
            { id: 2, value: 'B' }
          ]
        }
      }
    },
    {
      id: 'workflow-002',
      type: 'workflow',
      parameters: {
        workflow: 'approval',
        input: {
          amount: 1500
        }
      }
    }
  ]

  Promise.all(tasks.map(task => executeWorkflowTask(task)))
    .then(results => {
      results.forEach((result, i) => {
        console.log(`Workflow ${i + 1}:`, JSON.stringify(result, null, 2))
      })
    })
}
