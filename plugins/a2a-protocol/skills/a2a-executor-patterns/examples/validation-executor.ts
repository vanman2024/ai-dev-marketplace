/**
 * Validation Executor Example
 *
 * Complete example of an A2A executor for data validation
 * with custom rules, schema validation, and detailed error reporting
 */

interface A2ATask {
  id: string
  type: string
  parameters: {
    data: any
    validationType: string
    rules?: ValidationRule[]
    schema?: any
  }
}

interface A2AResult {
  taskId: string
  status: 'completed' | 'failed'
  result?: {
    valid: boolean
    errors: ValidationError[]
    warnings: ValidationWarning[]
    summary: string
  }
  error?: string
}

interface ValidationRule {
  field: string
  type: 'required' | 'format' | 'range' | 'custom'
  constraint?: any
  message?: string
}

interface ValidationError {
  field: string
  rule: string
  message: string
  value?: any
}

interface ValidationWarning {
  field: string
  message: string
}

// Validation Executor
async function executeValidationTask(task: A2ATask): Promise<A2AResult> {
  try {
    const { data, validationType, rules, schema } = task.parameters

    let validationResult

    switch (validationType) {
      case 'schema':
        validationResult = await validateSchema(data, schema)
        break

      case 'rules':
        validationResult = await validateRules(data, rules || [])
        break

      case 'type-check':
        validationResult = await validateTypes(data)
        break

      case 'business-logic':
        validationResult = await validateBusinessLogic(data)
        break

      default:
        throw new Error(`Unsupported validation type: ${validationType}`)
    }

    return {
      taskId: task.id,
      status: 'completed',
      result: validationResult
    }
  } catch (error) {
    return {
      taskId: task.id,
      status: 'failed',
      error: error instanceof Error ? error.message : 'Unknown error'
    }
  }
}

// Schema Validation
async function validateSchema(data: any, schema: any) {
  const errors: ValidationError[] = []
  const warnings: ValidationWarning[] = []

  if (!schema) {
    throw new Error('Schema is required for schema validation')
  }

  // Simple schema validation (in production, use zod, joi, etc.)
  for (const [field, requirements] of Object.entries(schema)) {
    const value = data[field]
    const reqs = requirements as any

    // Required check
    if (reqs.required && (value === undefined || value === null)) {
      errors.push({
        field,
        rule: 'required',
        message: `Field '${field}' is required`
      })
      continue
    }

    if (value !== undefined && value !== null) {
      // Type check
      if (reqs.type && typeof value !== reqs.type) {
        errors.push({
          field,
          rule: 'type',
          message: `Field '${field}' must be of type ${reqs.type}`,
          value
        })
      }

      // Min/Max for numbers
      if (reqs.type === 'number') {
        if (reqs.min !== undefined && value < reqs.min) {
          errors.push({
            field,
            rule: 'min',
            message: `Field '${field}' must be >= ${reqs.min}`,
            value
          })
        }
        if (reqs.max !== undefined && value > reqs.max) {
          errors.push({
            field,
            rule: 'max',
            message: `Field '${field}' must be <= ${reqs.max}`,
            value
          })
        }
      }

      // Pattern for strings
      if (reqs.type === 'string' && reqs.pattern) {
        const regex = new RegExp(reqs.pattern)
        if (!regex.test(value)) {
          errors.push({
            field,
            rule: 'pattern',
            message: `Field '${field}' does not match pattern ${reqs.pattern}`,
            value
          })
        }
      }
    }
  }

  return {
    valid: errors.length === 0,
    errors,
    warnings,
    summary: errors.length === 0
      ? 'All validations passed'
      : `${errors.length} validation error(s) found`
  }
}

// Rules-Based Validation
async function validateRules(data: any, rules: ValidationRule[]) {
  const errors: ValidationError[] = []
  const warnings: ValidationWarning[] = []

  for (const rule of rules) {
    const value = data[rule.field]

    switch (rule.type) {
      case 'required':
        if (value === undefined || value === null || value === '') {
          errors.push({
            field: rule.field,
            rule: 'required',
            message: rule.message || `${rule.field} is required`
          })
        }
        break

      case 'format':
        if (value && rule.constraint) {
          const regex = new RegExp(rule.constraint)
          if (!regex.test(value)) {
            errors.push({
              field: rule.field,
              rule: 'format',
              message: rule.message || `${rule.field} has invalid format`,
              value
            })
          }
        }
        break

      case 'range':
        if (value !== undefined && rule.constraint) {
          const { min, max } = rule.constraint
          if ((min !== undefined && value < min) || (max !== undefined && value > max)) {
            errors.push({
              field: rule.field,
              rule: 'range',
              message: rule.message || `${rule.field} must be between ${min} and ${max}`,
              value
            })
          }
        }
        break
    }
  }

  return {
    valid: errors.length === 0,
    errors,
    warnings,
    summary: errors.length === 0
      ? 'All rules passed'
      : `${errors.length} rule violation(s) found`
  }
}

// Type Validation
async function validateTypes(data: any) {
  const errors: ValidationError[] = []
  const warnings: ValidationWarning[] = []

  // Check for common type issues
  for (const [field, value] of Object.entries(data)) {
    if (value === null) {
      warnings.push({
        field,
        message: `Field '${field}' is null`
      })
    }

    // Check for NaN in numbers
    if (typeof value === 'number' && isNaN(value)) {
      errors.push({
        field,
        rule: 'type',
        message: `Field '${field}' is NaN`,
        value
      })
    }
  }

  return {
    valid: errors.length === 0,
    errors,
    warnings,
    summary: `Type check complete: ${errors.length} error(s), ${warnings.length} warning(s)`
  }
}

// Business Logic Validation
async function validateBusinessLogic(data: any) {
  const errors: ValidationError[] = []
  const warnings: ValidationWarning[] = []

  // Example business rules
  if (data.orderTotal && data.orderTotal < 0) {
    errors.push({
      field: 'orderTotal',
      rule: 'business-logic',
      message: 'Order total cannot be negative',
      value: data.orderTotal
    })
  }

  if (data.startDate && data.endDate) {
    const start = new Date(data.startDate)
    const end = new Date(data.endDate)

    if (start > end) {
      errors.push({
        field: 'endDate',
        rule: 'business-logic',
        message: 'End date must be after start date',
        value: data.endDate
      })
    }
  }

  return {
    valid: errors.length === 0,
    errors,
    warnings,
    summary: errors.length === 0
      ? 'Business logic validation passed'
      : `${errors.length} business logic error(s) found`
  }
}

// Export
export {
  executeValidationTask,
  A2ATask,
  A2AResult,
  ValidationRule
}

// Example Usage
if (require.main === module) {
  const tasks: A2ATask[] = [
    {
      id: 'val-001',
      type: 'validation',
      parameters: {
        validationType: 'schema',
        data: {
          name: 'John Doe',
          age: 30,
          email: 'invalid-email'
        },
        schema: {
          name: { type: 'string', required: true },
          age: { type: 'number', min: 0, max: 120 },
          email: { type: 'string', pattern: '^[^@]+@[^@]+\\.[^@]+$', required: true }
        }
      }
    },
    {
      id: 'val-002',
      type: 'validation',
      parameters: {
        validationType: 'business-logic',
        data: {
          orderTotal: -50,
          startDate: '2024-01-15',
          endDate: '2024-01-10'
        }
      }
    }
  ]

  Promise.all(tasks.map(task => executeValidationTask(task)))
    .then(results => {
      results.forEach((result, i) => {
        console.log(`Validation ${i + 1}:`, JSON.stringify(result, null, 2))
      })
    })
}
