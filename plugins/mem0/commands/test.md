---
description: Test Mem0 functionality end-to-end (setup, operations, performance, security)
argument-hint: none
allowed-tools: Task, Read, Bash(*), Glob, Grep, Skill
---
## Available Skills

This commands has access to the following skills from the mem0 plugin:

- **memory-design-patterns**: Best practices for memory architecture design including user vs agent vs session memory patterns, vector vs graph memory tradeoffs, retention strategies, and performance optimization. Use when designing memory systems, architecting AI memory layers, choosing memory types, planning retention strategies, or when user mentions memory architecture, user memory, agent memory, session memory, memory patterns, vector storage, graph memory, or Mem0 architecture.
- **memory-optimization**: Performance optimization patterns for Mem0 memory operations including query optimization, caching strategies, embedding efficiency, database tuning, batch operations, and cost reduction for both Platform and OSS deployments. Use when optimizing memory performance, reducing costs, improving query speed, implementing caching, tuning database performance, analyzing bottlenecks, or when user mentions memory optimization, performance tuning, cost reduction, slow queries, caching, or Mem0 optimization.
- **supabase-integration**: Complete Supabase setup for Mem0 OSS including PostgreSQL schema with pgvector for embeddings, memory_relationships tables for graph memory, RLS policies for user/tenant isolation, performance indexes, connection pooling, and backup/migration strategies. Use when setting up Mem0 with Supabase, configuring OSS memory backend, implementing memory persistence, migrating from Platform to OSS, or when user mentions Mem0 Supabase, memory database, pgvector for Mem0, memory isolation, or Mem0 backup.

**To use a skill:**
```
!{skill skill-name}
```

Use skills when you need:
- Domain-specific templates and examples
- Validation scripts and automation
- Best practices and patterns
- Configuration generators

Skills provide pre-built resources to accelerate your work.

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

Goal: Comprehensively test Mem0 installation, operations, performance, and security.

Core Principles:
- Test all memory operations
- Validate performance benchmarks
- Check security configuration
- Provide actionable recommendations

Phase 1: Setup Validation
Goal: Verify Mem0 is properly initialized

Actions:
- Check Mem0 packages are installed
- Verify configuration files exist
- Check environment variables are set (MEM0_API_KEY in ~/.bashrc)
- Validate deployment mode (Platform, OSS, or MCP)
- If MCP: Verify OpenMemory server is running at http://localhost:8765
- If Platform: Verify MEM0_API_KEY is loaded from ~/.bashrc
- If OSS: Verify Supabase connection and pgvector extension

Phase 2: Operations Testing
Goal: Test all memory operations work

Actions:

Launch the mem0-verifier agent to test Mem0 operations.

Provide the agent with:
- Test scope: Comprehensive
- Requirements:
  - Test add memory (single and batch)
  - Test search memory (various queries)
  - Test update memory
  - Test delete memory
  - Test get memory by ID
  - If graph memory: Test relationships
  - If webhooks: Test delivery
  - Verify error handling
  - Check response formats
- Expected output: Test report with pass/fail status

Phase 3: Performance Benchmarking
Goal: Measure memory operation performance

Actions:
- Measure latency for each operation:
  - Add memory (target: < 500ms)
  - Search memory (target: < 200ms)
  - Update memory (target: < 300ms)
- Test concurrent operations
- Check database performance (if OSS with Supabase)
- Identify bottlenecks

Phase 4: Security Audit
Goal: Validate security configuration

Actions:
- Check for exposed API keys in code
- Verify environment variables not hardcoded
- If OSS: Test RLS policies (user isolation)
- Check data encryption
- Validate access controls
- Test GDPR compliance features (delete user data)

Phase 5: Summary
Goal: Present comprehensive test report

Actions:
- Display test results:
  - Setup validation: ✅ Pass / ❌ Fail
  - Memory operations: [X/Y passed]
  - Performance benchmarks: [Latency results]
  - Security audit: [Findings]
- Show issues found:
  - Critical issues (fix immediately)
  - Warnings (should address)
  - Recommendations (nice to have)
- Provide fixes for failures:
  - Exact steps to resolve
  - Code changes needed
  - Configuration adjustments
- Provide next steps:
  - Fix critical issues
  - Optimize performance bottlenecks
  - Address security findings
  - Re-run test after fixes
- Provide documentation:
  - Platform FAQs: https://docs.mem0.ai/platform/faqs
  - OSS troubleshooting: https://docs.mem0.ai/open-source/overview
