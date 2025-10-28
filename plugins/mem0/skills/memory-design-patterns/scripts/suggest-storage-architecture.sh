#!/bin/bash
# Recommend storage architecture (vector vs graph) based on project requirements
# Usage: ./suggest-storage-architecture.sh "<project_description>"

set -e

PROJECT_DESC="${1}"

if [ -z "$PROJECT_DESC" ]; then
    echo "Storage Architecture Advisor"
    echo "============================"
    echo ""
    echo "Describe your project, and I'll recommend the optimal storage architecture."
    echo ""
    echo "Usage: $0 \"<project_description>\""
    echo ""
    echo "Examples:"
    echo "  $0 \"chatbot that remembers user preferences\""
    echo "  $0 \"team collaboration tool with org hierarchies\""
    echo "  $0 \"knowledge management system with entity relationships\""
    echo ""
    read -p "Enter your project description: " PROJECT_DESC
fi

echo ""
echo "Analyzing project: $PROJECT_DESC"
echo "=================================="
echo ""

# Convert to lowercase for pattern matching
PROJECT_LOWER=$(echo "$PROJECT_DESC" | tr '[:upper:]' '[:lower:]')

# Scoring system
VECTOR_SCORE=0
GRAPH_SCORE=0

# Vector indicators
if echo "$PROJECT_LOWER" | grep -qE "simple|preference|basic|chatbot|recommendation|search"; then
    VECTOR_SCORE=$((VECTOR_SCORE + 3))
fi

if echo "$PROJECT_LOWER" | grep -qE "semantic|similar|relevant|match|find"; then
    VECTOR_SCORE=$((VECTOR_SCORE + 2))
fi

if echo "$PROJECT_LOWER" | grep -qE "prototype|mvp|quick|simple"; then
    VECTOR_SCORE=$((VECTOR_SCORE + 2))
fi

# Graph indicators
if echo "$PROJECT_LOWER" | grep -qE "relationship|connection|link|network|graph|hierarchy|org|team"; then
    GRAPH_SCORE=$((GRAPH_SCORE + 4))
fi

if echo "$PROJECT_LOWER" | grep -qE "entity|knowledge|complex|multi|traverse|path"; then
    GRAPH_SCORE=$((GRAPH_SCORE + 3))
fi

if echo "$PROJECT_LOWER" | grep -qE "enterprise|organization|department|role"; then
    GRAPH_SCORE=$((GRAPH_SCORE + 3))
fi

if echo "$PROJECT_LOWER" | grep -qE "social|collaborate|connect|friend|follow"; then
    GRAPH_SCORE=$((GRAPH_SCORE + 2))
fi

# Determine recommendation
if [ $GRAPH_SCORE -gt $((VECTOR_SCORE + 3)) ]; then
    RECOMMENDATION="graph"
    CONFIDENCE="high"
elif [ $GRAPH_SCORE -gt $VECTOR_SCORE ]; then
    RECOMMENDATION="hybrid"
    CONFIDENCE="medium"
elif [ $VECTOR_SCORE -gt $((GRAPH_SCORE + 2)) ]; then
    RECOMMENDATION="vector"
    CONFIDENCE="high"
else
    RECOMMENDATION="vector"
    CONFIDENCE="medium"
fi

# Display recommendation
echo "RECOMMENDATION:"
echo "==============="
echo "Suggested Architecture: ${RECOMMENDATION^^}"
echo "Confidence: $CONFIDENCE"
echo ""
echo "Scoring:"
echo "  Vector Score: $VECTOR_SCORE"
echo "  Graph Score: $GRAPH_SCORE"
echo ""

# Display architecture details
case "$RECOMMENDATION" in
    vector)
        echo "VECTOR MEMORY Architecture"
        echo "=========================="
        echo ""
        echo "Why Vector Memory?"
        echo "-------------------"
        echo "✓ Your use case focuses on semantic search and preferences"
        echo "✓ No complex entity relationships detected"
        echo "✓ Vector-only provides faster setup and lower complexity"
        echo ""
        echo "Strengths:"
        echo "  • Fast semantic similarity search"
        echo "  • Excellent for unstructured data"
        echo "  • Low infrastructure complexity"
        echo "  • Works out-of-the-box with Mem0"
        echo "  • Lower cost for small-medium scale"
        echo ""
        echo "Limitations:"
        echo "  ✗ Cannot query explicit relationships"
        echo "  ✗ No entity connection reasoning"
        echo "  ✗ Limited multi-hop traversal"
        echo ""
        echo "Implementation:"
        cat <<'EOF'
from mem0 import Memory

# Default vector-only configuration
memory = Memory()

# Add memories
memory.add("User prefers concise responses", user_id="alice")

# Semantic search
results = memory.search("communication style", user_id="alice")
EOF
        echo ""
        echo "Infrastructure:"
        echo "  • Vector DB: Qdrant (default) or Pinecone"
        echo "  • Embeddings: OpenAI text-embedding-3-small"
        echo "  • Cost: ~\$0.50-5/month for 10k memories"
        ;;

    graph)
        echo "GRAPH MEMORY Architecture"
        echo "========================="
        echo ""
        echo "Why Graph Memory?"
        echo "------------------"
        echo "✓ Your use case involves complex entity relationships"
        echo "✓ Need for relationship traversal and multi-hop queries"
        echo "✓ Graph enables rich context and reasoning"
        echo ""
        echo "Strengths:"
        echo "  • Explicit entity relationships"
        echo "  • Complex query capabilities"
        echo "  • Multi-hop traversal"
        echo "  • Relationship reasoning"
        echo "  • Perfect for knowledge graphs"
        echo ""
        echo "Limitations:"
        echo "  ✗ Requires graph database setup (Neo4j/Memgraph)"
        echo "  ✗ Higher infrastructure complexity"
        echo "  ✗ Slower for pure semantic search"
        echo "  ✗ Higher cost and maintenance"
        echo ""
        echo "Implementation:"
        cat <<'EOF'
from mem0 import Memory
from mem0.configs.base import MemoryConfig

config = MemoryConfig(
    graph_store={
        "provider": "neo4j",
        "config": {
            "url": "bolt://localhost:7687",
            "username": "neo4j",
            "password": "password"
        }
    }
)
memory = Memory(config)

# Add with relationship extraction
result = memory.add(
    "Alice works with Bob on DataPipeline project",
    user_id="system"
)

# Returns memories + relationships
print(result["relations"])
# [{'source': 'Alice', 'relationship': 'WORKS_WITH', 'target': 'Bob'}]
EOF
        echo ""
        echo "Infrastructure:"
        echo "  • Graph DB: Neo4j or Memgraph"
        echo "  • Vector DB: Still needed for semantic search"
        echo "  • Embeddings: OpenAI text-embedding-3-small"
        echo "  • Cost: ~\$20-100/month (includes graph DB hosting)"
        ;;

    hybrid)
        echo "HYBRID Architecture (Vector + Graph)"
        echo "===================================="
        echo ""
        echo "Why Hybrid?"
        echo "-----------"
        echo "✓ Your use case has elements of both semantic search and relationships"
        echo "✓ Hybrid provides best of both worlds"
        echo "✓ Start with vector, add graph as relationships emerge"
        echo ""
        echo "Recommendation:"
        echo "  Phase 1: Start with VECTOR memory"
        echo "  Phase 2: Add GRAPH when relationship needs are clear"
        echo "  Phase 3: Optimize based on actual usage patterns"
        echo ""
        echo "Benefits:"
        echo "  • Progressive complexity (start simple)"
        echo "  • Validate needs before graph investment"
        echo "  • Lower initial cost"
        echo "  • Easier migration path"
        echo ""
        echo "Implementation Strategy:"
        cat <<'EOF'
# Phase 1: Vector-only (MVP)
from mem0 import Memory
memory = Memory()

# Phase 2: Add graph when needed
from mem0.configs.base import MemoryConfig
config = MemoryConfig(
    graph_store={
        "provider": "neo4j",
        "config": {...}
    }
)
memory = Memory(config)

# Use vector for semantic search
# Use graph for relationship queries
EOF
        echo ""
        echo "Migration Path:"
        echo "  1. Start with vector-only (weeks 1-4)"
        echo "  2. Monitor for relationship patterns"
        echo "  3. Set up graph DB (week 5)"
        echo "  4. Migrate relationship-heavy data"
        echo "  5. Optimize based on performance metrics"
        ;;
esac

echo ""
echo "Decision Matrix:"
echo "----------------"
cat <<'EOF'
┌─────────────────────────────────────────────────┐
│         VECTOR    │    GRAPH    │    HYBRID     │
├─────────────────────────────────────────────────┤
│ Setup     Fast    │    Slow     │    Medium     │
│ Cost      Low     │    High     │    Medium     │
│ Semantic  ★★★★★  │    ★★★☆☆   │    ★★★★★     │
│ Relations ★☆☆☆☆  │    ★★★★★   │    ★★★★☆     │
│ Complexity Low   │    High     │    Medium     │
└─────────────────────────────────────────────────┘

Use Cases:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Vector:  Preferences, basic chatbot, recommendations
Graph:   Knowledge graphs, org hierarchies, social
Hybrid:  Customer support, team tools, multi-tenant
EOF

echo ""
echo ""
echo "Scale Considerations:"
echo "---------------------"

cat <<'EOF'
Memory Volume      | Recommended Architecture
─────────────────────────────────────────────────
< 1,000 memories   | Vector (start simple)
1k - 10k memories  | Vector (unless relationships needed)
10k - 100k         | Vector or Hybrid
> 100k memories    | Hybrid or Graph (depends on queries)

Relationship Density | Recommended Architecture
─────────────────────────────────────────────────
No relationships   | Vector only
Few relationships  | Vector (start), add graph later
Many relationships | Graph or Hybrid
Complex reasoning  | Graph required
EOF

echo ""
echo ""
echo "Cost Comparison (10k memories):"
echo "--------------------------------"
echo "Vector:  \$1-5/month   (vector DB + embeddings)"
echo "Graph:   \$20-100/month (+ graph DB hosting)"
echo "Hybrid:  \$25-120/month (both systems)"
echo ""

echo "Next Steps:"
echo "-----------"
echo "1. Review the recommendation and decision matrix"
echo "2. Consider starting with Vector for MVP"
echo "3. Use the provided implementation code"
echo "4. Monitor relationship patterns in production"
echo "5. Migrate to Graph if relationships become critical"
echo "6. See templates/ directory for complete configs"
echo ""

if [ "$CONFIDENCE" = "medium" ]; then
    echo "ℹ️  Confidence is MEDIUM. Consider:"
    echo "   • Starting with Vector and monitoring for relationship patterns"
    echo "   • Reviewing the hybrid approach for flexibility"
    echo "   • Consulting the decision matrix for your specific scale"
fi

echo ""
echo "For more details:"
echo "  • Vector config: templates/vector-only-config.py"
echo "  • Graph config: templates/graph-memory-config.py"
echo "  • Hybrid config: templates/hybrid-architecture.py"
