"""
Webhook retry handler
Manages retry logic and backoff strategies
"""

import os
from datetime import datetime, timedelta
from typing import Optional, Dict, List


class RetryHandler:
    """
    Webhook retry handler

    Features:
    - Configurable retry strategies per event type
    - Exponential backoff
    - Maximum retry limits
    - Event type specific retry policies
    """

    def __init__(self):
        # Default retry configuration
        self.default_max_retries = int(os.getenv("WEBHOOK_MAX_RETRIES", "3"))
        self.default_retry_delay = int(os.getenv("WEBHOOK_RETRY_DELAY", "300"))  # 5 minutes

        # Event-specific retry policies
        self.retry_policies = {
            # Critical events - retry aggressively
            "invoice.payment_failed": {
                "max_retries": 5,
                "retry_delays": [300, 600, 1800, 3600, 7200],  # 5min, 10min, 30min, 1h, 2h
                "backoff": "exponential"
            },
            "customer.subscription.deleted": {
                "max_retries": 5,
                "retry_delays": [60, 300, 900, 1800, 3600],  # 1min, 5min, 15min, 30min, 1h
                "backoff": "exponential"
            },

            # Important events - retry with moderate backoff
            "customer.subscription.updated": {
                "max_retries": 3,
                "retry_delays": [300, 900, 1800],  # 5min, 15min, 30min
                "backoff": "linear"
            },
            "payment_intent.succeeded": {
                "max_retries": 3,
                "retry_delays": [300, 600, 1800],  # 5min, 10min, 30min
                "backoff": "linear"
            },

            # Less critical events - limited retries
            "charge.dispute.created": {
                "max_retries": 2,
                "retry_delays": [600, 1800],  # 10min, 30min
                "backoff": "linear"
            },

            # Informational events - minimal retries
            "customer.created": {
                "max_retries": 1,
                "retry_delays": [300],  # 5min
                "backoff": "none"
            }
        }

        # Events that should NOT be retried
        self.no_retry_events = [
            "ping",  # Test events
            "account.updated",  # Informational only
        ]

    def should_retry(
        self,
        event_type: str,
        attempt_count: int,
        last_attempt: Optional[datetime] = None
    ) -> bool:
        """
        Determine if event should be retried

        Args:
            event_type: Type of webhook event
            attempt_count: Number of attempts so far
            last_attempt: Timestamp of last attempt (optional)

        Returns:
            True if event should be retried
        """
        # Check if event type should never be retried
        if event_type in self.no_retry_events:
            return False

        # Get retry policy for event type
        policy = self.retry_policies.get(event_type, {
            "max_retries": self.default_max_retries,
            "retry_delays": [self.default_retry_delay] * self.default_max_retries,
            "backoff": "linear"
        })

        # Check if max retries reached
        if attempt_count >= policy["max_retries"]:
            return False

        # Check if enough time has passed since last attempt
        if last_attempt:
            retry_delay = self.get_retry_delay(event_type, attempt_count)
            next_retry = last_attempt + timedelta(seconds=retry_delay)

            if datetime.utcnow() < next_retry:
                return False  # Too soon to retry

        return True

    def get_retry_delay(self, event_type: str, attempt_count: int) -> int:
        """
        Get retry delay in seconds for given event and attempt

        Args:
            event_type: Type of webhook event
            attempt_count: Current attempt number (0-indexed)

        Returns:
            Delay in seconds before next retry
        """
        policy = self.retry_policies.get(event_type, {
            "max_retries": self.default_max_retries,
            "retry_delays": [self.default_retry_delay] * self.default_max_retries,
            "backoff": "linear"
        })

        retry_delays = policy["retry_delays"]
        backoff = policy.get("backoff", "linear")

        # Get base delay
        if attempt_count < len(retry_delays):
            base_delay = retry_delays[attempt_count]
        else:
            # Use last delay if we've exceeded configured delays
            base_delay = retry_delays[-1] if retry_delays else self.default_retry_delay

        # Apply backoff strategy
        if backoff == "exponential":
            # Exponential backoff: delay * 2^attempt
            return base_delay * (2 ** min(attempt_count, 5))  # Cap at 2^5
        elif backoff == "linear":
            # Linear backoff: delay * attempt
            return base_delay * (attempt_count + 1)
        else:
            # No backoff
            return base_delay

    def get_max_retries(self, event_type: str) -> int:
        """
        Get maximum retry count for event type

        Args:
            event_type: Type of webhook event

        Returns:
            Maximum number of retries allowed
        """
        if event_type in self.no_retry_events:
            return 0

        policy = self.retry_policies.get(event_type, {
            "max_retries": self.default_max_retries
        })

        return policy["max_retries"]

    def get_retry_schedule(self, event_type: str) -> List[int]:
        """
        Get complete retry schedule for event type

        Args:
            event_type: Type of webhook event

        Returns:
            List of retry delays in seconds
        """
        policy = self.retry_policies.get(event_type, {
            "retry_delays": [self.default_retry_delay] * self.default_max_retries
        })

        return policy.get("retry_delays", [])

    def is_permanent_failure(self, error_message: str) -> bool:
        """
        Determine if error is permanent (should not retry)

        Args:
            error_message: Error message from processing

        Returns:
            True if error is permanent
        """
        # Patterns indicating permanent failures
        permanent_errors = [
            "invalid payload",
            "malformed json",
            "missing required field",
            "invalid event type",
            "unauthorized",
            "forbidden",
            "not found",
            "duplicate",
            "already processed"
        ]

        error_lower = error_message.lower()
        return any(pattern in error_lower for pattern in permanent_errors)

    def get_http_status_for_retry(self, should_retry: bool) -> int:
        """
        Get appropriate HTTP status code based on retry decision

        Args:
            should_retry: Whether event should be retried

        Returns:
            HTTP status code to return
        """
        if should_retry:
            # 500 = Server error, provider will retry
            return 500
        else:
            # 400 = Bad request, provider won't retry
            return 400

    def format_retry_info(self, event_type: str, attempt_count: int) -> Dict:
        """
        Get formatted retry information for logging

        Args:
            event_type: Type of webhook event
            attempt_count: Current attempt number

        Returns:
            Dictionary with retry information
        """
        max_retries = self.get_max_retries(event_type)
        retry_delay = self.get_retry_delay(event_type, attempt_count)
        schedule = self.get_retry_schedule(event_type)

        return {
            "event_type": event_type,
            "attempt_count": attempt_count,
            "max_retries": max_retries,
            "next_retry_delay": retry_delay,
            "retry_schedule": schedule,
            "retries_remaining": max(0, max_retries - attempt_count)
        }


# Usage example
if __name__ == "__main__":
    handler = RetryHandler()

    # Example: Check if payment failure should be retried
    event_type = "invoice.payment_failed"
    attempt_count = 2

    should_retry = handler.should_retry(event_type, attempt_count)
    retry_info = handler.format_retry_info(event_type, attempt_count)

    print(f"Should retry {event_type}? {should_retry}")
    print(f"Retry info: {retry_info}")

    # Get next retry delay
    delay = handler.get_retry_delay(event_type, attempt_count)
    print(f"Next retry in: {delay} seconds ({delay/60:.1f} minutes)")

    # Check if error is permanent
    error = "Invalid payload format"
    is_permanent = handler.is_permanent_failure(error)
    print(f"Is permanent failure? {is_permanent}")
