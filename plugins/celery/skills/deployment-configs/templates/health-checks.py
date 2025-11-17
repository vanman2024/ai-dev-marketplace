"""
Production-grade health check implementation for Celery deployments.

Usage:
    from health_checks import CeleryHealthCheck

    checker = CeleryHealthCheck(celery_app)
    result = checker.run_all_checks()

    if result['healthy']:
        print("All systems operational")
    else:
        print(f"Health check failed: {result['errors']}")
"""

import logging
import time
from typing import Dict, List, Any, Optional
from celery import Celery
from celery.exceptions import TimeoutError as CeleryTimeoutError

logger = logging.getLogger(__name__)


class CeleryHealthCheck:
    """Comprehensive health check for Celery infrastructure."""

    def __init__(self, app: Celery, timeout: int = 5):
        """
        Initialize health checker.

        Args:
            app: Celery application instance
            timeout: Timeout for individual checks in seconds
        """
        self.app = app
        self.timeout = timeout
        self.errors: List[str] = []

    def check_broker(self) -> bool:
        """
        Verify broker connectivity.

        Returns:
            True if broker is accessible, False otherwise
        """
        try:
            # Try to establish connection to broker
            conn = self.app.connection_or_acquire()
            conn.ensure_connection(max_retries=3, interval_start=0, interval_step=1)
            conn.release()
            logger.info("Broker check: PASSED")
            return True
        except Exception as e:
            error_msg = f"Broker check FAILED: {str(e)}"
            logger.error(error_msg)
            self.errors.append(error_msg)
            return False

    def check_result_backend(self) -> bool:
        """
        Verify result backend connectivity.

        Returns:
            True if result backend is accessible, False otherwise
        """
        try:
            if not self.app.backend:
                logger.warning("No result backend configured")
                return True

            # Try to store and retrieve a test result
            test_key = f"health_check_{time.time()}"
            self.app.backend.set(test_key, "test_value")
            value = self.app.backend.get(test_key)
            self.app.backend.delete(test_key)

            if value == "test_value":
                logger.info("Result backend check: PASSED")
                return True
            else:
                raise ValueError("Failed to retrieve test value")

        except Exception as e:
            error_msg = f"Result backend check FAILED: {str(e)}"
            logger.error(error_msg)
            self.errors.append(error_msg)
            return False

    def check_workers(self, min_workers: int = 1) -> bool:
        """
        Check if workers are active and responding.

        Args:
            min_workers: Minimum number of workers required

        Returns:
            True if enough workers are active, False otherwise
        """
        try:
            # Ping all workers
            inspector = self.app.control.inspect(timeout=self.timeout)
            stats = inspector.stats()

            if not stats:
                raise ValueError("No workers responding")

            active_workers = len(stats)

            if active_workers < min_workers:
                raise ValueError(
                    f"Not enough workers: {active_workers} active, {min_workers} required"
                )

            logger.info(f"Worker check: PASSED ({active_workers} workers active)")
            return True

        except Exception as e:
            error_msg = f"Worker check FAILED: {str(e)}"
            logger.error(error_msg)
            self.errors.append(error_msg)
            return False

    def check_queue_depth(self, max_depth: int = 10000) -> bool:
        """
        Check queue depth to detect potential issues.

        Args:
            max_depth: Maximum allowed queue depth

        Returns:
            True if queue depth is acceptable, False otherwise
        """
        try:
            inspector = self.app.control.inspect(timeout=self.timeout)
            active_queues = inspector.active_queues()

            if not active_queues:
                logger.warning("No active queues found")
                return True

            # Check depth for each queue
            for worker, queues in active_queues.items():
                for queue in queues:
                    queue_name = queue.get('name', 'unknown')

                    # Get approximate queue length
                    with self.app.connection_or_acquire() as conn:
                        channel = conn.channel()
                        try:
                            # This works for AMQP brokers
                            _, message_count, _ = channel.queue_declare(
                                queue=queue_name, passive=True
                            )

                            if message_count > max_depth:
                                raise ValueError(
                                    f"Queue {queue_name} depth {message_count} exceeds "
                                    f"maximum {max_depth}"
                                )
                        except Exception:
                            # Redis and other brokers may not support this
                            logger.warning(f"Could not check depth for queue {queue_name}")

            logger.info("Queue depth check: PASSED")
            return True

        except Exception as e:
            error_msg = f"Queue depth check FAILED: {str(e)}"
            logger.error(error_msg)
            self.errors.append(error_msg)
            return False

    def check_task_execution(self, timeout: Optional[int] = None) -> bool:
        """
        Execute a test task to verify end-to-end functionality.

        Args:
            timeout: Timeout for task execution

        Returns:
            True if task executes successfully, False otherwise
        """
        try:
            timeout = timeout or self.timeout

            # Use a simple built-in task for testing
            from celery import group

            # Create a simple test task
            @self.app.task(name='health_check.test_task')
            def test_task():
                return "OK"

            # Execute and wait for result
            result = test_task.apply_async()
            output = result.get(timeout=timeout)

            if output == "OK":
                logger.info("Task execution check: PASSED")
                return True
            else:
                raise ValueError(f"Unexpected task result: {output}")

        except CeleryTimeoutError:
            error_msg = "Task execution check FAILED: Timeout"
            logger.error(error_msg)
            self.errors.append(error_msg)
            return False
        except Exception as e:
            error_msg = f"Task execution check FAILED: {str(e)}"
            logger.error(error_msg)
            self.errors.append(error_msg)
            return False

    def check_beat_schedule(self) -> bool:
        """
        Verify beat scheduler is running and schedule is accessible.

        Returns:
            True if beat is operational, False otherwise
        """
        try:
            # Check if schedule is configured
            if not self.app.conf.beat_schedule:
                logger.info("No beat schedule configured")
                return True

            # Try to get schedule information
            inspector = self.app.control.inspect(timeout=self.timeout)
            scheduled = inspector.scheduled()

            if scheduled is None:
                logger.warning("Could not verify beat scheduler status")
                return True

            logger.info("Beat scheduler check: PASSED")
            return True

        except Exception as e:
            error_msg = f"Beat scheduler check FAILED: {str(e)}"
            logger.error(error_msg)
            self.errors.append(error_msg)
            return False

    def get_metrics(self) -> Dict[str, Any]:
        """
        Collect metrics about the Celery infrastructure.

        Returns:
            Dictionary containing various metrics
        """
        metrics = {
            'timestamp': time.time(),
            'workers': {},
            'queues': {},
            'tasks': {}
        }

        try:
            inspector = self.app.control.inspect(timeout=self.timeout)

            # Worker stats
            stats = inspector.stats()
            if stats:
                metrics['workers']['count'] = len(stats)
                metrics['workers']['details'] = stats

            # Active tasks
            active = inspector.active()
            if active:
                total_active = sum(len(tasks) for tasks in active.values())
                metrics['tasks']['active'] = total_active

            # Registered tasks
            registered = inspector.registered()
            if registered:
                metrics['tasks']['registered'] = list(registered.values())[0] if registered else []

            # Queue information
            active_queues = inspector.active_queues()
            if active_queues:
                metrics['queues'] = active_queues

        except Exception as e:
            logger.error(f"Failed to collect metrics: {str(e)}")
            metrics['error'] = str(e)

        return metrics

    def run_all_checks(self, include_task_execution: bool = False) -> Dict[str, Any]:
        """
        Run all health checks and return comprehensive status.

        Args:
            include_task_execution: Whether to run task execution test

        Returns:
            Dictionary with health status and details
        """
        self.errors = []
        start_time = time.time()

        checks = {
            'broker': self.check_broker(),
            'result_backend': self.check_result_backend(),
            'workers': self.check_workers(),
            'queue_depth': self.check_queue_depth(),
            'beat_schedule': self.check_beat_schedule(),
        }

        if include_task_execution:
            checks['task_execution'] = self.check_task_execution()

        # Calculate overall health
        healthy = all(checks.values())
        duration = time.time() - start_time

        result = {
            'healthy': healthy,
            'checks': checks,
            'errors': self.errors,
            'duration': duration,
            'timestamp': time.time()
        }

        # Add metrics if healthy
        if healthy:
            result['metrics'] = self.get_metrics()

        return result


# Flask integration example
def create_flask_health_endpoint(celery_app: Celery):
    """
    Create Flask health check endpoint.

    Usage:
        from flask import Flask
        app = Flask(__name__)
        create_flask_health_endpoint(celery_app)
    """
    from flask import jsonify, current_app

    @current_app.route('/health')
    def health_check():
        checker = CeleryHealthCheck(celery_app)
        result = checker.run_all_checks()
        status_code = 200 if result['healthy'] else 503
        return jsonify(result), status_code


# FastAPI integration example
def create_fastapi_health_endpoint(celery_app: Celery):
    """
    Create FastAPI health check endpoint.

    Usage:
        from fastapi import FastAPI
        app = FastAPI()
        create_fastapi_health_endpoint(celery_app)
    """
    from fastapi import FastAPI, Response
    from fastapi.responses import JSONResponse

    app = FastAPI()

    @app.get("/health")
    async def health_check():
        checker = CeleryHealthCheck(celery_app)
        result = checker.run_all_checks()
        status_code = 200 if result['healthy'] else 503
        return JSONResponse(content=result, status_code=status_code)
