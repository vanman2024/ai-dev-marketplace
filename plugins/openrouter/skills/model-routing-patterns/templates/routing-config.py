"""
OpenRouter Model Routing Configuration (Python)

This module provides model routing configuration for OpenRouter
with support for multiple routing strategies, fallback chains, and monitoring.
"""

import json
import time
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass, field
from enum import Enum


class RoutingStrategy(Enum):
    """Available routing strategies"""
    COST_OPTIMIZED = "cost-optimized"
    SPEED_OPTIMIZED = "speed-optimized"
    QUALITY_OPTIMIZED = "quality-optimized"
    BALANCED = "balanced"
    CUSTOM = "custom"


@dataclass
class RetryConfig:
    """Retry configuration"""
    max_attempts: int = 3
    delay_ms: int = 1000
    exponential_backoff: bool = True


@dataclass
class RoutingRule:
    """Single routing rule"""
    description: str
    models: List[str]
    fallback: Optional[List[str]] = None
    classifier: Optional[Dict[str, Any]] = None
    max_tokens: int = 2000
    temperature: float = 0.7
    streaming: bool = False
    max_latency_ms: Optional[int] = None
    timeout: Optional[int] = None


@dataclass
class CostTrackingConfig:
    """Cost tracking configuration"""
    enabled: bool = True
    log_requests: bool = True
    alert_threshold_usd: float = 10.0
    daily_budget_usd: Optional[float] = None


@dataclass
class MonitoringConfig:
    """Monitoring configuration"""
    enabled: bool = True
    metrics: List[str] = field(default_factory=lambda: [
        "request_count", "success_rate", "avg_latency", "total_cost"
    ])
    alert_thresholds: Dict[str, float] = field(default_factory=dict)


@dataclass
class RoutingConfig:
    """Main routing configuration"""
    strategy: RoutingStrategy
    description: str
    version: str = "1.0.0"
    primary: Optional[str] = None
    fallback: Optional[List[str]] = None
    timeout: int = 5000
    retry: RetryConfig = field(default_factory=RetryConfig)
    on_error: str = "fallback"
    routing_rules: Optional[Dict[str, RoutingRule]] = None
    cost_tracking: Optional[CostTrackingConfig] = None
    monitoring: Optional[MonitoringConfig] = None


@dataclass
class RequestContext:
    """Request context for routing decisions"""
    messages: List[Dict[str, str]]
    token_count: Optional[int] = None
    task_type: Optional[str] = None
    complexity_score: Optional[float] = None
    streaming_required: bool = False
    latency_requirement: Optional[int] = None


@dataclass
class ModelSelection:
    """Selected model and configuration"""
    model: str
    fallback: List[str]
    rule: str
    config: Dict[str, Any]


@dataclass
class ModelResponse:
    """Model response with metadata"""
    content: str
    model: str
    cost: float
    latency: int


class ModelRouter:
    """
    Model Router
    Handles model selection based on routing configuration
    """

    def __init__(self, config: RoutingConfig):
        self.config = config
        self.request_count: Dict[str, int] = {}
        self.total_cost: float = 0.0

    def select_model(self, context: RequestContext) -> ModelSelection:
        """Select best model based on request context"""

        # Apply routing rules
        if self.config.routing_rules:
            for rule_name, rule in self.config.routing_rules.items():
                if self._matches_rule(context, rule):
                    return ModelSelection(
                        model=rule.models[0],
                        fallback=rule.fallback or rule.models[1:],
                        rule=rule_name,
                        config={
                            'max_tokens': rule.max_tokens,
                            'temperature': rule.temperature,
                            'streaming': rule.streaming
                        }
                    )

        # Default to primary/fallback
        return ModelSelection(
            model=self.config.primary or 'anthropic/claude-4.5-sonnet',
            fallback=self.config.fallback or [],
            rule='default',
            config={}
        )

    def _matches_rule(self, context: RequestContext, rule: RoutingRule) -> bool:
        """Check if request matches routing rule"""
        if not rule.classifier:
            return False

        conditions = rule.classifier.get('conditions', [])

        for condition in conditions:
            # Simple condition evaluation (extend as needed)
            if 'token_count <' in condition and context.token_count:
                threshold = int(condition.split('<')[1].strip())
                if context.token_count >= threshold:
                    return False

            if 'token_count >=' in condition and context.token_count:
                threshold = int(condition.split('>=')[1].split()[0])
                if context.token_count < threshold:
                    return False

            if 'task_type in' in condition and context.task_type:
                # Extract task types from condition
                allowed_types = condition.split('[')[1].split(']')[0]
                allowed_types = [t.strip().strip("'\"") for t in allowed_types.split(',')]
                if context.task_type not in allowed_types:
                    return False

        return True

    async def execute_with_fallback(
        self,
        context: RequestContext,
        api_client: 'OpenRouterClient'
    ) -> ModelResponse:
        """Execute request with fallback chain"""
        selection = self.select_model(context)
        models = [selection.model] + selection.fallback

        last_error = None

        for i, model in enumerate(models):
            try:
                print(f"Attempting model {i + 1}/{len(models)}: {model}")

                response = await self._execute_with_retry(
                    model,
                    context,
                    api_client,
                    selection.config
                )

                # Track metrics
                self._track_request(model, response.cost)

                return response

            except Exception as error:
                last_error = error
                print(f"Model {model} failed: {error}")

                if i == len(models) - 1:
                    # Last model in chain
                    raise Exception(f"All models failed. Last error: {last_error}")

                # Continue to next model
                continue

        raise Exception("Fallback chain exhausted")

    async def _execute_with_retry(
        self,
        model: str,
        context: RequestContext,
        api_client: 'OpenRouterClient',
        rule_config: Dict[str, Any]
    ) -> ModelResponse:
        """Execute request with retry logic"""
        max_attempts = self.config.retry.max_attempts
        delay = self.config.retry.delay_ms / 1000  # Convert to seconds

        for attempt in range(1, max_attempts + 1):
            try:
                response = await api_client.chat(
                    model=model,
                    messages=context.messages,
                    max_tokens=rule_config.get('max_tokens', 2000),
                    temperature=rule_config.get('temperature', 0.7),
                    stream=rule_config.get('streaming', False)
                )

                return response

            except Exception as error:
                if attempt == max_attempts:
                    raise error

                print(f"Retry attempt {attempt}/{max_attempts} after {delay}s")
                time.sleep(delay)

                if self.config.retry.exponential_backoff:
                    delay *= 2

        raise Exception("Max retries exceeded")

    def _track_request(self, model: str, cost: float):
        """Track request metrics"""
        self.request_count[model] = self.request_count.get(model, 0) + 1
        self.total_cost += cost

        # Check budget alerts
        if self.config.cost_tracking and self.config.cost_tracking.alert_threshold_usd:
            if self.total_cost >= self.config.cost_tracking.alert_threshold_usd:
                print(f"⚠️ Cost alert: ${self.total_cost:.2f} >= ${self.config.cost_tracking.alert_threshold_usd}")

    def get_stats(self) -> Dict[str, Any]:
        """Get routing statistics"""
        total_requests = sum(self.request_count.values())

        return {
            'total_requests': total_requests,
            'total_cost': self.total_cost,
            'model_distribution': self.request_count,
            'avg_cost_per_request': self.total_cost / total_requests if total_requests > 0 else 0
        }


class OpenRouterClient:
    """Mock OpenRouter API client (replace with actual implementation)"""

    async def chat(
        self,
        model: str,
        messages: List[Dict[str, str]],
        max_tokens: int,
        temperature: float,
        stream: bool
    ) -> ModelResponse:
        """Execute chat completion request"""
        # TODO: Implement actual API call
        return ModelResponse(
            content=f"Response from {model}",
            model=model,
            cost=0.001,
            latency=500
        )


def load_config_from_file(filepath: str) -> RoutingConfig:
    """Load routing configuration from JSON file"""
    with open(filepath, 'r') as f:
        data = json.load(f)

    # Convert to RoutingConfig
    retry_config = RetryConfig(**data.get('retry', {}))

    routing_rules = None
    if 'routing_rules' in data:
        routing_rules = {
            name: RoutingRule(**rule)
            for name, rule in data['routing_rules'].items()
        }

    cost_tracking = None
    if 'cost_tracking' in data:
        cost_tracking = CostTrackingConfig(**data['cost_tracking'])

    monitoring = None
    if 'monitoring' in data:
        monitoring = MonitoringConfig(**data['monitoring'])

    return RoutingConfig(
        strategy=RoutingStrategy(data['strategy']),
        description=data['description'],
        version=data.get('version', '1.0.0'),
        primary=data.get('primary'),
        fallback=data.get('fallback'),
        timeout=data.get('timeout', 5000),
        retry=retry_config,
        on_error=data.get('on_error', 'fallback'),
        routing_rules=routing_rules,
        cost_tracking=cost_tracking,
        monitoring=monitoring
    )


# Example usage
async def example_usage():
    """Example usage of ModelRouter"""

    # Load configuration
    config = load_config_from_file('balanced-routing.json')

    # Create router
    router = ModelRouter(config)

    # Create API client
    api_client = OpenRouterClient()

    # Execute request
    context = RequestContext(
        messages=[{'role': 'user', 'content': 'Hello!'}],
        token_count=100,
        task_type='classification'
    )

    try:
        response = await router.execute_with_fallback(context, api_client)
        print('Response:', response)
        print('Stats:', router.get_stats())
    except Exception as error:
        print('Error:', error)


if __name__ == '__main__':
    import asyncio
    asyncio.run(example_usage())
