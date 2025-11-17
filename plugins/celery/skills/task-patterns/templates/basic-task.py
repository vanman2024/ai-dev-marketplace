"""Basic Celery Task Template

A simple task with standard error handling and logging.
"""
from celery import Celery
from celery.utils.log import get_task_logger

logger = get_task_logger(__name__)

app = Celery('tasks', broker='redis://localhost:6379/0')


@app.task
def process_data(data_id: int) -> dict:
    """
    Basic task that processes data by ID.

    Args:
        data_id: ID of the data to process

    Returns:
        dict: Processing results with status and metadata

    Example:
        result = process_data.delay(123)
        output = result.get(timeout=10)
    """
    try:
        logger.info(f"Processing data ID: {data_id}")

        # Your processing logic here
        result = {
            'status': 'success',
            'data_id': data_id,
            'processed': True
        }

        logger.info(f"Successfully processed data ID: {data_id}")
        return result

    except Exception as exc:
        logger.error(f"Error processing data ID {data_id}: {exc}")
        raise


# Example usage
if __name__ == '__main__':
    # Execute immediately (synchronous)
    result = process_data(123)
    print(f"Sync result: {result}")

    # Execute asynchronously
    async_result = process_data.delay(456)
    print(f"Task ID: {async_result.id}")
    print(f"Async result: {async_result.get(timeout=10)}")
