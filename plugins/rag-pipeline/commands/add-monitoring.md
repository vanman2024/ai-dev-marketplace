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
- Provide clear setup instructions and API key guidance

Phase 1: Platform Selection
Goal: Determine which monitoring platform to configure

Actions:
- Check if $ARGUMENTS specifies a monitoring platform
- If not provided, ask user which monitoring platform:

  "Which observability platform would you like to configure?

  **Managed Platforms:**
  - LangSmith (LangChain native, 5K traces/month free tier)
  - LlamaCloud (LlamaIndex native, free tier available)

  **Open Source/Custom:**
  - Custom (Python logging + metrics, completely free)

  Enter platform name (langsmith, llamacloud, or custom):"

- Store selection for use in subsequent phases

Phase 2: Fetch Documentation
Goal: Load platform-specific setup documentation

Actions:
Fetch docs based on selection using WebFetch in parallel:

LangSmith:
- https://docs.langchain.com/langsmith/home
- https://docs.smith.langchain.com/tracing
- https://docs.smith.langchain.com/evaluation

LlamaCloud:
- https://docs.cloud.llamaindex.ai/
- https://docs.llamaindex.ai/en/stable/module_guides/observability/

Custom:
- https://docs.python.org/3/howto/logging.html
- https://prometheus.io/docs/introduction/overview/

Wait for all fetches to complete.

Phase 3: Project Discovery
Goal: Understand existing RAG pipeline structure

Actions:
- Detect project type: !{bash test -f requirements.txt && echo "python" || test -f package.json && echo "node"}
- Check for existing RAG components: !{bash find . -name "*retrieval*" -o -name "*generation*" -o -name "*query*" 2>/dev/null | head -10}
- Identify framework: Check for LangChain (langchain imports) or LlamaIndex (llama_index imports)
- Locate or create monitoring config directory
- Check if monitoring dependencies already installed

Phase 4: Implementation
Goal: Install dependencies and configure monitoring platform

Actions:

Task(description="Setup RAG pipeline monitoring", subagent_type="general-purpose", prompt="Configure $ARGUMENTS monitoring for RAG pipeline based on fetched documentation.

Platform: $ARGUMENTS (or from user question)

Implementation:

1. Core Monitoring (src/monitoring/):
   - tracer.py: initialize_tracer(), trace_retrieval(), trace_generation(), trace_pipeline()
   - metrics.py: track_latency(), track_cost(), track_quality(), export_metrics()
   - callbacks.py: CustomCallback/Handler for chosen platform
   - logger.py: structured_log(), error_tracking(), performance_log()

2. Platform-Specific Setup:

   LangSmith:
   - Install: langsmith, langchain-core
   - Config: LANGCHAIN_TRACING_V2=true, LANGCHAIN_API_KEY, LANGCHAIN_PROJECT
   - Callbacks: LangChainTracer integration
   - Features: automatic tracing, evaluation runs, dataset testing

   LlamaCloud:
   - Install: llama-cloud, llama-index-callbacks-observability
   - Config: LLAMA_CLOUD_API_KEY, LLAMA_CLOUD_PROJECT_NAME
   - Callbacks: LlamaCloudObservabilityHandler
   - Features: trace visualization, performance metrics, query analytics

   Custom:
   - Install: prometheus-client, structlog (Python) or pino, prometheus-client (Node)
   - Setup: Custom metrics collector, log aggregation, trace context
   - Export: /metrics endpoint, structured JSON logs
   - Features: full control, no vendor lock-in, free

3. Instrumentation (src/monitoring/instrumentation/):
   - retrieval_instrumentation.py: wrap retrieval calls, track chunk count, measure latency
   - generation_instrumentation.py: wrap LLM calls, count tokens, track costs, measure TTFT
   - pipeline_instrumentation.py: end-to-end tracing, context flow, error capture

4. Metrics Configuration (config/monitoring.py):
   - Latency thresholds: retrieval (<500ms), generation (<2s), total (<3s)
   - Cost tracking: token usage, API costs, embeddings costs
   - Quality metrics: relevance score, citation accuracy, response quality
   - Alerting rules: error rates, latency spikes, cost overruns

5. Dashboard Setup (monitoring/dashboards/):
   - rag_metrics.json: Grafana/platform dashboard config
   - metrics.md: How to interpret metrics
   - alerts.yaml: Alert definitions

6. Testing (tests/test_monitoring.py):
   - Test tracer initialization
   - Verify metrics collection
   - Test cost tracking accuracy
   - Validate trace context propagation
   - Sample query with full instrumentation

7. Environment (.env.example additions):
   - LANGSMITH_API_KEY, LANGSMITH_PROJECT (LangSmith)
   - LLAMA_CLOUD_API_KEY, LLAMA_CLOUD_PROJECT (LlamaCloud)
   - ENABLE_MONITORING, LOG_LEVEL, METRICS_PORT (Custom)

8. Examples:
   - examples/monitored_rag_query.py: RAG query with full tracing
   - examples/cost_tracking.py: Track costs across multiple queries
   - examples/quality_metrics.py: Measure and log quality scores

9. Documentation (docs/monitoring.md):
   - Setup instructions per platform
   - How to view traces/metrics
   - Cost tracking interpretation
   - Troubleshooting common issues
   - Best practices for production monitoring

Best Practices:
- Sample traces in production (10-20% sampling)
- Tag traces with user_id, session_id, query_type
- Track both technical (latency) and business (quality) metrics
- Set up alerts for anomalies
- Export metrics for long-term analysis

Deliverable: Complete monitoring setup with instrumentation, metrics collection, and documentation.")

Phase 5: API Key Configuration
Goal: Guide user through API key setup

Actions:
- Display platform-specific setup instructions:

  LangSmith:
  1. Create account: https://smith.langchain.com
  2. Get API key: Settings → API Keys
  3. Add to .env:
     LANGCHAIN_TRACING_V2=true
     LANGCHAIN_API_KEY=your_key_here
     LANGCHAIN_PROJECT=rag-pipeline
  4. Free tier: 5,000 traces/month

  LlamaCloud:
  1. Create account: https://cloud.llamaindex.ai
  2. Get API key: Dashboard → API Keys
  3. Add to .env:
     LLAMA_CLOUD_API_KEY=your_key_here
     LLAMA_CLOUD_PROJECT_NAME=rag-pipeline
  4. Free tier available

  Custom:
  1. No API keys needed
  2. Configure log output directory
  3. Optionally set up Prometheus endpoint
  4. Completely free

- Check if .env file exists: !{bash test -f .env && echo "exists" || echo "create"}
- If missing, remind user to copy from .env.example

Phase 6: Test Monitoring
Goal: Verify monitoring works with sample RAG queries

Actions:
- Run monitored query example: !{bash python3 examples/monitored_rag_query.py 2>&1 | head -50}
- Verify trace/log output appears
- Check metrics collection: !{bash python3 -c "from src.monitoring.metrics import track_latency; track_latency('test', 100); print('Metrics OK')" 2>&1}
- Test cost tracking: !{bash python3 examples/cost_tracking.py 2>&1 | head -30}
- Display sample metrics output
- Provide platform-specific viewing instructions:
  * LangSmith: Visit https://smith.langchain.com/projects
  * LlamaCloud: Visit https://cloud.llamaindex.ai/traces
  * Custom: Check logs/ directory or /metrics endpoint

Phase 7: Summary
Goal: Present monitoring capabilities and next steps

Actions:
Display:
- Monitoring Platform: [from selection]
- Components instrumented: Retrieval, Generation, End-to-End Pipeline
- Metrics tracked: Latency, Cost, Quality, Error Rate
- Key files: tracer.py, metrics.py, instrumentation/

Monitoring Capabilities:
1. Latency Tracking:
   - Retrieval time (vector search + reranking)
   - Generation time (TTFT + total)
   - End-to-end pipeline latency

2. Cost Tracking:
   - Token usage per query
   - Embedding costs
   - LLM API costs
   - Total cost per session

3. Quality Metrics:
   - Retrieval relevance scores
   - Citation accuracy
   - Response coherence
   - User feedback integration

4. Error Monitoring:
   - Failed queries
   - Timeout events
   - API errors
   - Fallback triggers

Next Steps:
1. Configure API keys in .env (if using LangSmith/LlamaCloud)
2. Run sample monitored query: python examples/monitored_rag_query.py
3. View traces in platform dashboard
4. Set up alerts for production
5. Monitor costs and optimize based on metrics
6. A/B test different retrieval strategies using metrics

Platform Links:
- LangSmith: https://smith.langchain.com
- LlamaCloud: https://cloud.llamaindex.ai
- Prometheus: http://localhost:9090/metrics (Custom)

Best Practices:
- Start with 100% sampling in dev, 10-20% in production
- Tag all traces with query_type and user_id
- Set up alerts for latency >3s and error_rate >5%
- Review quality metrics weekly
- Export cost data for budget planning
- Use sampling to reduce monitoring overhead

Resources:
- LangSmith Docs: https://docs.langchain.com/langsmith/home
- LlamaCloud Docs: https://docs.cloud.llamaindex.ai
- Observability Guide: docs/monitoring.md
