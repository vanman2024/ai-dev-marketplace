#!/usr/bin/env python3
"""Analyze Newman test results from JSON output."""

import json
import sys
from pathlib import Path

def analyze_newman_results(results_file):
    """Parse and analyze Newman JSON results."""
    with open(results_file) as f:
        data = json.load(f)

    run = data.get('run', {})
    stats = run.get('stats', {})

    # Extract statistics
    total_requests = stats.get('requests', {}).get('total', 0)
    failed_requests = stats.get('requests', {}).get('failed', 0)
    total_assertions = stats.get('assertions', {}).get('total', 0)
    failed_assertions = stats.get('assertions', {}).get('failed', 0)

    # Calculate metrics
    pass_rate = ((total_assertions - failed_assertions) / total_assertions * 100) if total_assertions > 0 else 0

    print(f"\n{'='*60}")
    print(f"Newman Test Results")
    print(f"{'='*60}\n")

    print(f"Requests:")
    print(f"  Total: {total_requests}")
    print(f"  Failed: {failed_requests}")
    print(f"  Success Rate: {((total_requests - failed_requests) / total_requests * 100):.1f}%\n")

    print(f"Assertions:")
    print(f"  Total: {total_assertions}")
    print(f"  Failed: {failed_assertions}")
    print(f"  Pass Rate: {pass_rate:.1f}%\n")

    # Show failures
    if failed_assertions > 0:
        print(f"Failed Assertions:")
        for execution in run.get('executions', []):
            for assertion in execution.get('assertions', []):
                if assertion.get('error'):
                    request_name = execution.get('item', {}).get('name', 'Unknown')
                    error_msg = assertion.get('error', {}).get('message', 'Unknown error')
                    print(f"  ❌ {request_name}: {error_msg}")
        print()

    # Overall status
    if failed_assertions == 0 and failed_requests == 0:
        print("✅ All tests passed!")
        return 0
    else:
        print("❌ Some tests failed")
        return 1

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: analyze-newman-results.py <results.json>")
        sys.exit(1)

    sys.exit(analyze_newman_results(sys.argv[1]))
