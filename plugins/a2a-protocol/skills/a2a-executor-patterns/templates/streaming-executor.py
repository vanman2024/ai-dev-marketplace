"""
Streaming A2A Executor

Use for: Results that should be delivered incrementally
Examples: Text generation, real-time data, progressive results
"""

from dataclasses import dataclass
from typing import Any, Dict, AsyncGenerator
import asyncio
import json


# Task and Result Classes
@dataclass
class A2ATask:
    """A2A Task definition"""
    id: str
    type: str
    parameters: Dict[str, Any]


@dataclass
class StreamChunk:
    """Stream chunk data"""
    task_id: str
    index: int
    data: Any
    done: bool


# Streaming Executor
async def execute_streaming_task(task: A2ATask) -> AsyncGenerator[StreamChunk, None]:
    """Execute task with streaming results"""
    try:
        # Validate task
        if not task.id or not task.type:
            raise ValueError('Invalid task structure')

        # Stream based on task type
        if task.type == 'text-generation':
            async for chunk in stream_text_generation(task):
                yield chunk

        elif task.type == 'data-processing':
            async for chunk in stream_data_processing(task):
                yield chunk

        elif task.type == 'file-streaming':
            async for chunk in stream_file_data(task):
                yield chunk

        else:
            raise ValueError(f'Unsupported streaming task: {task.type}')

    except Exception as error:
        # Send error chunk
        yield StreamChunk(
            task_id=task.id,
            index=-1,
            data={'error': str(error)},
            done=True
        )


# Example: Text Generation Streaming
async def stream_text_generation(task: A2ATask) -> AsyncGenerator[StreamChunk, None]:
    """Stream text generation results"""
    prompt = task.parameters.get('prompt', '')
    max_tokens = task.parameters.get('maxTokens', 100)

    # Simulate streaming text generation
    text = 'This is a simulated streaming response from an LLM...'
    words = text.split(' ')

    for i, word in enumerate(words):
        await asyncio.sleep(0.1)

        yield StreamChunk(
            task_id=task.id,
            index=i,
            data={
                'text': word + ' ',
                'tokens': i + 1
            },
            done=False
        )

    # Final chunk
    yield StreamChunk(
        task_id=task.id,
        index=len(words),
        data={
            'text': '',
            'tokens': len(words),
            'complete': True
        },
        done=True
    )


# Example: Data Processing Streaming
async def stream_data_processing(task: A2ATask) -> AsyncGenerator[StreamChunk, None]:
    """Stream data processing results"""
    items = task.parameters.get('items', [])

    if not isinstance(items, list):
        raise ValueError('Items must be a list')

    for i, item in enumerate(items):
        await asyncio.sleep(0.05)

        processed = await process_item(item)

        yield StreamChunk(
            task_id=task.id,
            index=i,
            data={
                'item': processed,
                'progress': ((i + 1) / len(items)) * 100
            },
            done=(i == len(items) - 1)
        )


# Example: File Streaming
async def stream_file_data(task: A2ATask) -> AsyncGenerator[StreamChunk, None]:
    """Stream file data"""
    file_url = task.parameters.get('fileUrl')
    chunk_size = task.parameters.get('chunkSize', 1024)

    # Simulate file streaming
    total_chunks = 10
    for i in range(total_chunks):
        await asyncio.sleep(0.1)

        yield StreamChunk(
            task_id=task.id,
            index=i,
            data={
                'chunk': f'Chunk {i + 1}/{total_chunks}',
                'bytes': (i + 1) * chunk_size
            },
            done=(i == total_chunks - 1)
        )


# Helper function
async def process_item(item: Any) -> Any:
    """Process a single item"""
    # Simulate processing
    return {**item, 'processed': True} if isinstance(item, dict) else {'value': item, 'processed': True}


# FastAPI Streaming Response Example
def create_fastapi_streaming_endpoint():
    """Example FastAPI streaming endpoint"""
    from fastapi import FastAPI
    from fastapi.responses import StreamingResponse

    app = FastAPI()

    @app.post("/execute/stream")
    async def execute_stream(task: Dict[str, Any]):
        a2a_task = A2ATask(**task)

        async def generate():
            async for chunk in execute_streaming_task(a2a_task):
                yield f"data: {json.dumps({
                    'task_id': chunk.task_id,
                    'index': chunk.index,
                    'data': chunk.data,
                    'done': chunk.done
                })}\n\n"

        return StreamingResponse(
            generate(),
            media_type="text/event-stream"
        )

    return app


# WebSocket Streaming Example
async def handle_websocket_streaming(websocket, task: A2ATask):
    """Handle WebSocket streaming"""
    try:
        async for chunk in execute_streaming_task(task):
            await websocket.send_json({
                'task_id': chunk.task_id,
                'index': chunk.index,
                'data': chunk.data,
                'done': chunk.done
            })

            if chunk.done:
                await websocket.close()
                break

    except Exception as error:
        await websocket.send_json({
            'error': str(error)
        })
        await websocket.close()


# Example Usage
if __name__ == '__main__':
    async def main():
        example_task = A2ATask(
            id='stream-task-001',
            type='text-generation',
            parameters={
                'prompt': 'Explain quantum computing',
                'maxTokens': 100
            }
        )

        print('Starting stream...\n')

        async for chunk in execute_streaming_task(example_task):
            print('Chunk:', json.dumps({
                'task_id': chunk.task_id,
                'index': chunk.index,
                'data': chunk.data,
                'done': chunk.done
            }, indent=2))

            if chunk.done:
                print('\nStream complete!')
                break

    asyncio.run(main())
