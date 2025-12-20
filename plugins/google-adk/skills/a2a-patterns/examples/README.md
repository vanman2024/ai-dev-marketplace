# A2A Pattern Examples

This directory contains complete, production-ready examples of multi-agent systems using the Agent-to-Agent (A2A) protocol with Google's Agent Development Kit (ADK).

## Examples Overview

### 1. Research Cluster (`research-cluster.py`)

**Use Case:** Automated research and report generation

**Architecture:**
- **Coordinator Agent**: Orchestrates research workflow
- **Search Agent**: Gathers information from multiple sources
- **Analysis Agent**: Evaluates and synthesizes findings
- **Writing Agent**: Creates polished reports

**Features:**
- Single topic research
- Parallel research across multiple topics
- Iterative deep-dive research
- Configurable depth (quick, standard, comprehensive)

**Run:**
```bash
python examples/research-cluster.py
```

**Environment Variables:**
```bash
USE_REMOTE_AGENTS=true
SEARCH_AGENT_URL=https://search-agent.example.com
ANALYSIS_AGENT_URL=https://analysis-agent.example.com
WRITING_AGENT_URL=https://writing-agent.example.com
```

### 2. E-Commerce Assistant (`ecommerce-assistant.py`)

**Use Case:** Customer service and order processing

**Architecture:**
- **Customer Agent**: Front-facing customer interaction
- **Inventory Agent**: Stock and availability management
- **Pricing Agent**: Price calculations and discounts
- **Payment Agent**: Payment processing

**Features:**
- Customer inquiry handling
- Complete order processing workflow
- Customer support issue resolution
- Multi-service coordination

**Run:**
```bash
python examples/ecommerce-assistant.py
```

**Environment Variables:**
```bash
USE_REMOTE_AGENTS=true
INVENTORY_AGENT_URL=https://inventory.example.com
PRICING_AGENT_URL=https://pricing.example.com
PAYMENT_AGENT_URL=https://payment.example.com
```

### 3. Code Review System (`code-review.py`)

**Use Case:** Automated code review and quality assurance

**Architecture:**
- **Review Manager**: Coordinates review process
- **Style Agent**: Checks code formatting and conventions
- **Security Agent**: Scans for vulnerabilities
- **Performance Agent**: Analyzes efficiency

**Features:**
- Multi-aspect code review
- Parallel review execution
- Automated fix suggestions
- Review report generation

**Run:**
```bash
python examples/code-review.py
```

### 4. Data Pipeline (`data-pipeline.py`)

**Use Case:** ETL and data processing workflows

**Architecture:**
- **Ingestion Agent**: Collects data from sources
- **Transformation Agent**: Processes and cleans data
- **Validation Agent**: Checks data quality
- **Storage Agent**: Persists results

**Features:**
- Sequential pipeline execution
- Error handling and retry logic
- Data quality validation
- Multiple storage backends

**Run:**
```bash
python examples/data-pipeline.py
```

## Running Examples

### Local Development (No A2A)

For local testing without deploying A2A services:

```bash
# Run with local agents (default)
python examples/research-cluster.py
```

The examples will use local ADK agents instead of remote A2A agents.

### Production (With A2A)

For production with deployed A2A services:

```bash
# Set environment variables
export USE_REMOTE_AGENTS=true
export SEARCH_AGENT_URL=https://search-agent-xyz.run.app
export ANALYSIS_AGENT_URL=https://analysis-agent-xyz.run.app
export WRITING_AGENT_URL=https://writing-agent-xyz.run.app

# Run with remote agents
python examples/research-cluster.py
```

## Deploying Example Agents as A2A Services

Each specialist agent can be deployed as an independent A2A service:

```bash
# Deploy search agent
cd agents/search-agent
bash ../../scripts/expose-agent.sh --agent-name search-agent --platform cloud-run

# Deploy analysis agent
cd agents/analysis-agent
bash ../../scripts/expose-agent.sh --agent-name analysis-agent --platform cloud-run

# Deploy writing agent
cd agents/writing-agent
bash ../../scripts/expose-agent.sh --agent-name writing-agent --platform cloud-run
```

After deployment, update environment variables with actual URLs.

## Architecture Patterns

### Pattern 1: Sequential Coordination

```
Coordinator → Agent 1 → Agent 2 → Agent 3 → Result
```

Used in: Data Pipeline

### Pattern 2: Parallel Execution

```
                ┌→ Agent 1 ┐
Coordinator → ├→ Agent 2 ├→ Aggregator → Result
                └→ Agent 3 ┘
```

Used in: Code Review, Parallel Research

### Pattern 3: Hierarchical

```
Coordinator
    ├→ Team Lead 1
    │   ├→ Specialist 1A
    │   └→ Specialist 1B
    └→ Team Lead 2
        ├→ Specialist 2A
        └→ Specialist 2B
```

Used in: Large-scale research clusters

### Pattern 4: Service-Oriented

```
Customer Agent ←→ Inventory Service
               ←→ Pricing Service
               ←→ Payment Service
```

Used in: E-Commerce Assistant

## Best Practices Demonstrated

1. **Error Handling**: All examples include try/catch and fallback logic
2. **Session Management**: Consistent session IDs for multi-turn interactions
3. **Parallel Execution**: Use `asyncio.gather()` for independent tasks
4. **Security**: Environment variables for credentials, no hardcoded secrets
5. **Monitoring**: Logging and status tracking throughout workflows
6. **Testing**: Local development mode for testing without A2A deployment

## Customization

Each example can be customized by:

1. **Modifying Agent Instructions**: Update prompts in agent definitions
2. **Adding Tools**: Integrate additional tools for each agent
3. **Changing Models**: Switch between Gemini models based on needs
4. **Adjusting Workflows**: Modify coordination logic in coordinator agents
5. **Adding Agents**: Extend with new specialist agents

## Testing

```bash
# Run all examples
bash scripts/run-all-examples.sh

# Run specific example
python examples/research-cluster.py

# Run with verbose logging
VERBOSE=true python examples/ecommerce-assistant.py
```

## Requirements

```bash
# Install dependencies
pip install google-adk[a2a]
pip install google-cloud-aiplatform
pip install asyncio

# Set up authentication
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account-key.json
export GOOGLE_CLOUD_PROJECT=your-project-id
```

## Troubleshooting

**Issue:** "Could not resolve agent card"
- Check agent URL is accessible
- Verify `/.well-known/agent.json` exists
- Check CORS configuration

**Issue:** "Connection refused"
- Ensure agent is deployed and running
- Verify firewall rules
- Check endpoint URL format

**Issue:** "Authentication failed"
- Verify service account has necessary permissions
- Check API keys and credentials
- Review security card configuration

## Resources

- [A2A Protocol Documentation](https://a2a-protocol.org/)
- [Google ADK Documentation](https://google.github.io/adk-docs/)
- [Agent Skills Best Practices](https://google.github.io/adk-docs/best-practices/)

## Contributing

To add new examples:

1. Create new Python file in `examples/`
2. Follow existing patterns and structure
3. Include comprehensive docstrings
4. Add environment variable documentation
5. Update this README with new example details
