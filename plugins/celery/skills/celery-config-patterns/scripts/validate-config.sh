#!/bin/bash
# Validate Celery Configuration
#
# This script validates Celery configuration for common errors and misconfigurations.
# It checks:
# - Python syntax
# - Celery app importability
# - Broker URL format
# - Required settings
# - Task discovery paths
#
# Usage:
#   bash validate-config.sh
#   bash validate-config.sh --config=celeryconfig.py
#   bash validate-config.sh --app=myapp.celery:app

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
CONFIG_FILE="${1:-celeryconfig.py}"
CELERY_APP="${CELERY_APP:-}"
ERRORS=0

echo "=================================================="
echo "Celery Configuration Validator"
echo "=================================================="
echo ""

# ============================================================================
# Helper Functions
# ============================================================================

log_error() {
    echo -e "${RED}✗ ERROR:${NC} $1"
    ((ERRORS++))
}

log_warning() {
    echo -e "${YELLOW}⚠ WARNING:${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_info() {
    echo "  $1"
}

# ============================================================================
# Parse Arguments
# ============================================================================

for arg in "$@"; do
    case $arg in
        --config=*)
            CONFIG_FILE="${arg#*=}"
            shift
            ;;
        --app=*)
            CELERY_APP="${arg#*=}"
            shift
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --config=FILE    Path to Celery config file (default: celeryconfig.py)"
            echo "  --app=APP        Celery app module path (e.g., myapp.celery:app)"
            echo "  --help           Show this help message"
            echo ""
            exit 0
            ;;
    esac
done

# ============================================================================
# Check Python is Available
# ============================================================================

echo "Checking Python installation..."
if ! command -v python3 &> /dev/null; then
    log_error "Python 3 is not installed or not in PATH"
    exit 1
fi
log_success "Python 3 found: $(python3 --version)"
echo ""

# ============================================================================
# Check Celery is Installed
# ============================================================================

echo "Checking Celery installation..."
if ! python3 -c "import celery" 2>/dev/null; then
    log_error "Celery is not installed"
    log_info "Install with: pip install celery"
    exit 1
fi
CELERY_VERSION=$(python3 -c "import celery; print(celery.__version__)")
log_success "Celery found: version $CELERY_VERSION"
echo ""

# ============================================================================
# Validate Config File Syntax
# ============================================================================

if [ -f "$CONFIG_FILE" ]; then
    echo "Validating config file: $CONFIG_FILE"

    # Check Python syntax
    if python3 -m py_compile "$CONFIG_FILE" 2>/dev/null; then
        log_success "Python syntax is valid"
    else
        log_error "Python syntax error in $CONFIG_FILE"
        python3 -m py_compile "$CONFIG_FILE"
    fi

    # Check for common issues
    if grep -q "broker_url\s*=\s*['\"]$" "$CONFIG_FILE"; then
        log_warning "Broker URL appears to be empty"
    fi

    if grep -q "sk-ant-\|sk-\|password123\|admin" "$CONFIG_FILE"; then
        log_error "Possible hardcoded credentials found in config file"
        log_info "Use environment variables for credentials"
    fi

    echo ""
else
    log_warning "Config file $CONFIG_FILE not found (may be configured in code)"
    echo ""
fi

# ============================================================================
# Validate Broker URL Format
# ============================================================================

echo "Validating broker URL format..."
python3 << 'EOF'
import os
import sys
import re

# Try to get broker URL from environment or config
broker_url = os.getenv('CELERY_BROKER_URL', '')

if not broker_url:
    try:
        # Try to import from config
        import celeryconfig
        broker_url = getattr(celeryconfig, 'broker_url', '') or \
                     getattr(celeryconfig, 'CELERY_BROKER_URL', '')
    except:
        pass

if not broker_url:
    print("⚠ WARNING: Broker URL not found in environment or config")
    sys.exit(0)

# Validate URL format
valid_schemes = ['redis://', 'rediss://', 'amqp://', 'amqps://', 'sentinel://']
is_valid = any(broker_url.startswith(scheme) for scheme in valid_schemes)

if is_valid:
    print(f"✓ Broker URL format appears valid: {broker_url.split('@')[0]}...")
else:
    print(f"✗ ERROR: Invalid broker URL format: {broker_url}")
    print(f"  Expected one of: {', '.join(valid_schemes)}")
    sys.exit(1)

# Check for localhost in production
if 'localhost' in broker_url or '127.0.0.1' in broker_url:
    env = os.getenv('ENVIRONMENT', 'development')
    if env == 'production':
        print("⚠ WARNING: Using localhost in production environment")
EOF
echo ""

# ============================================================================
# Validate Celery App Import
# ============================================================================

if [ -n "$CELERY_APP" ]; then
    echo "Validating Celery app: $CELERY_APP"

    python3 << EOF
import sys
try:
    # Parse app string (e.g., "myapp.celery:app")
    module_path, app_name = "$CELERY_APP".rsplit(':', 1)

    # Import module
    import importlib
    module = importlib.import_module(module_path)

    # Get app object
    app = getattr(module, app_name)

    # Validate it's a Celery instance
    from celery import Celery
    if not isinstance(app, Celery):
        print(f"✗ ERROR: {app_name} is not a Celery instance")
        sys.exit(1)

    print(f"✓ Celery app imported successfully")
    print(f"  Main: {app.main}")
    print(f"  Broker: {app.conf.broker_url.split('@')[0] if app.conf.broker_url else 'Not configured'}...")

except Exception as e:
    print(f"✗ ERROR: Failed to import Celery app: {e}")
    sys.exit(1)
EOF

    if [ $? -ne 0 ]; then
        ((ERRORS++))
    fi
    echo ""
fi

# ============================================================================
# Check Required Settings
# ============================================================================

echo "Checking required settings..."
python3 << 'EOF'
import os
import sys

required_settings = {
    'broker_url': 'Broker URL for message transport',
    'result_backend': 'Backend for storing task results',
}

config = {}
try:
    import celeryconfig
    config = vars(celeryconfig)
except:
    pass

missing = []
for setting, description in required_settings.items():
    # Check config file
    if setting in config or setting.upper() in config:
        print(f"✓ {setting} is configured")
        continue

    # Check environment
    env_var = f"CELERY_{setting.upper()}"
    if os.getenv(env_var):
        print(f"✓ {setting} found in environment ({env_var})")
        continue

    # Not found
    print(f"⚠ WARNING: {setting} not found")
    print(f"  Description: {description}")
    missing.append(setting)

if missing:
    print(f"\n⚠ WARNING: {len(missing)} settings not configured")
EOF
echo ""

# ============================================================================
# Check Task Discovery
# ============================================================================

echo "Checking task discovery configuration..."
python3 << 'EOF'
import os
import sys
import glob

config = {}
try:
    import celeryconfig
    config = vars(celeryconfig)
except:
    pass

# Check imports setting
imports = config.get('imports', config.get('CELERY_IMPORTS', []))
if imports:
    print(f"✓ Task imports configured: {imports}")

    # Try to import each module
    for module_name in imports:
        try:
            __import__(module_name)
            print(f"  ✓ {module_name} is importable")
        except ImportError as e:
            print(f"  ✗ ERROR: Cannot import {module_name}: {e}")

# Check for tasks.py files
task_files = glob.glob('**/tasks.py', recursive=True)
if task_files:
    print(f"✓ Found {len(task_files)} tasks.py files:")
    for f in task_files[:5]:  # Show first 5
        print(f"  - {f}")
    if len(task_files) > 5:
        print(f"  ... and {len(task_files) - 5} more")
else:
    print("⚠ WARNING: No tasks.py files found")
    print("  Create tasks.py or configure CELERY_IMPORTS")
EOF
echo ""

# ============================================================================
# Check Broker Connection (Optional)
# ============================================================================

echo "Testing broker connection..."
python3 << 'EOF'
import os
import sys

try:
    from celery import Celery

    # Create temporary app
    broker_url = os.getenv('CELERY_BROKER_URL')
    if not broker_url:
        try:
            import celeryconfig
            broker_url = getattr(celeryconfig, 'broker_url', None) or \
                        getattr(celeryconfig, 'CELERY_BROKER_URL', None)
        except:
            pass

    if not broker_url:
        print("⚠ WARNING: Cannot test broker connection (URL not found)")
        sys.exit(0)

    app = Celery(broker=broker_url)

    # Try to connect
    conn = app.connection()
    conn.ensure_connection(max_retries=3)
    print("✓ Broker connection successful")

except Exception as e:
    print(f"✗ ERROR: Broker connection failed: {e}")
    print("  Make sure broker is running and accessible")
    sys.exit(1)
EOF
echo ""

# ============================================================================
# Security Checks
# ============================================================================

echo "Running security checks..."

# Check for hardcoded credentials
if find . -name "*.py" -type f -exec grep -l "password\s*=\s*['\"][^'\"]*['\"]" {} \; 2>/dev/null | head -n 1 | grep -q .; then
    log_warning "Possible hardcoded passwords found in Python files"
    log_info "Use environment variables for sensitive data"
fi

# Check .gitignore
if [ -f .gitignore ]; then
    if ! grep -q "\.env" .gitignore; then
        log_warning ".env files not in .gitignore"
        log_info "Add '.env' to .gitignore to protect credentials"
    else
        log_success ".env files are protected by .gitignore"
    fi
fi

echo ""

# ============================================================================
# Summary
# ============================================================================

echo "=================================================="
echo "Validation Summary"
echo "=================================================="

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo ""
    echo "Your Celery configuration appears to be valid."
    echo ""
    echo "Next steps:"
    echo "  1. Start Celery worker: celery -A myapp worker --loglevel=info"
    echo "  2. Start Celery beat (if using): celery -A myapp beat --loglevel=info"
    echo "  3. Monitor with Flower: celery -A myapp flower"
    echo ""
    exit 0
else
    echo -e "${RED}✗ Validation failed with $ERRORS error(s)${NC}"
    echo ""
    echo "Please fix the errors above before starting Celery."
    echo ""
    exit 1
fi
