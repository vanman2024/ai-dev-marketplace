"""
Async A2A Executor - Long-Running Pattern

Use for: Tasks that take time and need status updates
Examples: LLM inference, file processing, data analysis
"""

from dataclasses import dataclass, field
from typing import Any, Dict, Optional, Callable
from datetime import datetime
from enum import Enum
import asyncio
import json


class TaskStatus(str, Enum):
    """Task status values"""
    PENDING = 'pending'
    RUNNING = 'running'
    COMPLETED = 'completed'
    FAILED = 'failed'


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
    status: TaskStatus
    result: Optional[Any] = None
    error: Optional[str] = None
    progress: int = 0
    metadata: Optional[Dict[str, Any]] = None


@dataclass
class TaskState:
    """Internal task state"""
    task: A2ATask
    status: TaskStatus
    result: Optional[Any] = None
    error: Optional[str] = None
    progress: int = 0
    start_time: datetime = field(default_factory=datetime.utcnow)
    end_time: Optional[datetime] = None


# Task Store
class TaskStore:
    """In-memory task state storage"""

    def __init__(self):
        self.tasks: Dict[str, TaskState] = {}

    def create_task(self, task: A2ATask) -> TaskState:
        """Create new task state"""
        state = TaskState(
            task=task,
            status=TaskStatus.PENDING,
            progress=0
        )
        self.tasks[task.id] = state
        return state

    def update_task(self, task_id: str, **updates) -> None:
        """Update task state"""
        if task_id in self.tasks:
            state = self.tasks[task_id]
            for key, value in updates.items():
                setattr(state, key, value)

    def get_task(self, task_id: str) -> Optional[TaskState]:
        """Get task state"""
        return self.tasks.get(task_id)

    def delete_task(self, task_id: str) -> None:
        """Delete task state"""
        if task_id in self.tasks:
            del self.tasks[task_id]


# Global task store
task_store = TaskStore()


# Async Executor
async def submit_task(task: A2ATask) -> A2AResult:
    """Submit task for async execution"""
    # Create task state
    task_store.create_task(task)

    # Start async execution (don't await)
    asyncio.create_task(execute_task_async(task))

    # Return immediate response
    return A2AResult(
        task_id=task.id,
        status=TaskStatus.PENDING,
        progress=0,
        metadata={
            'submitted_at': datetime.utcnow().isoformat()
        }
    )


async def execute_task_async(task: A2ATask) -> None:
    """Execute task asynchronously"""
    try:
        # Update to running
        task_store.update_task(
            task.id,
            status=TaskStatus.RUNNING,
            progress=10
        )

        # Execute task
        async def on_progress(progress: int):
            task_store.update_task(task.id, progress=progress)

        result = await process_long_running_task(task, on_progress)

        # Update to completed
        task_store.update_task(
            task.id,
            status=TaskStatus.COMPLETED,
            result=result,
            progress=100,
            end_time=datetime.utcnow()
        )

        # Optional: Send callback notification
        await send_callback(task, result)

    except Exception as error:
        task_store.update_task(
            task.id,
            status=TaskStatus.FAILED,
            error=str(error),
            end_time=datetime.utcnow()
        )


async def process_long_running_task(
    task: A2ATask,
    on_progress: Callable[[int], None]
) -> Any:
    """Process long-running task with progress updates"""
    # Simulate long-running task
    steps = 10
    for i in range(steps):
        await asyncio.sleep(0.5)
        await on_progress(10 + (i + 1) * 8)  # Progress from 10% to 90%

    # Return result based on task type
    if task.type == 'llm-inference':
        return await run_llm_inference(task.parameters)

    elif task.type == 'file-processing':
        return await process_file(task.parameters)

    elif task.type == 'data-analysis':
        return await analyze_data(task.parameters)

    else:
        raise ValueError(f'Unsupported task type: {task.type}')


# Get Task Status
def get_task_status(task_id: str) -> Optional[A2AResult]:
    """Get current task status"""
    state = task_store.get_task(task_id)
    if not state:
        return None

    return A2AResult(
        task_id=task_id,
        status=state.status,
        result=state.result,
        error=state.error,
        progress=state.progress,
        metadata={
            'start_time': state.start_time.isoformat(),
            'end_time': state.end_time.isoformat() if state.end_time else None
        }
    )


# Cancel Task
async def cancel_task(task_id: str) -> bool:
    """Cancel running task"""
    state = task_store.get_task(task_id)
    if not state or state.status in [TaskStatus.COMPLETED, TaskStatus.FAILED]:
        return False

    task_store.update_task(
        task_id,
        status=TaskStatus.FAILED,
        error='Task cancelled',
        end_time=datetime.utcnow()
    )

    return True


# Example Task Processors
async def run_llm_inference(parameters: Dict[str, Any]) -> Any:
    """Implement LLM inference"""
    prompt = parameters.get('prompt')
    model = parameters.get('model')
    # Call LLM API here
    return {
        'response': 'Generated response',
        'model': model,
        'tokens': 100
    }


async def process_file(parameters: Dict[str, Any]) -> Any:
    """Implement file processing"""
    file_url = parameters.get('fileUrl')
    operation = parameters.get('operation')
    # Process file here
    return {
        'processed': True,
        'operation': operation,
        'file_url': file_url
    }


async def analyze_data(parameters: Dict[str, Any]) -> Any:
    """Implement data analysis"""
    data = parameters.get('data')
    analysis_type = parameters.get('analysisType')
    # Analyze data here
    return {
        'analysis': 'Results',
        'type': analysis_type
    }


# Optional: Callback notification
async def send_callback(task: A2ATask, result: Any) -> None:
    """Send callback notification"""
    if not task.metadata or 'callback_url' not in task.metadata:
        return

    callback_url = task.metadata['callback_url']

    try:
        # Use aiohttp or httpx for async HTTP
        # For this example, we'll just log
        print(f'Would send callback to: {callback_url}')
    except Exception as error:
        print(f'Callback failed: {error}')


# Example Usage
if __name__ == '__main__':
    async def main():
        example_task = A2ATask(
            id='async-task-001',
            type='llm-inference',
            parameters={
                'prompt': 'Explain quantum computing',
                'model': 'gpt-4'
            }
        )

        result = await submit_task(example_task)
        print('Task submitted:', json.dumps({
            'task_id': result.task_id,
            'status': result.status.value,
            'progress': result.progress
        }, indent=2))

        # Poll for status
        while True:
            await asyncio.sleep(1)
            status = get_task_status(example_task.id)
            if status:
                print('Status:', json.dumps({
                    'task_id': status.task_id,
                    'status': status.status.value,
                    'progress': status.progress
                }, indent=2))

                if status.status in [TaskStatus.COMPLETED, TaskStatus.FAILED]:
                    break

    asyncio.run(main())
