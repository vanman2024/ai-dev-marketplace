---
description: Analyze existing project specs for completeness and identify gaps
argument-hint: (optional)
allowed-tools: Task, Read, Write, Bash, Glob, Grep, TodoWrite
---

**Arguments**: $ARGUMENTS

Goal: Comprehensively analyze all existing project specification files to identify gaps, incomplete sections, missing features, and provide actionable recommendations for improvement.

Core Principles:
- Discover all specs systematically
- Analyze each spec independently in parallel
- Consolidate findings into actionable gaps
- Provide clear recommendations

Phase 1: Discovery
Goal: Identify all existing specification files

Actions:
- Create todo list for tracking analysis progress
- Search for all specification files following naming convention
- Count total specs found
- Validate specs directory exists

!{bash if [ -d "specs" ]; then echo "Specs directory found"; else echo "ERROR: specs directory not found"; exit 1; fi}

!{bash find specs -type f -name '[0-9][0-9][0-9]-*.md' 2>/dev/null | sort}

Parse discovered specs and prepare for parallel analysis.

If no specs found, report that project has no specs to analyze.

Phase 2: Parallel Analysis
Goal: Launch spec-analyzer agent for each discovered spec file

Actions:

For EACH spec file discovered in Phase 1, launch a spec-analyzer agent in PARALLEL.

Task(description="Analyze spec completeness", subagent_type="spec-analyzer", prompt="You are the spec-analyzer agent. Analyze the specification file for completeness and quality.

Target: $ARGUMENTS

Your analysis should evaluate:
- Completeness: Are all sections filled out? Any TODO or placeholder text?
- Clarity: Is the spec clear and unambiguous?
- Technical detail: Sufficient implementation guidance?
- Requirements coverage: Are acceptance criteria defined?
- Dependencies: Are dependencies on other specs documented?
- Testability: Can this spec be validated/tested?

Deliverable: Return JSON analysis:
{
  \"spec_file\": \"filename\",
  \"completeness_score\": 0-100,
  \"missing_sections\": [list],
  \"incomplete_sections\": [list with details],
  \"clarity_issues\": [list],
  \"technical_gaps\": [list],
  \"recommendations\": [list]
}")

Wait for ALL spec-analyzer agents to complete before proceeding.

Update todos as each analysis completes.

Phase 3: Consolidation
Goal: Aggregate all analysis results and identify patterns

Actions:
- Collect all JSON results from spec-analyzer agents
- Calculate aggregate metrics:
  - Average completeness score across all specs
  - Total missing sections
  - Total incomplete sections
  - Common clarity issues
  - Common technical gaps
- Identify specs requiring immediate attention (score < 60)
- Identify specs that are well-documented (score >= 80)
- Cross-reference dependencies between specs
- Prioritize gaps by impact

Phase 4: Gap Analysis Report
Goal: Generate comprehensive gap analysis document

Actions:
- Create gaps-analysis.json with structure:
  {
    "analysis_date": "YYYY-MM-DD",
    "total_specs": N,
    "avg_completeness": X,
    "critical_gaps": [],
    "incomplete_specs": [],
    "well_documented_specs": [],
    "missing_features": [],
    "recommendations": []
  }
- Write report to project root or specs directory
- Include severity levels: CRITICAL, HIGH, MEDIUM, LOW

!{bash echo "Gap analysis saved to gaps-analysis.json"}

Phase 5: Summary and Recommendations
Goal: Present actionable findings to user

Actions:
- Mark all todos complete
- Display comprehensive summary:

**Analysis Complete**

Total Specs Analyzed: [N]
Average Completeness: [X%]

**Critical Issues** (requires immediate attention):
- [List specs with score < 60]
- [Key missing sections]

**Incomplete Specs** (needs work):
- [List specs with score 60-79]

**Well-Documented Specs** (reference examples):
- [List specs with score >= 80]

**Top Missing Features/Gaps**:
1. [Gap 1 with affected specs]
2. [Gap 2 with affected specs]
3. [Gap 3 with affected specs]

**Recommendations**:
1. [Priority 1 action]
2. [Priority 2 action]
3. [Priority 3 action]

**Next Steps**:
- Review gaps-analysis.json for detailed breakdown
- Prioritize specs needing completion
- Consider creating new specs for missing features
- Update incomplete sections following well-documented examples
