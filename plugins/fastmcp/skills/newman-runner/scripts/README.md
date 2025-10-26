# Newman Runner Scripts

This directory contains functional scripts for running and analyzing Newman (Postman CLI) tests.

## Scripts

### `run-newman.sh`
**Purpose:** Execute Newman tests on Postman collections with comprehensive reporting

**Usage:**
```bash
./run-newman.sh <collection.json> [environment.json]
```

**Features:**
- Runs Newman with CLI, JSON, and HTML reporters
- Timestamps all output files
- Supports environment variables
- Configurable iteration count and delays

**Output:**
- `newman-results/results-TIMESTAMP.json` - Machine-readable results
- `newman-results/report-TIMESTAMP.html` - Human-readable HTML report

### `analyze-newman-results.py`
**Purpose:** Parse and analyze Newman JSON output to extract test metrics

**Usage:**
```bash
./analyze-newman-results.py <newman-results.json>
```

**Features:**
- Calculates pass/fail rates for requests and assertions
- Lists all failed assertions with details
- Provides clear summary of test results
- Exit code 0 for success, 1 for failures

**Output:**
- Formatted summary to stdout
- Exit code for CI/CD integration

### `validate-collection.sh`
**Purpose:** Validate Postman collection structure before running tests

**Usage:**
```bash
./validate-collection.sh <collection.json>
```

**Features:**
- Checks JSON validity
- Verifies required collection fields
- Counts collection items
- Quick validation before test execution

**Requirements:**
- `jq` for JSON processing

## Dependencies

All scripts require:
- **Newman:** `npm install -g newman`
- **Python 3.7+:** For analysis script
- **jq:** For collection validation

## Examples

See `../examples/` directory for complete usage examples.
