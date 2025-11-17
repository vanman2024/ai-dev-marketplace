"""API-Related Celery Task Patterns

Demonstrates best practices for external API calls in Celery tasks.
"""
from celery import Celery
from celery.utils.log import get_task_logger
from requests.exceptions import RequestException, Timeout, HTTPError
from typing import Dict, List, Optional, Any
import requests
from datetime import datetime
from enum import Enum

logger = get_task_logger(__name__)

app = Celery('tasks', broker='redis://localhost:6379/0')


class HttpMethod(str, Enum):
    """HTTP methods."""
    GET = "GET"
    POST = "POST"
    PUT = "PUT"
    DELETE = "DELETE"
    PATCH = "PATCH"


@app.task(
    bind=True,
    autoretry_for=(RequestException, Timeout, HTTPError),
    retry_backoff=True,
    retry_backoff_max=600,
    retry_jitter=True,
    max_retries=5
)
def api_call_with_retry(
    self,
    url: str,
    method: str = 'GET',
    headers: Optional[dict] = None,
    json_data: Optional[dict] = None,
    timeout: int = 30
) -> dict:
    """
    Make API call with automatic retries on failure.

    Best Practices:
    - Automatic retry on connection/timeout errors
    - Exponential backoff to avoid overwhelming API
    - Jitter to prevent thundering herd
    - Timeout to prevent hanging tasks

    Args:
        url: API endpoint URL
        method: HTTP method (GET, POST, PUT, DELETE, PATCH)
        headers: Request headers
        json_data: JSON request body
        timeout: Request timeout in seconds

    Returns:
        dict: API response

    Example:
        result = api_call_with_retry.delay(
            'https://api.example.com/users',
            method='POST',
            json_data={'name': 'John Doe'},
            timeout=60
        )
    """
    try:
        logger.info(
            f"API call to {url} (method={method}, "
            f"attempt={self.request.retries + 1}/{self.max_retries})"
        )

        # Prepare headers
        headers = headers or {}
        headers.setdefault('User-Agent', 'Celery-Task/1.0')
        headers.setdefault('Accept', 'application/json')

        # Make request
        response = requests.request(
            method=method,
            url=url,
            headers=headers,
            json=json_data,
            timeout=timeout
        )

        # Raise for HTTP errors (4xx, 5xx)
        response.raise_for_status()

        # Parse response
        result = {
            'status': 'success',
            'status_code': response.status_code,
            'url': url,
            'method': method,
            'data': response.json() if response.content else {},
            'headers': dict(response.headers),
            'timestamp': datetime.utcnow().isoformat()
        }

        logger.info(f"API call successful: {url} ({response.status_code})")
        return result

    except (RequestException, Timeout, HTTPError) as exc:
        logger.warning(
            f"API call failed (attempt {self.request.retries + 1}): {exc}"
        )
        raise  # Let autoretry_for handle the retry


@app.task(rate_limit='10/m')
def rate_limited_api_call(url: str, api_key: str) -> dict:
    """
    API call with rate limiting to respect API quotas.

    Use this when API has strict rate limits.

    Args:
        url: API endpoint
        api_key: API key for authentication (use placeholder: your_api_key_here)

    Returns:
        dict: API response

    Example:
        result = rate_limited_api_call.delay(
            'https://api.example.com/data',
            'your_api_key_here'
        )
    """
    logger.info(f"Making rate-limited API call to {url}")

    headers = {
        'Authorization': f'Bearer {api_key}',
        'Content-Type': 'application/json'
    }

    response = requests.get(url, headers=headers, timeout=30)
    response.raise_for_status()

    return {
        'status': 'success',
        'url': url,
        'data': response.json()
    }


@app.task(bind=True)
def paginated_api_fetch(
    self,
    base_url: str,
    params: Optional[dict] = None,
    max_pages: int = 10
) -> dict:
    """
    Fetch all pages from paginated API endpoint.

    Args:
        base_url: Base API URL
        params: Query parameters
        max_pages: Maximum pages to fetch

    Returns:
        dict: All fetched data

    Example:
        result = paginated_api_fetch.delay(
            'https://api.example.com/users',
            params={'status': 'active'},
            max_pages=20
        )
    """
    all_data = []
    params = params or {}
    page = 1

    while page <= max_pages:
        logger.info(f"Fetching page {page}/{max_pages} from {base_url}")

        params['page'] = page
        response = requests.get(base_url, params=params, timeout=30)
        response.raise_for_status()

        data = response.json()

        # Handle different pagination formats
        if isinstance(data, dict):
            items = data.get('items', data.get('results', data.get('data', [])))
            has_more = data.get('has_more', data.get('next', False))
        else:
            items = data
            has_more = len(items) > 0

        all_data.extend(items)

        if not has_more:
            logger.info(f"No more pages after page {page}")
            break

        page += 1

    return {
        'status': 'success',
        'total_items': len(all_data),
        'pages_fetched': page,
        'data': all_data
    }


@app.task(bind=True)
def batch_api_calls(self, urls: List[str], timeout: int = 30) -> List[dict]:
    """
    Make multiple API calls in batch.

    Args:
        urls: List of URLs to fetch
        timeout: Request timeout

    Returns:
        list: Results from all API calls

    Example:
        urls = [
            'https://api.example.com/user/1',
            'https://api.example.com/user/2',
            'https://api.example.com/user/3',
        ]
        result = batch_api_calls.delay(urls)
    """
    results = []

    for i, url in enumerate(urls):
        logger.info(f"Fetching URL {i+1}/{len(urls)}: {url}")

        try:
            response = requests.get(url, timeout=timeout)
            response.raise_for_status()

            results.append({
                'url': url,
                'status': 'success',
                'data': response.json()
            })

        except Exception as exc:
            logger.error(f"Failed to fetch {url}: {exc}")
            results.append({
                'url': url,
                'status': 'error',
                'error': str(exc)
            })

    return results


@app.task(
    bind=True,
    autoretry_for=(RequestException,),
    max_retries=3
)
def webhook_delivery(
    self,
    webhook_url: str,
    event_type: str,
    payload: dict
) -> dict:
    """
    Deliver webhook with retry on failure.

    Args:
        webhook_url: Webhook endpoint URL
        event_type: Type of event
        payload: Event data

    Returns:
        dict: Delivery result

    Example:
        result = webhook_delivery.delay(
            'https://client.example.com/webhooks',
            'user.created',
            {'user_id': 123, 'email': 'user@example.com'}
        )
    """
    try:
        logger.info(
            f"Delivering webhook {event_type} to {webhook_url} "
            f"(attempt {self.request.retries + 1})"
        )

        headers = {
            'Content-Type': 'application/json',
            'X-Event-Type': event_type,
            'X-Delivery-ID': self.request.id
        }

        response = requests.post(
            webhook_url,
            json=payload,
            headers=headers,
            timeout=30
        )

        response.raise_for_status()

        return {
            'status': 'delivered',
            'webhook_url': webhook_url,
            'event_type': event_type,
            'status_code': response.status_code,
            'attempt': self.request.retries + 1
        }

    except RequestException as exc:
        logger.error(f"Webhook delivery failed: {exc}")
        raise


@app.task(bind=True)
def api_with_authentication(
    self,
    url: str,
    auth_type: str = 'bearer',
    token: Optional[str] = None,
    api_key: Optional[str] = None
) -> dict:
    """
    API call with various authentication methods.

    Args:
        url: API endpoint
        auth_type: Type of auth (bearer, api_key, basic)
        token: Bearer token (use placeholder: your_token_here)
        api_key: API key (use placeholder: your_api_key_here)

    Returns:
        dict: API response

    Example:
        # Bearer token
        result = api_with_authentication.delay(
            'https://api.example.com/data',
            auth_type='bearer',
            token='your_token_here'
        )

        # API key
        result = api_with_authentication.delay(
            'https://api.example.com/data',
            auth_type='api_key',
            api_key='your_api_key_here'
        )
    """
    headers = {}

    if auth_type == 'bearer' and token:
        headers['Authorization'] = f'Bearer {token}'
    elif auth_type == 'api_key' and api_key:
        headers['X-API-Key'] = api_key
    else:
        raise ValueError(f"Invalid auth_type: {auth_type}")

    logger.info(f"Making authenticated API call to {url} (auth={auth_type})")

    response = requests.get(url, headers=headers, timeout=30)
    response.raise_for_status()

    return {
        'status': 'success',
        'url': url,
        'data': response.json()
    }


@app.task(bind=True, soft_time_limit=60)
def long_running_api_call(self, url: str) -> dict:
    """
    Long-running API call with timeout protection.

    Args:
        url: API endpoint

    Returns:
        dict: API response

    Example:
        result = long_running_api_call.delay('https://api.example.com/report')
    """
    from celery.exceptions import SoftTimeLimitExceeded

    try:
        logger.info(f"Making long-running API call to {url}")

        response = requests.get(url, timeout=55)  # Slightly less than soft limit
        response.raise_for_status()

        return {
            'status': 'success',
            'url': url,
            'data': response.json()
        }

    except SoftTimeLimitExceeded:
        logger.warning(f"API call to {url} exceeded soft time limit")
        return {
            'status': 'timeout',
            'url': url,
            'message': 'Request exceeded time limit'
        }


# API Best Practices Documentation
API_BEST_PRACTICES = """
API Task Best Practices:

1. Always Set Timeouts
   ❌ BAD:  requests.get(url)
   ✅ GOOD: requests.get(url, timeout=30)

2. Use Automatic Retries
   - autoretry_for for connection errors
   - Exponential backoff to avoid overload
   - Jitter to prevent thundering herd

3. Respect Rate Limits
   - Use rate_limit parameter
   - Implement backoff on 429 responses
   - Cache responses when possible

4. Handle Authentication Securely
   - Read tokens from environment variables
   - Never hardcode credentials
   - Use placeholders in examples

5. Log All API Calls
   - Log URL, method, status code
   - Log retry attempts
   - Track response times

6. Handle Pagination
   - Fetch all pages when needed
   - Set reasonable max_pages limit
   - Handle different pagination formats

7. Error Handling
   - Catch specific exceptions
   - Return structured error responses
   - Don't expose sensitive error details
"""


# Example usage
if __name__ == '__main__':
    # Basic API call with retry
    result1 = api_call_with_retry.delay(
        'https://api.example.com/users',
        method='GET'
    )
    print(f"API Call Task ID: {result1.id}")

    # Rate-limited API call
    result2 = rate_limited_api_call.delay(
        'https://api.example.com/data',
        'your_api_key_here'
    )
    print(f"Rate Limited Task ID: {result2.id}")

    # Paginated fetch
    result3 = paginated_api_fetch.delay(
        'https://api.example.com/users',
        params={'status': 'active'}
    )
    print(f"Paginated Fetch Task ID: {result3.id}")

    # Webhook delivery
    result4 = webhook_delivery.delay(
        'https://client.example.com/webhooks',
        'user.created',
        {'user_id': 123}
    )
    print(f"Webhook Task ID: {result4.id}")

    print("\nBest Practices:")
    print(API_BEST_PRACTICES)
