#!/bin/bash
# Validate A2A executor implementation structure and compliance

set -e

EXECUTOR_FILE="$1"

if [ -z "$EXECUTOR_FILE" ]; then
  echo "Usage: validate-executor.sh <executor-file>"
  exit 1
fi

if [ ! -f "$EXECUTOR_FILE" ]; then
  echo "Error: Executor file not found: $EXECUTOR_FILE"
  exit 1
fi

echo "Validating A2A executor: $EXECUTOR_FILE"
echo "================================================"

# Determine file type
if [[ "$EXECUTOR_FILE" == *.ts || "$EXECUTOR_FILE" == *.tsx ]]; then
  LANG="typescript"
elif [[ "$EXECUTOR_FILE" == *.py ]]; then
  LANG="python"
else
  echo "Error: Unsupported file type. Use .ts or .py"
  exit 1
fi

ERRORS=0

# Validation checks
echo "Checking required components..."

if [ "$LANG" = "typescript" ]; then
  # TypeScript validations

  # Check for task interface/type
  if ! grep -q "interface.*Task\|type.*Task" "$EXECUTOR_FILE"; then
    echo "❌ Missing task interface/type definition"
    ERRORS=$((ERRORS + 1))
  else
    echo "✓ Task interface/type defined"
  fi

  # Check for result interface/type
  if ! grep -q "interface.*Result\|type.*Result" "$EXECUTOR_FILE"; then
    echo "❌ Missing result interface/type definition"
    ERRORS=$((ERRORS + 1))
  else
    echo "✓ Result interface/type defined"
  fi

  # Check for execute function
  if ! grep -q "async function execute\|executeTask\|async execute" "$EXECUTOR_FILE"; then
    echo "❌ Missing execute function"
    ERRORS=$((ERRORS + 1))
  else
    echo "✓ Execute function defined"
  fi

  # Check for error handling
  if ! grep -q "try\|catch" "$EXECUTOR_FILE"; then
    echo "⚠️  Warning: No error handling detected (try/catch)"
  else
    echo "✓ Error handling present"
  fi

  # Check for validation
  if ! grep -q "validate\|Validation" "$EXECUTOR_FILE"; then
    echo "⚠️  Warning: No validation logic detected"
  else
    echo "✓ Validation logic present"
  fi

elif [ "$LANG" = "python" ]; then
  # Python validations

  # Check for task class/dataclass
  if ! grep -q "class.*Task\|@dataclass" "$EXECUTOR_FILE"; then
    echo "❌ Missing task class definition"
    ERRORS=$((ERRORS + 1))
  else
    echo "✓ Task class defined"
  fi

  # Check for result class/dataclass
  if ! grep -q "class.*Result\|@dataclass" "$EXECUTOR_FILE"; then
    echo "❌ Missing result class definition"
    ERRORS=$((ERRORS + 1))
  else
    echo "✓ Result class defined"
  fi

  # Check for execute function
  if ! grep -q "async def execute\|def execute_task" "$EXECUTOR_FILE"; then
    echo "❌ Missing execute function"
    ERRORS=$((ERRORS + 1))
  else
    echo "✓ Execute function defined"
  fi

  # Check for error handling
  if ! grep -q "try:\|except" "$EXECUTOR_FILE"; then
    echo "⚠️  Warning: No error handling detected (try/except)"
  else
    echo "✓ Error handling present"
  fi

  # Check for validation
  if ! grep -q "validate\|Validation" "$EXECUTOR_FILE"; then
    echo "⚠️  Warning: No validation logic detected"
  else
    echo "✓ Validation logic present"
  fi
fi

# Check for common best practices

# Logging
if grep -q "console.log\|logger\|print\|logging" "$EXECUTOR_FILE"; then
  echo "✓ Logging implemented"
else
  echo "⚠️  Warning: No logging detected"
fi

# Timeout handling
if grep -q "timeout\|setTimeout\|asyncio.timeout" "$EXECUTOR_FILE"; then
  echo "✓ Timeout handling present"
else
  echo "⚠️  Warning: No timeout handling detected"
fi

# Retry logic
if grep -q "retry\|Retry\|retries" "$EXECUTOR_FILE"; then
  echo "✓ Retry logic present"
else
  echo "⚠️  Warning: No retry logic detected"
fi

echo ""
echo "================================================"

if [ $ERRORS -eq 0 ]; then
  echo "✓ Validation passed!"
  echo ""
  echo "Executor structure is valid."
  exit 0
else
  echo "❌ Validation failed with $ERRORS error(s)"
  echo ""
  echo "Please fix the errors above."
  exit 1
fi
