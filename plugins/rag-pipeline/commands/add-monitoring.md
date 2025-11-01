---
description: Add observability (LangSmith/LlamaCloud integration)
argument-hint: [platform]
allowed-tools: Task, Read, Write, Edit, Bash, AskUserQuestion, Glob, Grep, WebFetch
---

**Arguments**: $ARGUMENTS

Goal: Add comprehensive observability and monitoring to RAG pipeline with cost tracking, latency monitoring, and quality metrics

Core Principles:
- Highlight free and open-source options (Custom/OSS solutions)
- Fetch latest vendor documentation for chosen platform
- Implement cost tracking, latency monitoring, quality metrics
- Test monitoring with sample queries

Phase 1: Platform Selection
Goal: Determine which monitoring platform to configure

Actions:
- Check if $ARGUMENTS specifies a monitoring platform
- If not provided, use AskUserQuestion:

  "Which observability platform would you like to configure?

  **Managed Platforms:**
  - LangSmith (LangChain native, 5K traces/month free tier)
  - LlamaCloud (LlamaIndex native, free tier available)

  **Open Source/Custom:**
  - Custom (Python logging + metrics, completely free)

  Enter platform name (langsmith, llamacloud, or custom):"

- Store selection for subsequent phases

Phase 2: Fetch Documentation
Goal: Load platform-specific setup documentation

Actions:
Fetch docs based on selection using WebFetch:

LangSmith:
- WebFetch: https://docs.langchain.com/langsmith/home
- WebFetch: https://docs.smith.langchain.com/tracing

LlamaCloud:
- WebFetch: https://docs.cloud.llamaindex.ai/
- WebFetch: https://docs.llamaindex.ai/en/stable/module_guides/observability/

Custom:
- WebFetch: https://docs.python.org/3/howto/logging.html
- WebFetch: https://prometheus.io/docs/introduction/overview/

Phase 3: Project Discovery
Goal: Understand existing RAG pipeline structure

Actions:
- Detect project type: !{bash test -f requirements.txt && echo "python" || test -f package.json && echo "node"}
- Find RAG components: !{bash find . -name "*retrieval*" -o -name "*generation*" -o -name "*query*" 2>/dev/null | head -10}
- Identify framework: Check for LangChain or LlamaIndex imports
- Check existing monitoring: !{bash grep -r "LANGCHAIN_TRACING\|LlamaCloud\|prometheus" . 2>/dev/null | head -5}

Phase 4: Implementation
Goal: Install dependencies and configure monitoring platform

Actions:

Task(description="Setup RAG pipeline monitoring", subagent_type="rag-pipeline:rag-tester", prompt="You are the rag-tester agent. Configure $ARGUMENTS monitoring for RAG pipeline based on fetched documentation.

Platform: $ARGUMENTS (or from user question)
Project type: [from Phase 3]
Framework: [from Phase 3]

Using the documentation fetched in Phase 2, implement:

1. Core Monitoring Components:
   - Tracer initialization and context propagation
   - Metrics collection (latency, cost, quality)
   - Platform-specific callbacks/handlers
   - Structured logging

2. Instrumentation:
   - Wrap retrieval calls with tracing
   - Wrap LLM calls with cost tracking
   - End-to-end pipeline monitoring

3. Configuration:
   - Install required packages
   - Setup API keys in .env (ask user if needed)
   - Configure platform-specific settings
   - Set latency/cost thresholds

4. Testing:
   - Create test file to verify monitoring
   - Run sample query with full instrumentation
   - Verify traces appear in platform dashboard

5. Documentation:
   - Add setup instructions to README
   - Document metrics and how to interpret them

Deliverable: Working monitoring setup with test results")

Phase 5: Validation
Goal: Verify monitoring is working correctly

Actions:
- Run test query: !{bash python -m tests.test_monitoring 2>&1 || echo "manual-test-needed"}
- Check for traces/metrics in platform dashboard
- Verify cost tracking is accurate
- Test latency measurement

Phase 6: Summary
Goal: Display setup summary and next steps

Actions:
Display summary:
- Platform configured: [platform name]
- Monitoring enabled for: [components]
- Metrics tracked: latency, cost, quality, errors
- Dashboard URL: [platform-specific link]
- Test results: [pass/fail status]

Next steps:
- Review dashboard: [platform URL]
- Configure alerts for: errors, latency spikes, cost overruns
- Set up evaluation datasets: /rag-pipeline:test
- Monitor production queries and iterate on retrieval quality

Important Notes:
- Adapts to user's platform choice (LangSmith, LlamaCloud, or Custom)
- Fetches vendor docs for latest API changes
- Tests monitoring with sample queries before completing
- Provides clear next steps for dashboard setup
- Highlights free tiers and open-source options
