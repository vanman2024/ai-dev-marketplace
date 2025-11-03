---
description: Validate training data quality and format
argument-hint: [dataset-path]
allowed-tools: Bash, Read, Grep, Glob
---

## Security Requirements

**CRITICAL:** All generated files must follow security rules:

@docs/security/SECURITY-RULES.md

**Key requirements:**
- Never hardcode API keys or secrets
- Use placeholders: `your_service_key_here`
- Protect `.env` files with `.gitignore`
- Create `.env.example` with placeholders only
- Document key acquisition for users

**Arguments**: $ARGUMENTS

Goal: Validate machine learning training data for quality, format consistency, and structural integrity, providing comprehensive statistics and issue reporting.

Core Principles:
- Detect data characteristics, don't assume format
- Validate comprehensively across multiple dimensions
- Provide actionable feedback with clear statistics
- Support common ML data formats (CSV, JSON, Parquet, NPY)

Phase 1: Discovery
Goal: Parse arguments and detect dataset format

Actions:
- Extract dataset path from $ARGUMENTS
- Verify dataset exists and is accessible
- Detect file format based on extension
- Example: !{bash test -e "$ARGUMENTS" && echo "Found: $ARGUMENTS" || echo "Error: Dataset not found"}
- List dataset files if directory provided
- Example: !{bash if [ -d "$ARGUMENTS" ]; then ls -lh "$ARGUMENTS"; fi}

Phase 2: Format Detection
Goal: Identify dataset type and structure

Actions:
- Determine file type (CSV, JSON, Parquet, NPY, etc.)
- Check if single file or directory of files
- Example: !{bash file "$ARGUMENTS"}
- For CSV: Detect delimiter, quote character, header presence
- For JSON: Check if JSONL, nested, or array format
- Report detected format to user

Phase 3: Data Validation
Goal: Run comprehensive validation checks

Actions:

**For CSV files:**
- Check header row exists and is valid
- Count rows and columns
- Example: !{bash head -1 "$ARGUMENTS" && wc -l "$ARGUMENTS"}
- Detect column data types
- Check for missing values per column
- Identify duplicate rows
- Validate delimiter consistency
- Example: !{bash awk -F',' '{print NF}' "$ARGUMENTS" | sort -u}

**For JSON files:**
- Validate JSON syntax
- Example: !{bash python3 -m json.tool "$ARGUMENTS" > /dev/null && echo "Valid JSON" || echo "Invalid JSON"}
- Check schema consistency across records
- Count total records
- Identify missing or null fields

**For Parquet files:**
- Use Python to read and validate
- Example: !{bash python3 -c "import pandas as pd; df=pd.read_parquet('$ARGUMENTS'); print(f'Rows: {len(df)}, Cols: {len(df.columns)}')"}
- Check schema and data types
- Report compression and size

**For NumPy files:**
- Validate array shape and dtype
- Example: !{bash python3 -c "import numpy as np; arr=np.load('$ARGUMENTS'); print(f'Shape: {arr.shape}, Dtype: {arr.dtype}')"}
- Check for NaN or inf values

Phase 4: Quality Checks
Goal: Assess data quality metrics

Actions:
- Calculate basic statistics (min, max, mean for numeric columns)
- Identify outliers or anomalous values
- Check class distribution for classification datasets
- Detect data imbalance issues
- Validate value ranges are reasonable
- Check file size and memory requirements
- Example: !{bash du -h "$ARGUMENTS"}

Phase 5: Issue Reporting
Goal: Summarize validation results and flag problems

Actions:
- Report dataset statistics:
  - Total records/rows
  - Number of features/columns
  - Data types per column
  - Missing value counts
  - File size
- Flag critical issues:
  - Format errors
  - Missing values exceeding threshold
  - Duplicate records
  - Class imbalance
  - Invalid data types
- Provide warnings for potential problems:
  - Small dataset size
  - High missing value percentage
  - Inconsistent formats
- Suggest fixes for identified issues

Phase 6: Summary
Goal: Present comprehensive validation report

Actions:
- Display validation summary:
  - Dataset: [path]
  - Format: [detected format]
  - Status: PASS/FAIL
  - Records: [count]
  - Features: [count]
  - Issues Found: [count]
- List all issues with severity (CRITICAL/WARNING/INFO)
- Recommend next steps:
  - If PASS: Ready for training
  - If FAIL: List required fixes
  - Suggest data cleaning commands if applicable
- Save validation report to file if requested
- Example: !{bash echo "Validation complete for $ARGUMENTS"}
