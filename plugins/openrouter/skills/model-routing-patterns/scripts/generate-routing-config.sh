#!/bin/bash

# generate-routing-config.sh
# Interactive generator for OpenRouter routing configurations
# Supports: cost-optimized, speed-optimized, quality-optimized, balanced, custom

set -e

STRATEGY="$1"
OUTPUT_FILE="$2"

show_usage() {
    echo "Usage: $0 <strategy> [output-file]"
    echo ""
    echo "Strategies:"
    echo "  cost-optimized    - Minimize API costs with free/cheap models"
    echo "  speed-optimized   - Minimize latency with fast models"
    echo "  quality-optimized - Maximize quality with premium models"
    echo "  balanced          - Dynamic routing based on task complexity"
    echo "  custom            - Interactive custom configuration"
    echo ""
    echo "Examples:"
    echo "  $0 cost-optimized routing.json"
    echo "  $0 balanced > config.json"
    echo "  $0 custom  # Interactive mode"
    exit 1
}

if [ -z "$STRATEGY" ]; then
    show_usage
fi

# Generate configuration based on strategy
generate_config() {
    local strategy="$1"

    case "$strategy" in
        cost-optimized)
            cat <<'EOF'
{
  "strategy": "cost-optimized",
  "description": "Minimize costs using free models with premium fallback",
  "primary": "google/gemma-2-9b-it:free",
  "fallback": [
    "anthropic/claude-3-haiku",
    "anthropic/claude-3-5-sonnet"
  ],
  "timeout": 5000,
  "retry": {
    "max_attempts": 3,
    "delay_ms": 1000,
    "exponential_backoff": true
  },
  "on_error": "fallback",
  "routing_rules": {
    "simple_tasks": {
      "models": ["google/gemma-2-9b-it:free", "meta-llama/llama-3.2-3b-instruct:free"],
      "max_tokens": 1000
    },
    "complex_tasks": {
      "models": ["anthropic/claude-3-haiku", "openai/gpt-4o-mini"],
      "max_tokens": 4000
    },
    "critical_tasks": {
      "models": ["anthropic/claude-3-5-sonnet"],
      "max_tokens": 8000
    }
  },
  "cost_tracking": {
    "enabled": true,
    "alert_threshold_usd": 10.0
  }
}
EOF
            ;;

        speed-optimized)
            cat <<'EOF'
{
  "strategy": "speed-optimized",
  "description": "Minimize latency with fast models and streaming",
  "primary": "anthropic/claude-3-haiku",
  "fallback": [
    "openai/gpt-4o-mini",
    "google/gemini-flash-1.5"
  ],
  "timeout": 3000,
  "streaming": {
    "enabled": true,
    "buffer_size": 100
  },
  "retry": {
    "max_attempts": 2,
    "delay_ms": 500
  },
  "on_error": "fallback",
  "routing_rules": {
    "default": {
      "models": ["anthropic/claude-3-haiku"],
      "max_latency_ms": 1000
    },
    "streaming_required": {
      "models": ["anthropic/claude-3-haiku", "openai/gpt-4o-mini"],
      "streaming": true
    }
  },
  "geographic_routing": {
    "enabled": true,
    "prefer_region": "auto"
  }
}
EOF
            ;;

        quality-optimized)
            cat <<'EOF'
{
  "strategy": "quality-optimized",
  "description": "Maximize quality with premium models",
  "primary": "anthropic/claude-3-5-sonnet",
  "fallback": [
    "openai/gpt-4o",
    "google/gemini-pro-1.5"
  ],
  "timeout": 10000,
  "retry": {
    "max_attempts": 3,
    "delay_ms": 2000,
    "exponential_backoff": true
  },
  "on_error": "fallback",
  "routing_rules": {
    "default": {
      "models": ["anthropic/claude-3-5-sonnet"],
      "temperature": 0.7
    },
    "code_generation": {
      "models": ["anthropic/claude-3-5-sonnet"],
      "temperature": 0.2
    },
    "creative_writing": {
      "models": ["openai/gpt-4o", "anthropic/claude-3-5-sonnet"],
      "temperature": 0.9
    },
    "long_context": {
      "models": ["google/gemini-pro-1.5"],
      "max_tokens": 32000
    }
  },
  "quality_verification": {
    "enabled": true,
    "min_confidence_score": 0.8
  }
}
EOF
            ;;

        balanced)
            cat <<'EOF'
{
  "strategy": "balanced",
  "description": "Dynamic routing based on task complexity and cost",
  "routing_rules": {
    "simple_tasks": {
      "classifier": "token_count < 500",
      "models": ["google/gemma-2-9b-it:free", "meta-llama/llama-3.2-3b-instruct:free"],
      "fallback": ["anthropic/claude-3-haiku"]
    },
    "medium_tasks": {
      "classifier": "token_count >= 500 and token_count < 2000",
      "models": ["anthropic/claude-3-haiku", "openai/gpt-4o-mini"],
      "fallback": ["anthropic/claude-3-5-sonnet"]
    },
    "complex_tasks": {
      "classifier": "token_count >= 2000 or complexity == 'high'",
      "models": ["anthropic/claude-3-5-sonnet", "openai/gpt-4o"],
      "fallback": ["google/gemini-pro-1.5"]
    }
  },
  "complexity_detection": {
    "enabled": true,
    "factors": [
      "token_count",
      "code_blocks",
      "reasoning_depth",
      "domain_expertise"
    ]
  },
  "timeout": 5000,
  "retry": {
    "max_attempts": 3,
    "delay_ms": 1000
  },
  "on_error": "fallback",
  "cost_optimization": {
    "enabled": true,
    "max_cost_per_request_usd": 0.10,
    "prefer_cheaper_when_available": true
  },
  "adaptive_routing": {
    "enabled": true,
    "learn_from_history": true,
    "optimize_for": "cost_quality_balance"
  }
}
EOF
            ;;

        custom)
            echo "Interactive Custom Configuration Builder"
            echo "========================================="
            echo ""

            # Ask questions
            read -p "Primary optimization goal (cost/speed/quality): " GOAL
            read -p "Primary model (e.g., anthropic/claude-3-haiku): " PRIMARY
            read -p "Fallback model 1 (or press Enter to skip): " FALLBACK1
            read -p "Fallback model 2 (or press Enter to skip): " FALLBACK2
            read -p "Timeout in milliseconds (default: 5000): " TIMEOUT
            TIMEOUT=${TIMEOUT:-5000}
            read -p "Max retries (default: 3): " MAX_RETRIES
            MAX_RETRIES=${MAX_RETRIES:-3}

            # Build fallback array
            FALLBACK_JSON="[]"
            if [ -n "$FALLBACK1" ]; then
                FALLBACK_JSON="[\"$FALLBACK1\"]"
                if [ -n "$FALLBACK2" ]; then
                    FALLBACK_JSON="[\"$FALLBACK1\", \"$FALLBACK2\"]"
                fi
            fi

            # Generate config
            cat <<EOF
{
  "strategy": "custom-$GOAL",
  "description": "Custom routing configuration",
  "primary": "$PRIMARY",
  "fallback": $FALLBACK_JSON,
  "timeout": $TIMEOUT,
  "retry": {
    "max_attempts": $MAX_RETRIES,
    "delay_ms": 1000,
    "exponential_backoff": true
  },
  "on_error": "fallback"
}
EOF
            ;;

        *)
            echo "Error: Unknown strategy '$STRATEGY'"
            echo ""
            show_usage
            ;;
    esac
}

# Generate configuration
CONFIG=$(generate_config "$STRATEGY")

# Output to file or stdout
if [ -n "$OUTPUT_FILE" ]; then
    echo "$CONFIG" > "$OUTPUT_FILE"
    echo "Configuration generated: $OUTPUT_FILE"
    echo ""
    echo "Next steps:"
    echo "  1. Validate: ./scripts/validate-routing-config.sh $OUTPUT_FILE"
    echo "  2. Test: ./scripts/test-fallback-chain.sh $OUTPUT_FILE"
    echo "  3. Deploy: Use configuration in your application"
else
    echo "$CONFIG"
fi
