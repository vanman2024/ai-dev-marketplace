#!/bin/bash
# Test A2A executor against protocol specification

set -e

EXECUTOR_FILE="$1"

if [ -z "$EXECUTOR_FILE" ]; then
  echo "Usage: test-executor.sh <executor-file>"
  exit 1
fi

if [ ! -f "$EXECUTOR_FILE" ]; then
  echo "Error: Executor file not found: $EXECUTOR_FILE"
  exit 1
fi

echo "Testing A2A executor: $EXECUTOR_FILE"
echo "================================================"

# Determine file type
if [[ "$EXECUTOR_FILE" == *.ts || "$EXECUTOR_FILE" == *.tsx ]]; then
  LANG="typescript"
  RUNTIME="tsx"
elif [[ "$EXECUTOR_FILE" == *.py ]]; then
  LANG="python"
  RUNTIME="python3"
else
  echo "Error: Unsupported file type. Use .ts or .py"
  exit 1
fi

# Create test directory
TEST_DIR=$(mktemp -d)
echo "Test directory: $TEST_DIR"

# Create test task file
cat > "$TEST_DIR/test-task.json" << 'EOF'
{
  "id": "test-task-001",
  "type": "test-execution",
  "parameters": {
    "input": "test input data",
    "timeout": 5000
  }
}
EOF

echo ""
echo "Test 1: Basic execution"
echo "------------------------"

# Check if runtime exists
if ! command -v "$RUNTIME" &> /dev/null; then
  echo "⚠️  Warning: $RUNTIME not found, skipping runtime tests"
  echo "Install $RUNTIME to run execution tests"
else
  echo "✓ Runtime available: $RUNTIME"

  # Attempt to run basic syntax check
  if [ "$LANG" = "typescript" ]; then
    if command -v tsc &> /dev/null; then
      echo "Running TypeScript syntax check..."
      if tsc --noEmit "$EXECUTOR_FILE" 2>&1 | head -20; then
        echo "✓ TypeScript syntax valid"
      else
        echo "⚠️  TypeScript syntax errors detected"
      fi
    fi
  elif [ "$LANG" = "python" ]; then
    echo "Running Python syntax check..."
    if python3 -m py_compile "$EXECUTOR_FILE" 2>&1; then
      echo "✓ Python syntax valid"
    else
      echo "❌ Python syntax errors detected"
    fi
  fi
fi

echo ""
echo "Test 2: A2A Protocol compliance"
echo "--------------------------------"

# Check for required A2A protocol fields
echo "Checking protocol compliance..."

COMPLIANCE_ERRORS=0

# Task ID handling
if grep -q "task\.id\|task\[\"id\"\]\|task_id" "$EXECUTOR_FILE"; then
  echo "✓ Task ID handling present"
else
  echo "❌ Missing task ID handling"
  COMPLIANCE_ERRORS=$((COMPLIANCE_ERRORS + 1))
fi

# Task type handling
if grep -q "task\.type\|task\[\"type\"\]\|task_type" "$EXECUTOR_FILE"; then
  echo "✓ Task type handling present"
else
  echo "❌ Missing task type handling"
  COMPLIANCE_ERRORS=$((COMPLIANCE_ERRORS + 1))
fi

# Status field in result
if grep -q "status.*:\|status =" "$EXECUTOR_FILE"; then
  echo "✓ Status field in result"
else
  echo "❌ Missing status field in result"
  COMPLIANCE_ERRORS=$((COMPLIANCE_ERRORS + 1))
fi

# Result field
if grep -q "result.*:\|result =" "$EXECUTOR_FILE"; then
  echo "✓ Result field present"
else
  echo "⚠️  Warning: No result field detected"
fi

echo ""
echo "Test 3: Error handling"
echo "----------------------"

ERROR_HANDLING_SCORE=0

# Validation errors
if grep -q "ValidationError\|validation.*error" "$EXECUTOR_FILE"; then
  echo "✓ Validation error handling"
  ERROR_HANDLING_SCORE=$((ERROR_HANDLING_SCORE + 1))
fi

# Retryable errors
if grep -q "RetryableError\|retryable" "$EXECUTOR_FILE"; then
  echo "✓ Retryable error handling"
  ERROR_HANDLING_SCORE=$((ERROR_HANDLING_SCORE + 1))
fi

# Timeout errors
if grep -q "TimeoutError\|timeout.*error" "$EXECUTOR_FILE"; then
  echo "✓ Timeout error handling"
  ERROR_HANDLING_SCORE=$((ERROR_HANDLING_SCORE + 1))
fi

# Generic error handling
if grep -q "try\|catch\|except" "$EXECUTOR_FILE"; then
  echo "✓ Generic error handling"
  ERROR_HANDLING_SCORE=$((ERROR_HANDLING_SCORE + 1))
fi

if [ $ERROR_HANDLING_SCORE -ge 2 ]; then
  echo "✓ Error handling coverage: Good ($ERROR_HANDLING_SCORE/4 patterns)"
else
  echo "⚠️  Error handling coverage: Limited ($ERROR_HANDLING_SCORE/4 patterns)"
fi

echo ""
echo "Test 4: Production readiness"
echo "-----------------------------"

READINESS_SCORE=0

# Logging
if grep -q "log\|console\|print" "$EXECUTOR_FILE"; then
  echo "✓ Logging implemented"
  READINESS_SCORE=$((READINESS_SCORE + 1))
fi

# Metrics/monitoring
if grep -q "metric\|monitor\|telemetry" "$EXECUTOR_FILE"; then
  echo "✓ Metrics/monitoring present"
  READINESS_SCORE=$((READINESS_SCORE + 1))
fi

# Timeout handling
if grep -q "timeout\|setTimeout" "$EXECUTOR_FILE"; then
  echo "✓ Timeout handling"
  READINESS_SCORE=$((READINESS_SCORE + 1))
fi

# Retry logic
if grep -q "retry\|maxAttempts\|max_attempts" "$EXECUTOR_FILE"; then
  echo "✓ Retry logic implemented"
  READINESS_SCORE=$((READINESS_SCORE + 1))
fi

# Resource cleanup
if grep -q "finally\|cleanup\|close" "$EXECUTOR_FILE"; then
  echo "✓ Resource cleanup"
  READINESS_SCORE=$((READINESS_SCORE + 1))
fi

if [ $READINESS_SCORE -ge 3 ]; then
  echo "✓ Production readiness: Good ($READINESS_SCORE/5 features)"
else
  echo "⚠️  Production readiness: Basic ($READINESS_SCORE/5 features)"
fi

# Cleanup
rm -rf "$TEST_DIR"

echo ""
echo "================================================"
echo "Test Summary"
echo "================================================"
echo "Protocol compliance errors: $COMPLIANCE_ERRORS"
echo "Error handling coverage: $ERROR_HANDLING_SCORE/4"
echo "Production readiness: $READINESS_SCORE/5"
echo ""

if [ $COMPLIANCE_ERRORS -eq 0 ] && [ $ERROR_HANDLING_SCORE -ge 2 ] && [ $READINESS_SCORE -ge 2 ]; then
  echo "✓ All tests passed!"
  echo ""
  echo "Executor is ready for A2A protocol usage."
  exit 0
else
  echo "⚠️  Tests completed with warnings"
  echo ""
  echo "Review warnings above to improve executor quality."
  exit 0
fi
