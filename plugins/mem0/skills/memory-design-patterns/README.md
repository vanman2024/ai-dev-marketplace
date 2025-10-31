# Memory Design Patterns Skill

**Version**: 1.0.0
**Plugin**: mem0
**Last Updated**: 2025-10-27

## Overview

This skill provides comprehensive guidance on designing production-ready memory architectures for AI applications using Mem0. It covers memory types, storage backends, retention strategies, performance optimization, and cost management.

## What This Skill Provides

### 1. Memory Type Guidance
- **User Memory**: Persistent preferences and profile data
- **Agent Memory**: Agent-specific knowledge and capabilities
- **Session Memory**: Temporary conversation context
- Decision frameworks for choosing the right memory type

### 2. Storage Architecture Patterns
- **Vector Memory**: Fast semantic search for preferences and unstructured data
- **Graph Memory**: Complex entity relationships and multi-hop queries
- **Hybrid Approach**: Progressive complexity from vector to graph
- Decision tools for architecture selection

### 3. Retention Strategies
- Memory lifecycle management
- Archival and cleanup policies
- GDPR compliance patterns
- Cost optimization through retention

### 4. Performance Optimization
- Query performance analysis
- Caching strategies
- Search optimization techniques
- Batch operation patterns

### 5. Cost Management
- Cost analysis and breakdown
- Optimization recommendations
- ROI calculation frameworks
- Budget monitoring tools

### 6. Security & Compliance
- Data isolation patterns
- GDPR/HIPAA compliance
- Encryption strategies
- Audit logging

## Directory Structure

```
memory-design-patterns/
├── SKILL.md                          # Main skill instructions
├── README.md                         # This file
├── scripts/                          # Functional helper scripts
│   ├── generate-retention-policy.sh  # Create retention policies
│   ├── analyze-retention.sh          # Analyze memory age/access
│   ├── analyze-memory-performance.sh # Performance profiling
│   ├── analyze-memory-costs.sh       # Cost analysis
│   ├── deduplicate-memories.sh       # Find/remove duplicates
│   ├── audit-memory-security.sh      # Security compliance check
│   ├── suggest-memory-type.sh        # Memory type advisor
│   └── suggest-storage-architecture.sh # Architecture advisor
├── templates/                        # Code templates
│   ├── multi-level-memory-pattern.py # Complete implementation
│   ├── vector-only-config.py         # Vector memory setup
│   ├── graph-memory-config.py        # Graph memory setup
│   └── retention-policy.yaml         # Retention configuration
└── examples/                         # Real-world examples
    └── customer-support-memory-architecture.md
```

## Quick Start

### 1. Choose Memory Type

```bash
./scripts/suggest-memory-type.sh "store user's dietary preferences"
```

Output:
```
Suggested Memory Type: USER
Confidence: high

Reasoning:
This appears to be persistent user-specific information that should
be retained across all sessions and agents.
```

### 2. Choose Storage Architecture

```bash
./scripts/suggest-storage-architecture.sh "chatbot that remembers preferences"
```

Output:
```
Suggested Architecture: VECTOR
Confidence: high

Why Vector Memory?
✓ Your use case focuses on semantic search and preferences
✓ No complex entity relationships detected
✓ Vector-only provides faster setup and lower complexity
```

### 3. Implement Memory Pattern

Use the multi-level memory pattern template:

```python
from templates.multi_level_memory_pattern import MultiLevelMemoryManager

manager = MultiLevelMemoryManager()

# Add user memory
manager.add_user_memory(
    "User prefers dark mode"
    user_id="alice"
)

# Get context
context = manager.get_multi_level_context(
    query="What are the user's preferences?"
    user_id="alice"
    agent_id="assistant"
    run_id="session_123"
)
```

### 4. Set Up Retention Policy

```bash
./scripts/generate-retention-policy.sh user 365
```

Creates: `retention-policy-user.yaml` with recommended settings.

### 5. Monitor Performance

```bash
./scripts/analyze-memory-performance.sh my_project
```

Output:
```
Average Query Time: 127ms
P99 Query Time: 520ms

Recommendations:
1. REDUCE SEARCH LIMIT (Impact: -30% query time)
2. ADD SEARCH FILTERS (Impact: -40% query time)
3. IMPLEMENT CACHING (Impact: -50% for cached)
```

### 6. Optimize Costs

```bash
./scripts/analyze-memory-costs.sh user_123 30
```

Output:
```
Current Monthly Cost: $54.27

Optimization Opportunities:
1. Deduplicate memories → Save $1.00/month
2. Archive old memories → Save $3.12/month
3. Use smaller embeddings → Save $9.70/month
4. Implement caching → Save $6.68/month

Total Potential Savings: $52.56/month (96.8% reduction)
```

## Use Cases

### Customer Support System
- User: Customer history and preferences
- Agent: Product knowledge and solutions
- Session: Current ticket context
- **Example**: `examples/customer-support-memory-architecture.md`

### Personal Assistant
- User: Preferences, schedules, relationships
- Agent: Assistant capabilities
- Session: Current task context
- **Pattern**: Multi-level with caching

### E-commerce Personalization
- User: Purchase history, preferences
- Agent: Product catalog knowledge
- Session: Current browsing session
- **Storage**: Vector (unless complex product relationships)

### Healthcare Assistant
- User: Patient profile, medical history
- Agent: Medical knowledge, protocols
- Session: Current consultation
- **Requirements**: HIPAA compliance, encryption

## Key Decision Frameworks

### When to Use Each Memory Type

```
User Memory:
  ✓ Persistent preferences
  ✓ Profile information
  ✓ Long-term context
  ✗ Temporary data

Agent Memory:
  ✓ Agent capabilities
  ✓ Domain knowledge
  ✓ Procedures/SOPs
  ✗ User-specific info

Session Memory:
  ✓ Current conversation
  ✓ Task context
  ✓ Temporary state
  ✗ Long-term storage
```

### Vector vs Graph Decision Matrix

| Criteria | Vector | Graph |
|----------|--------|-------|
| Semantic search | ★★★★★ | ★★★☆☆ |
| Relationships | ★☆☆☆☆ | ★★★★★ |
| Setup complexity | Low | High |
| Cost (10k memories) | $1-5/mo | $20-100/mo |
| Best for | Preferences, RAG | Knowledge graphs, orgs |

## Best Practices

### 1. Start Simple
- Begin with vector-only, user + session memories
- Add complexity only when needed
- Monitor actual usage patterns

### 2. Optimize Early
- Set retention policies from day 1
- Implement caching for frequently accessed data
- Use search filters to reduce query scope

### 3. Monitor Continuously
- Track memory growth rate
- Monitor costs weekly
- Set up performance alerts

### 4. Security First
- Always validate user_id
- Encrypt sensitive data
- Implement GDPR deletion
- Audit access logs

### 5. Test at Scale
- Load test with realistic data
- Verify isolation between users
- Test retention cleanup
- Validate backup/recovery

## Performance Benchmarks

### Query Latency Targets
- Chat applications: < 100ms
- RAG systems: < 200ms
- Knowledge queries: < 300ms

### Memory Limits
- User memories: 10-50 per user
- Agent memories: 50-200 per agent
- Session memories: 5-20 per session

### Search Result Limits
- Chat: 3-5 results
- RAG: 5-10 results
- Knowledge: 10-20 results

## Cost Optimization

### Low-Cost Setup (< $10/month)
- Vector-only storage
- Smaller embeddings (1536 dim)
- Aggressive caching (80%+ hit rate)
- Short retention (30-90 days)

### Production Setup ($20-50/month)
- Vector + optional graph
- Standard embeddings
- Moderate caching
- Balanced retention

### Enterprise Setup ($100+/month)
- Graph memory enabled
- High-quality embeddings
- Distributed caching
- Long retention + archival

## Troubleshooting

### Slow Queries
1. Run performance analyzer: `./scripts/analyze-memory-performance.sh`
2. Reduce search limit
3. Add filters
4. Implement caching

### High Costs
1. Run cost analyzer: `./scripts/analyze-memory-costs.sh`
2. Deduplicate memories
3. Archive old data
4. Use smaller embeddings

### Poor Search Results
1. Check embedding model quality
2. Verify memory content is descriptive
3. Add metadata for filtering
4. Consider hybrid search

### Memory Leakage
1. Run security audit: `./scripts/audit-memory-security.sh`
2. Review all queries for user_id filtering
3. Implement access logging
4. Check RLS policies

## Resources

### Templates
- `templates/multi-level-memory-pattern.py` - Complete implementation
- `templates/vector-only-config.py` - Simple vector setup
- `templates/graph-memory-config.py` - Graph memory setup
- `templates/retention-policy.yaml` - Retention configuration

### Scripts
All scripts in `scripts/` are fully functional (not placeholders):
- Retention policy generation
- Performance analysis
- Cost analysis
- Security auditing
- Architecture recommendations

### Examples
- `examples/customer-support-memory-architecture.md` - Complete support system

### External Documentation
- [Mem0 Docs](https://docs.mem0.ai)
- [Graph Memory Guide](https://docs.mem0.ai/features/graph-memory)
- [Performance Optimization](https://docs.mem0.ai/guides/optimization)

## Support

For issues or questions about this skill:
1. Review SKILL.md for detailed instructions
2. Check examples/ for real-world patterns
3. Run advisor scripts for recommendations
4. Consult Mem0 documentation

## Changelog

### Version 1.0.0 (2025-10-27)
- Initial release
- Complete memory type guidance
- Vector and graph architecture patterns
- 8 functional helper scripts
- 4 code templates
- 1 comprehensive example
- Retention strategy framework
- Performance optimization guide
- Cost management tools
- Security audit tooling

## License

Part of the ai-dev-marketplace mem0 plugin.

## Contributing

To improve this skill:
1. Add new examples for different use cases
2. Enhance scripts with additional metrics
3. Update templates with new patterns
4. Share optimization discoveries
5. Report issues or edge cases
