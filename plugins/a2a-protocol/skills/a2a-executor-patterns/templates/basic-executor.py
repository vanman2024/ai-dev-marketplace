"""
Basic A2A Executor - Synchronous Pattern

Use for: Simple, fast tasks with immediate results
Examples: Validation, quick transformations, data formatting
"""

from dataclasses import dataclass, field
from typing import Any, Dict, Optional
from datetime import datetime
import json


# Task and Result Classes
@dataclass
class A2ATask:
    """A2A Task definition"""
    id: str
    type: str
    parameters: Dict[str, Any]
    metadata: Optional[Dict[str, Any]] = None


@dataclass
class A2AResult:
    """A2A Result definition"""
    task_id: str
    status: str  # 'completed' or 'failed'
    result: Optional[Any] = None
    error: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = None


# Error Classes
class ValidationError(Exception):
    """Raised when task validation fails"""
    pass


class ExecutionError(Exception):
    """Raised when task execution fails"""
    pass


# Task Validation
def validate_task(task: A2ATask) -> None:
    """Validate task structure and required fields"""
    if not task.id:
        raise ValidationError('Task ID is required')

    if not task.type:
        raise ValidationError('Task type is required')

    if not isinstance(task.parameters, dict):
        raise ValidationError('Task parameters must be a dictionary')


# Main Executor Function
async def execute_task(task: A2ATask) -> A2AResult:
    """Execute A2A task and return result"""
    try:
        # Step 1: Validate input
        validate_task(task)

        # Step 2: Process task based on type
        result = None

        if task.type == 'validate-data':
            result = await validate_data(task.parameters)

        elif task.type == 'transform-data':
            result = await transform_data(task.parameters)

        elif task.type == 'compute-result':
            result = await compute_result(task.parameters)

        else:
            raise ExecutionError(f'Unsupported task type: {task.type}')

        # Step 3: Return successful result
        return A2AResult(
            task_id=task.id,
            status='completed',
            result=result,
            metadata={
                'executed_at': datetime.utcnow().isoformat(),
                'execution_time': 0  # Add timing if needed
            }
        )

    except Exception as error:
        # Error handling
        print(f'Task execution failed: {task.id} - {str(error)}')

        return A2AResult(
            task_id=task.id,
            status='failed',
            error=str(error),
            metadata={
                'failed_at': datetime.utcnow().isoformat()
            }
        )


# Example Task Handlers
async def validate_data(parameters: Dict[str, Any]) -> Any:
    """Implement validation logic"""
    data = parameters.get('data')
    schema = parameters.get('schema')

    # Example: simple validation
    if not data:
        raise ValidationError('Data is required')

    return {
        'valid': True,
        'data': data
    }


async def transform_data(parameters: Dict[str, Any]) -> Any:
    """Implement transformation logic"""
    input_data = parameters.get('input')
    transform_type = parameters.get('transformType')

    # Example: simple transformation
    return {
        'transformed': input_data,
        'type': transform_type
    }


async def compute_result(parameters: Dict[str, Any]) -> Any:
    """Implement computation logic"""
    values = parameters.get('values')
    operation = parameters.get('operation')

    # Example: simple computation
    return {
        'result': values,
        'operation': operation
    }


# Example Usage
if __name__ == '__main__':
    import asyncio

    async def main():
        example_task = A2ATask(
            id='task-001',
            type='validate-data',
            parameters={
                'data': {'name': 'test', 'value': 42},
                'schema': {}
            }
        )

        result = await execute_task(example_task)
        print('Result:', json.dumps({
            'task_id': result.task_id,
            'status': result.status,
            'result': result.result,
            'error': result.error,
            'metadata': result.metadata
        }, indent=2))

    asyncio.run(main())
