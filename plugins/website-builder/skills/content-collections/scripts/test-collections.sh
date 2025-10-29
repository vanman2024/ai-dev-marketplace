#!/bin/bash
# test-collections.sh
# Run comprehensive tests on content collections

set -e

PROJECT_PATH="${1:-.}"
CONTENT_DIR="$PROJECT_PATH/src/content"
CONFIG_FILE="$CONTENT_DIR/config.ts"

echo "Testing content collections in: $PROJECT_PATH"
echo ""

# Initialize counters
TESTS_PASSED=0
TESTS_FAILED=0
TOTAL_TESTS=0

# Helper function to run test
run_test() {
  local test_name="$1"
  local test_command="$2"

  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  echo -n "Testing: $test_name... "

  if eval "$test_command" &> /dev/null; then
    echo "✓ PASS"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo "✗ FAIL"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

# Test 1: Check if content directory exists
run_test "Content directory exists" "[ -d '$CONTENT_DIR' ]"

# Test 2: Check if config.ts exists
run_test "Content config exists" "[ -f '$CONFIG_FILE' ]"

# Test 3: Check if config has valid TypeScript syntax
if [ -f "$CONFIG_FILE" ]; then
  run_test "Config has valid imports" "grep -q 'import.*astro:content' '$CONFIG_FILE'"
  run_test "Config exports collections" "grep -q 'export const collections' '$CONFIG_FILE'"
fi

# Test 4: Check for collection directories
echo ""
echo "Checking collection directories..."
if [ -d "$CONTENT_DIR" ]; then
  COLLECTIONS=$(find "$CONTENT_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null || echo "")

  if [ -n "$COLLECTIONS" ]; then
    echo "Found collections:"
    echo "$COLLECTIONS" | while read -r collection; do
      collection_name=$(basename "$collection")
      echo "  - $collection_name"

      # Count content files in collection
      file_count=$(find "$collection" -name "*.md" -o -name "*.mdx" 2>/dev/null | wc -l)
      echo "    Files: $file_count"
    done
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "  No collection directories found"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TOTAL_TESTS=$((TOTAL_TESTS + 1))
fi

# Test 5: Validate frontmatter in all content files
echo ""
echo "Validating frontmatter..."
if [ -d "$CONTENT_DIR" ]; then
  CONTENT_FILES=$(find "$CONTENT_DIR" -name "*.md" -o -name "*.mdx" 2>/dev/null || echo "")

  if [ -n "$CONTENT_FILES" ]; then
    FRONTMATTER_TESTS=0
    FRONTMATTER_PASSED=0

    echo "$CONTENT_FILES" | while read -r file; do
      if [ -f "$file" ]; then
        FRONTMATTER_TESTS=$((FRONTMATTER_TESTS + 1))

        # Check if file has frontmatter
        if head -n 1 "$file" | grep -q "^---$"; then
          echo "  ✓ $file"
          FRONTMATTER_PASSED=$((FRONTMATTER_PASSED + 1))
        else
          echo "  ✗ $file (no frontmatter)"
        fi
      fi
    done

    if [ $FRONTMATTER_TESTS -eq $FRONTMATTER_PASSED ]; then
      TESTS_PASSED=$((TESTS_PASSED + 1))
    else
      TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
  fi
fi

# Test 6: Check TypeScript types generation
echo ""
TYPES_FILE="$PROJECT_PATH/.astro/types.d.ts"
run_test "TypeScript types generated" "[ -f '$TYPES_FILE' ]"

if [ -f "$TYPES_FILE" ]; then
  run_test "Types include collection entries" "grep -q 'CollectionEntry' '$TYPES_FILE'"
fi

# Test 7: Check for required dependencies
echo ""
echo "Checking dependencies..."
PACKAGE_JSON="$PROJECT_PATH/package.json"
if [ -f "$PACKAGE_JSON" ]; then
  run_test "zod installed" "grep -q '\"zod\"' '$PACKAGE_JSON'"
  run_test "astro installed" "grep -q '\"astro\"' '$PACKAGE_JSON'"
else
  echo "  Warning: package.json not found"
fi

# Test 8: Check Astro config
echo ""
ASTRO_CONFIG="$PROJECT_PATH/astro.config.mjs"
ASTRO_CONFIG_TS="$PROJECT_PATH/astro.config.ts"
if [ -f "$ASTRO_CONFIG" ] || [ -f "$ASTRO_CONFIG_TS" ]; then
  run_test "Astro config exists" "true"
else
  run_test "Astro config exists" "false"
fi

# Test 9: Performance check - count total content files
echo ""
echo "Performance metrics..."
if [ -d "$CONTENT_DIR" ]; then
  TOTAL_FILES=$(find "$CONTENT_DIR" -name "*.md" -o -name "*.mdx" 2>/dev/null | wc -l)
  echo "  Total content files: $TOTAL_FILES"

  if [ $TOTAL_FILES -gt 100 ]; then
    echo "  ⚠ Large collection detected. Consider:"
    echo "    - Implementing pagination"
    echo "    - Using getEntry() for single items"
    echo "    - Caching collection queries"
  fi
fi

# Test 10: Check for common issues
echo ""
echo "Checking for common issues..."

# Check for empty frontmatter
if [ -d "$CONTENT_DIR" ]; then
  EMPTY_FRONTMATTER=$(find "$CONTENT_DIR" -name "*.md" -o -name "*.mdx" 2>/dev/null | while read -r file; do
    if [ -f "$file" ]; then
      FRONTMATTER=$(awk '/^---$/{flag=!flag;next}flag' "$file")
      if [ -z "$FRONTMATTER" ]; then
        echo "$file"
      fi
    fi
  done)

  if [ -n "$EMPTY_FRONTMATTER" ]; then
    echo "  ⚠ Files with empty frontmatter:"
    echo "$EMPTY_FRONTMATTER" | sed 's/^/    /'
  fi
fi

# Summary
echo ""
echo "================================"
echo "Test Summary"
echo "================================"
echo "Total tests: $TOTAL_TESTS"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
  echo "✓ All tests passed!"
  exit 0
else
  echo "✗ Some tests failed. Please review the output above."
  exit 1
fi
