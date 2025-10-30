#!/usr/bin/env bash

# setup-monitoring.sh
# Configures comprehensive monitoring infrastructure for ElevenLabs API integration
# Usage: bash setup-monitoring.sh --project-name "my-app" --log-level "info" --metrics-port 9090

set -e

# Default configuration
PROJECT_NAME="elevenlabs-app"
LOG_LEVEL="info"
METRICS_PORT=9090
HEALTH_PORT=8080
LOG_DIR="./logs"
MONITORING_DIR="./monitoring"
SKIP_INSTALL=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --project-name)
            PROJECT_NAME="$2"
            shift 2
            ;;
        --log-level)
            LOG_LEVEL="$2"
            shift 2
            ;;
        --metrics-port)
            METRICS_PORT="$2"
            shift 2
            ;;
        --health-port)
            HEALTH_PORT="$2"
            shift 2
            ;;
        --log-dir)
            LOG_DIR="$2"
            shift 2
            ;;
        --monitoring-dir)
            MONITORING_DIR="$2"
            shift 2
            ;;
        --skip-install)
            SKIP_INSTALL=true
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Helper functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Node.js is installed
check_nodejs() {
    log_info "Checking Node.js installation..."
    if ! command -v node &> /dev/null; then
        log_error "Node.js is not installed. Please install Node.js 16+ first."
        exit 1
    fi

    NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 16 ]; then
        log_error "Node.js version must be 16 or higher. Current: $(node -v)"
        exit 1
    fi

    log_info "Node.js version: $(node -v) ✓"
}

# Check if Python is installed
check_python() {
    log_info "Checking Python installation..."
    if ! command -v python3 &> /dev/null; then
        log_warn "Python 3 is not installed. Some monitoring features may be limited."
        return 0
    fi

    log_info "Python version: $(python3 --version) ✓"
}

# Detect project type
detect_project_type() {
    log_info "Detecting project type..."

    if [ -f "package.json" ]; then
        PROJECT_TYPE="nodejs"
        log_info "Project type: Node.js"
    elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
        PROJECT_TYPE="python"
        log_info "Project type: Python"
    else
        log_warn "Could not detect project type. Defaulting to Node.js"
        PROJECT_TYPE="nodejs"
    fi
}

# Create directory structure
create_directories() {
    log_info "Creating directory structure..."

    mkdir -p "$LOG_DIR"
    mkdir -p "$MONITORING_DIR/config"
    mkdir -p "$MONITORING_DIR/dashboards"
    mkdir -p "$MONITORING_DIR/alerts"

    log_info "Created directories:"
    log_info "  - $LOG_DIR (log files)"
    log_info "  - $MONITORING_DIR/config (monitoring configuration)"
    log_info "  - $MONITORING_DIR/dashboards (Grafana dashboards)"
    log_info "  - $MONITORING_DIR/alerts (alert rules)"
}

# Install Node.js monitoring dependencies
install_nodejs_deps() {
    if [ "$SKIP_INSTALL" = true ]; then
        log_info "Skipping dependency installation (--skip-install flag)"
        return 0
    fi

    log_info "Installing Node.js monitoring dependencies..."

    # Check if package.json exists
    if [ ! -f "package.json" ]; then
        log_info "Creating package.json..."
        npm init -y
    fi

    # Install monitoring packages
    npm install --save \
        winston \
        winston-daily-rotate-file \
        prom-client \
        express-prom-bundle \
        express

    log_info "Node.js dependencies installed ✓"
}

# Install Python monitoring dependencies
install_python_deps() {
    if [ "$SKIP_INSTALL" = true ]; then
        log_info "Skipping dependency installation (--skip-install flag)"
        return 0
    fi

    log_info "Installing Python monitoring dependencies..."

    pip3 install --upgrade \
        prometheus-client \
        structlog \
        python-json-logger \
        flask

    log_info "Python dependencies installed ✓"
}

# Create Winston logger configuration (Node.js)
create_winston_config() {
    log_info "Creating Winston logger configuration..."

    cat > "$MONITORING_DIR/config/logger.js" << 'EOF'
const winston = require('winston');
const DailyRotateFile = require('winston-daily-rotate-file');

// Custom format for structured logging
const structuredFormat = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
  winston.format.errors({ stack: true }),
  winston.format.json()
);

// Console format for development
const consoleFormat = winston.format.combine(
  winston.format.colorize(),
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
  winston.format.printf(({ timestamp, level, message, ...meta }) => {
    let metaStr = '';
    if (Object.keys(meta).length > 0) {
      metaStr = JSON.stringify(meta, null, 2);
    }
    return `${timestamp} [${level}]: ${message} ${metaStr}`;
  })
);

// Create logger instance
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: structuredFormat,
  defaultMeta: {
    service: process.env.PROJECT_NAME || 'elevenlabs-app',
    environment: process.env.NODE_ENV || 'development'
  },
  transports: [
    // Daily rotating file for all logs
    new DailyRotateFile({
      filename: 'logs/app-%DATE%.log',
      datePattern: 'YYYY-MM-DD',
      maxSize: '20m',
      maxFiles: '14d',
      level: 'info'
    }),
    // Separate file for errors
    new DailyRotateFile({
      filename: 'logs/error-%DATE%.log',
      datePattern: 'YYYY-MM-DD',
      maxSize: '20m',
      maxFiles: '30d',
      level: 'error'
    }),
    // Console output
    new winston.transports.Console({
      format: consoleFormat
    })
  ]
});

// Add request logging helper
logger.logRequest = (req, res, duration) => {
  logger.info('HTTP Request', {
    method: req.method,
    path: req.path,
    statusCode: res.statusCode,
    duration: `${duration}ms`,
    ip: req.ip,
    userAgent: req.get('user-agent')
  });
};

// Add error logging helper
logger.logError = (error, context = {}) => {
  logger.error('Error occurred', {
    error: error.message,
    stack: error.stack,
    ...context
  });
};

module.exports = logger;
EOF

    log_info "Winston logger configuration created ✓"
}

# Create Python logger configuration
create_python_logger() {
    log_info "Creating Python logger configuration..."

    cat > "$MONITORING_DIR/config/logger.py" << 'EOF'
import logging
import structlog
from pythonjsonlogger import jsonlogger
import os
from datetime import datetime

# Configure structlog
structlog.configure(
    processors=[
        structlog.stdlib.filter_by_level,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
        structlog.processors.UnicodeDecoder(),
        structlog.processors.JSONRenderer()
    ],
    context_class=dict,
    logger_factory=structlog.stdlib.LoggerFactory(),
    cache_logger_on_first_use=True,
)

class CustomJsonFormatter(jsonlogger.JsonFormatter):
    def add_fields(self, log_record, record, message_dict):
        super(CustomJsonFormatter, self).add_fields(log_record, record, message_dict)
        log_record['timestamp'] = datetime.utcnow().isoformat()
        log_record['level'] = record.levelname
        log_record['service'] = os.getenv('PROJECT_NAME', 'elevenlabs-app')
        log_record['environment'] = os.getenv('ENVIRONMENT', 'development')

def setup_logger(name: str, level: str = 'INFO'):
    """Setup logger with file and console handlers"""
    logger = logging.getLogger(name)
    logger.setLevel(getattr(logging, level.upper()))

    # Create logs directory
    os.makedirs('logs', exist_ok=True)

    # File handler with JSON format
    file_handler = logging.FileHandler(f'logs/{name}.log')
    file_handler.setFormatter(CustomJsonFormatter(
        '%(timestamp)s %(level)s %(name)s %(message)s'
    ))
    logger.addHandler(file_handler)

    # Console handler
    console_handler = logging.StreamHandler()
    console_handler.setFormatter(logging.Formatter(
        '%(asctime)s [%(levelname)s] %(name)s: %(message)s'
    ))
    logger.addHandler(console_handler)

    return structlog.wrap_logger(logger)

# Create default logger
logger = setup_logger('elevenlabs-app', os.getenv('LOG_LEVEL', 'INFO'))
EOF

    log_info "Python logger configuration created ✓"
}

# Create Prometheus metrics configuration
create_prometheus_config() {
    log_info "Creating Prometheus metrics configuration..."

    if [ "$PROJECT_TYPE" = "nodejs" ]; then
        cat > "$MONITORING_DIR/config/metrics.js" << 'EOF'
const promClient = require('prom-client');

// Create a Registry
const register = new promClient.Registry();

// Add default metrics
promClient.collectDefaultMetrics({ register });

// Custom metrics for ElevenLabs API
const elevenLabsMetrics = {
  // Request metrics
  requestsTotal: new promClient.Counter({
    name: 'elevenlabs_requests_total',
    help: 'Total number of requests to ElevenLabs API',
    labelNames: ['method', 'status', 'model'],
    registers: [register]
  }),

  requestDuration: new promClient.Histogram({
    name: 'elevenlabs_request_duration_seconds',
    help: 'Duration of requests to ElevenLabs API',
    labelNames: ['method', 'model'],
    buckets: [0.1, 0.5, 1, 2, 5, 10],
    registers: [register]
  }),

  concurrentRequests: new promClient.Gauge({
    name: 'elevenlabs_concurrent_requests',
    help: 'Current number of concurrent requests',
    registers: [register]
  }),

  queueDepth: new promClient.Gauge({
    name: 'elevenlabs_queue_depth',
    help: 'Number of requests in queue',
    registers: [register]
  }),

  // Error metrics
  errorsTotal: new promClient.Counter({
    name: 'elevenlabs_errors_total',
    help: 'Total number of errors',
    labelNames: ['type', 'code'],
    registers: [register]
  }),

  retriesTotal: new promClient.Counter({
    name: 'elevenlabs_retries_total',
    help: 'Total number of retry attempts',
    labelNames: ['reason'],
    registers: [register]
  }),

  circuitBreakerState: new promClient.Gauge({
    name: 'elevenlabs_circuit_breaker_state',
    help: 'Circuit breaker state (0=closed, 1=open, 2=half-open)',
    labelNames: ['circuit'],
    registers: [register]
  }),

  // Business metrics
  charactersGenerated: new promClient.Counter({
    name: 'elevenlabs_characters_generated_total',
    help: 'Total characters processed',
    labelNames: ['model'],
    registers: [register]
  }),

  audioDuration: new promClient.Counter({
    name: 'elevenlabs_audio_duration_seconds_total',
    help: 'Total audio duration generated',
    labelNames: ['model'],
    registers: [register]
  }),

  quotaUsed: new promClient.Gauge({
    name: 'elevenlabs_quota_used_percentage',
    help: 'Quota utilization percentage',
    registers: [register]
  })
};

module.exports = {
  register,
  metrics: elevenLabsMetrics
};
EOF
    else
        cat > "$MONITORING_DIR/config/metrics.py" << 'EOF'
from prometheus_client import Counter, Histogram, Gauge, CollectorRegistry

# Create registry
registry = CollectorRegistry()

# Request metrics
requests_total = Counter(
    'elevenlabs_requests_total',
    'Total number of requests to ElevenLabs API',
    ['method', 'status', 'model'],
    registry=registry
)

request_duration = Histogram(
    'elevenlabs_request_duration_seconds',
    'Duration of requests to ElevenLabs API',
    ['method', 'model'],
    buckets=[0.1, 0.5, 1, 2, 5, 10],
    registry=registry
)

concurrent_requests = Gauge(
    'elevenlabs_concurrent_requests',
    'Current number of concurrent requests',
    registry=registry
)

queue_depth = Gauge(
    'elevenlabs_queue_depth',
    'Number of requests in queue',
    registry=registry
)

# Error metrics
errors_total = Counter(
    'elevenlabs_errors_total',
    'Total number of errors',
    ['type', 'code'],
    registry=registry
)

retries_total = Counter(
    'elevenlabs_retries_total',
    'Total number of retry attempts',
    ['reason'],
    registry=registry
)

circuit_breaker_state = Gauge(
    'elevenlabs_circuit_breaker_state',
    'Circuit breaker state (0=closed, 1=open, 2=half-open)',
    ['circuit'],
    registry=registry
)

# Business metrics
characters_generated = Counter(
    'elevenlabs_characters_generated_total',
    'Total characters processed',
    ['model'],
    registry=registry
)

audio_duration = Counter(
    'elevenlabs_audio_duration_seconds_total',
    'Total audio duration generated',
    ['model'],
    registry=registry
)

quota_used = Gauge(
    'elevenlabs_quota_used_percentage',
    'Quota utilization percentage',
    registry=registry
)
EOF
    fi

    log_info "Prometheus metrics configuration created ✓"
}

# Create health check endpoint
create_health_check() {
    log_info "Creating health check endpoint..."

    if [ "$PROJECT_TYPE" = "nodejs" ]; then
        cat > "$MONITORING_DIR/config/health.js" << EOF
const express = require('express');
const { register } = require('./metrics');

const app = express();
const PORT = process.env.HEALTH_PORT || $HEALTH_PORT;

// Health check endpoint
app.get('/health', (req, res) => {
  const health = {
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    service: process.env.PROJECT_NAME || '$PROJECT_NAME'
  };

  res.status(200).json(health);
});

// Readiness check
app.get('/ready', async (req, res) => {
  try {
    // Add checks for dependencies here
    // e.g., database connection, API connectivity

    res.status(200).json({
      status: 'ready',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(503).json({
      status: 'not ready',
      error: error.message
    });
  }
});

// Metrics endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

app.listen(PORT, () => {
  console.log(\`Health check server running on port \${PORT}\`);
  console.log(\`  - Health: http://localhost:\${PORT}/health\`);
  console.log(\`  - Readiness: http://localhost:\${PORT}/ready\`);
  console.log(\`  - Metrics: http://localhost:\${PORT}/metrics\`);
});

module.exports = app;
EOF
    else
        cat > "$MONITORING_DIR/config/health.py" << EOF
from flask import Flask, jsonify
from prometheus_client import generate_latest
from metrics import registry
import os
import time

app = Flask(__name__)
start_time = time.time()

@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': time.time(),
        'uptime': time.time() - start_time,
        'service': os.getenv('PROJECT_NAME', '$PROJECT_NAME')
    })

@app.route('/ready')
def ready():
    """Readiness check endpoint"""
    try:
        # Add checks for dependencies here
        return jsonify({
            'status': 'ready',
            'timestamp': time.time()
        })
    except Exception as e:
        return jsonify({
            'status': 'not ready',
            'error': str(e)
        }), 503

@app.route('/metrics')
def metrics():
    """Prometheus metrics endpoint"""
    return generate_latest(registry)

if __name__ == '__main__':
    port = int(os.getenv('HEALTH_PORT', $HEALTH_PORT))
    print(f'Health check server running on port {port}')
    print(f'  - Health: http://localhost:{port}/health')
    print(f'  - Readiness: http://localhost:{port}/ready')
    print(f'  - Metrics: http://localhost:{port}/metrics')
    app.run(host='0.0.0.0', port=port)
EOF
    fi

    log_info "Health check endpoint created ✓"
}

# Create alert rules
create_alert_rules() {
    log_info "Creating alert rules..."

    cat > "$MONITORING_DIR/alerts/elevenlabs.rules.yml" << 'EOF'
groups:
  - name: elevenlabs_alerts
    interval: 30s
    rules:
      # Critical alerts
      - alert: HighErrorRate
        expr: rate(elevenlabs_errors_total[5m]) > 0.05
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate detected"
          description: "Error rate is {{ $value }} (threshold: 5%)"

      - alert: CircuitBreakerOpen
        expr: elevenlabs_circuit_breaker_state > 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Circuit breaker is open"
          description: "Circuit {{ $labels.circuit }} is in {{ $value }} state"

      - alert: HighQueueDepth
        expr: elevenlabs_queue_depth > 500
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Request queue is very deep"
          description: "Queue depth is {{ $value }} requests"

      # Warning alerts
      - alert: HighLatency
        expr: histogram_quantile(0.95, rate(elevenlabs_request_duration_seconds_bucket[5m])) > 2
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High latency detected"
          description: "P95 latency is {{ $value }}s (threshold: 2s)"

      - alert: HighQuotaUsage
        expr: elevenlabs_quota_used_percentage > 90
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Quota usage is high"
          description: "Quota usage is {{ $value }}% (threshold: 90%)"

      - alert: HighRetryRate
        expr: rate(elevenlabs_retries_total[5m]) > 0.2
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High retry rate detected"
          description: "Retry rate is {{ $value }} (threshold: 20%)"
EOF

    log_info "Alert rules created ✓"
}

# Create Grafana dashboard
create_grafana_dashboard() {
    log_info "Creating Grafana dashboard..."

    cat > "$MONITORING_DIR/dashboards/elevenlabs-overview.json" << 'EOF'
{
  "dashboard": {
    "title": "ElevenLabs API Monitoring",
    "tags": ["elevenlabs", "api", "production"],
    "timezone": "browser",
    "panels": [
      {
        "title": "Request Rate",
        "targets": [
          {
            "expr": "rate(elevenlabs_requests_total[5m])"
          }
        ],
        "type": "graph"
      },
      {
        "title": "Error Rate",
        "targets": [
          {
            "expr": "rate(elevenlabs_errors_total[5m])"
          }
        ],
        "type": "graph"
      },
      {
        "title": "Request Duration (P95)",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(elevenlabs_request_duration_seconds_bucket[5m]))"
          }
        ],
        "type": "graph"
      },
      {
        "title": "Concurrent Requests",
        "targets": [
          {
            "expr": "elevenlabs_concurrent_requests"
          }
        ],
        "type": "graph"
      },
      {
        "title": "Queue Depth",
        "targets": [
          {
            "expr": "elevenlabs_queue_depth"
          }
        ],
        "type": "graph"
      },
      {
        "title": "Circuit Breaker State",
        "targets": [
          {
            "expr": "elevenlabs_circuit_breaker_state"
          }
        ],
        "type": "stat"
      }
    ]
  }
}
EOF

    log_info "Grafana dashboard created ✓"
}

# Create environment template
create_env_template() {
    log_info "Creating environment template..."

    cat > "$MONITORING_DIR/.env.monitoring.example" << EOF
# Project configuration
PROJECT_NAME=$PROJECT_NAME
NODE_ENV=production
ENVIRONMENT=production

# Logging configuration
LOG_LEVEL=$LOG_LEVEL
LOG_DIR=$LOG_DIR

# Monitoring ports
METRICS_PORT=$METRICS_PORT
HEALTH_PORT=$HEALTH_PORT

# ElevenLabs API
ELEVENLABS_API_KEY=your_api_key_here
ELEVENLABS_PLAN_TIER=pro

# Alert configuration
ALERT_EMAIL=alerts@example.com
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
EOF

    log_info "Environment template created ✓"
}

# Print summary
print_summary() {
    echo ""
    log_info "=========================================="
    log_info "  Monitoring Setup Complete!"
    log_info "=========================================="
    echo ""
    log_info "Created files:"
    log_info "  - $MONITORING_DIR/config/logger.${PROJECT_TYPE: -2}"
    log_info "  - $MONITORING_DIR/config/metrics.${PROJECT_TYPE: -2}"
    log_info "  - $MONITORING_DIR/config/health.${PROJECT_TYPE: -2}"
    log_info "  - $MONITORING_DIR/alerts/elevenlabs.rules.yml"
    log_info "  - $MONITORING_DIR/dashboards/elevenlabs-overview.json"
    log_info "  - $MONITORING_DIR/.env.monitoring.example"
    echo ""
    log_info "Next steps:"
    log_info "  1. Copy .env.monitoring.example to .env and configure"
    log_info "  2. Start health check server:"
    if [ "$PROJECT_TYPE" = "nodejs" ]; then
        log_info "     node $MONITORING_DIR/config/health.js"
    else
        log_info "     python3 $MONITORING_DIR/config/health.py"
    fi
    log_info "  3. Configure Prometheus to scrape http://localhost:$HEALTH_PORT/metrics"
    log_info "  4. Import Grafana dashboard from $MONITORING_DIR/dashboards/"
    log_info "  5. Configure alert notifications"
    echo ""
    log_info "Documentation: See README.md for full setup guide"
}

# Main execution
main() {
    log_info "Starting monitoring setup for: $PROJECT_NAME"
    log_info "Configuration:"
    log_info "  - Log level: $LOG_LEVEL"
    log_info "  - Metrics port: $METRICS_PORT"
    log_info "  - Health port: $HEALTH_PORT"
    echo ""

    check_nodejs
    check_python
    detect_project_type
    create_directories

    if [ "$PROJECT_TYPE" = "nodejs" ]; then
        install_nodejs_deps
        create_winston_config
    else
        install_python_deps
        create_python_logger
    fi

    create_prometheus_config
    create_health_check
    create_alert_rules
    create_grafana_dashboard
    create_env_template

    print_summary
}

# Run main function
main
