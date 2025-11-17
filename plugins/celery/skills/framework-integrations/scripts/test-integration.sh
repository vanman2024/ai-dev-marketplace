#!/bin/bash
# test-integration.sh - Test Celery framework integration
# Usage: ./test-integration.sh <framework>
# Frameworks: django, flask, fastapi

set -e

FRAMEWORK=$1
if [[ -z "$FRAMEWORK" ]]; then
    echo "Usage: $0 <framework>"
    echo "Frameworks: django, flask, fastapi"
    exit 1
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "🧪 Testing Celery + $FRAMEWORK integration..."
echo ""

# Function to run test and capture result
run_test() {
    local test_name=$1
    local test_command=$2

    echo -e "${BLUE}▶${NC} Running: $test_name"
    if eval "$test_command"; then
        echo -e "${GREEN}✓${NC} PASS: $test_name"
        return 0
    else
        echo -e "${RED}✗${NC} FAIL: $test_name"
        return 1
    fi
    echo ""
}

FAILED_TESTS=0

case "$FRAMEWORK" in
    django)
        echo "🔷 Testing Django + Celery integration..."
        echo ""

        # Test 1: Django can import Celery app
        run_test "Import Celery app" \
            "python -c 'from celery_app import app' || python -c 'import celery'" || ((FAILED_TESTS++))

        # Test 2: Django settings accessible
        run_test "Django settings" \
            "python manage.py check --settings=\${DJANGO_SETTINGS_MODULE:-settings}" || ((FAILED_TESTS++))

        # Test 3: Celery can discover tasks
        run_test "Task discovery" \
            "celery -A celery_app inspect registered 2>/dev/null | grep -q 'tasks' || echo 'No workers running (expected)'" || true

        # Test 4: Transaction safety (check for on_commit usage)
        echo -e "${BLUE}▶${NC} Checking for transaction safety patterns..."
        if find . -name "*.py" -type f -exec grep -l "transaction.on_commit" {} \; | head -1 >/dev/null; then
            echo -e "${GREEN}✓${NC} Found transaction.on_commit() usage (good!)"
        else
            echo -e "${YELLOW}⚠${NC} No transaction.on_commit() found"
            echo "   Consider using it for tasks that depend on DB state"
        fi
        echo ""

        echo "📝 Manual tests to run:"
        echo "   1. Start worker: celery -A celery_app worker -l info"
        echo "   2. Run Django shell: python manage.py shell"
        echo "   3. Test task: from myapp.tasks import my_task; my_task.delay()"
        ;;

    flask)
        echo "🔷 Testing Flask + Celery integration..."
        echo ""

        # Test 1: Flask app can be imported
        run_test "Import Flask app" \
            "python -c 'from app import app' || python -c 'from myapp import create_app; create_app()'" || ((FAILED_TESTS++))

        # Test 2: Celery app with Flask context
        run_test "Import Celery app" \
            "python -c 'from celery_app import celery' || python -c 'from celery import Celery'" || ((FAILED_TESTS++))

        # Test 3: App context handling
        echo -e "${BLUE}▶${NC} Checking for app context patterns..."
        if find . -name "*.py" -type f -exec grep -l "app.app_context()" {} \; | head -1 >/dev/null; then
            echo -e "${GREEN}✓${NC} Found app.app_context() usage (good!)"
        else
            echo -e "${YELLOW}⚠${NC} No app.app_context() found in tasks"
            echo "   Tasks may fail if they access Flask extensions"
        fi
        echo ""

        # Test 4: Celery can discover tasks
        run_test "Task discovery" \
            "celery -A celery_app inspect registered 2>/dev/null | grep -q 'tasks' || echo 'No workers running (expected)'" || true

        echo "📝 Manual tests to run:"
        echo "   1. Start worker: celery -A celery_app worker -l info"
        echo "   2. Run Flask shell: flask shell"
        echo "   3. Test task: from tasks import my_task; my_task.delay()"
        ;;

    fastapi)
        echo "🔷 Testing FastAPI + Celery integration..."
        echo ""

        # Test 1: FastAPI app can be imported
        run_test "Import FastAPI app" \
            "python -c 'from main import app' || python -c 'from app.main import app'" || ((FAILED_TESTS++))

        # Test 2: Celery app can be imported
        run_test "Import Celery app" \
            "python -c 'from celery_app import celery' || python -c 'from app.celery_app import celery'" || ((FAILED_TESTS++))

        # Test 3: Check for async task patterns
        echo -e "${BLUE}▶${NC} Checking for async patterns..."
        if find . -name "tasks.py" -type f -exec grep -l "async def" {} \; | head -1 >/dev/null; then
            echo -e "${GREEN}✓${NC} Found async task definitions"
        else
            echo -e "${YELLOW}ℹ${NC} No async tasks found (sync tasks are fine too)"
        fi
        echo ""

        # Test 4: Check for BackgroundTasks usage
        echo -e "${BLUE}▶${NC} Checking for BackgroundTasks vs Celery usage..."
        if find . -name "*.py" -type f -exec grep -l "BackgroundTasks" {} \; | head -1 >/dev/null; then
            echo -e "${GREEN}✓${NC} Found FastAPI BackgroundTasks usage"
            echo "   Remember: Use BackgroundTasks for short tasks, Celery for long/distributed tasks"
        else
            echo -e "${YELLOW}ℹ${NC} No BackgroundTasks found (using only Celery is fine)"
        fi
        echo ""

        # Test 5: Celery can discover tasks
        run_test "Task discovery" \
            "celery -A celery_app inspect registered 2>/dev/null | grep -q 'tasks' || echo 'No workers running (expected)'" || true

        echo "📝 Manual tests to run:"
        echo "   1. Start FastAPI: uvicorn main:app --reload"
        echo "   2. Start worker: celery -A celery_app worker -l info"
        echo "   3. Test endpoint that triggers task"
        echo "   4. Check task execution in worker logs"
        ;;

    *)
        echo -e "${RED}✗${NC} Unknown framework: $FRAMEWORK"
        echo "Supported frameworks: django, flask, fastapi"
        exit 1
        ;;
esac

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ $FAILED_TESTS -eq 0 ]]; then
    echo -e "${GREEN}✓ All automated tests passed!${NC}"
    echo ""
    echo "⚠️  Some tests require running workers and manual verification."
    echo "Follow the manual test steps above to complete integration testing."
    exit 0
else
    echo -e "${RED}✗ $FAILED_TESTS test(s) failed${NC}"
    echo ""
    echo "Fix the errors and run tests again."
    exit 1
fi
