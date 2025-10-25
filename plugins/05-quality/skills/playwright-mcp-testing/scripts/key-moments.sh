#!/bin/bash

# Playwright MCP Integration - KEY MOMENTS Script
# This script triggers automated testing at critical workflow moments

set -e

echo "🤖 Playwright MCP Automation - KEY MOMENTS"
echo "=========================================="

# Function to check if MCP server is running
check_mcp_server() {
    echo "🔍 Checking MCP server status..."
    if curl -s http://localhost:3000/health > /dev/null 2>&1; then
        echo "✅ MCP server is running"
        return 0
    else
        echo "⚠️  MCP server not running, starting..."
        npx @executeautomation/playwright-mcp-server &
        sleep 5
        return 1
    fi
}

# Function to run tests based on trigger
run_tests_for_moment() {
    local moment="$1"
    local additional_args="${2:-}"
    
    echo "🎯 Triggering tests for moment: $moment"
    
    case "$moment" in
        "pre-commit")
            echo "🔄 Running pre-commit validation..."
            node test-automation.js commit
            ;;
        "pre-push")
            echo "🚀 Running pre-push smoke tests..."
            node test-automation.js smoke
            ;;
        "deployment")
            echo "🌐 Running deployment validation..."
            node test-automation.js deploy
            ;;
        "feature-complete")
            echo "🎉 Running feature completion tests..."
            node test-automation.js full
            ;;
        "nightly")
            echo "🌙 Running nightly regression tests..."
            node test-automation.js full --extended
            ;;
        "manual")
            echo "👤 Running manual test trigger..."
            node test-automation.js ${additional_args:-full}
            ;;
        *)
            echo "❓ Unknown moment: $moment"
            echo "Available moments: pre-commit, pre-push, deployment, feature-complete, nightly, manual"
            exit 1
            ;;
    esac
}

# Main execution
main() {
    # Check arguments
    if [ $# -eq 0 ]; then
        echo "Usage: $0 <moment> [additional_args]"
        echo "Moments: pre-commit, pre-push, deployment, feature-complete, nightly, manual"
        exit 1
    fi
    
    local moment="$1"
    local additional_args="${2:-}"
    
    # Ensure MCP server is running
    check_mcp_server
    
    # Run the appropriate tests
    run_tests_for_moment "$moment" "$additional_args"
    
    echo "✅ Test execution completed for moment: $moment"
}

# Execute if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

# INTEGRATION EXAMPLES:
# 
# 1. Git Hooks:
#    echo "./key-moments.sh pre-commit" > .git/hooks/pre-commit
#    echo "./key-moments.sh pre-push" > .git/hooks/pre-push
#
# 2. CI/CD Pipeline:
#    - name: Run deployment tests
#      run: ./key-moments.sh deployment
#
# 3. Manual trigger:
#    ./key-moments.sh manual "api-only"
#
# 4. Cron job:
#    0 2 * * * /path/to/key-moments.sh nightly
#
# 5. Feature completion:
#    ./key-moments.sh feature-complete