/**
 * Basic Hybrid Agent Example - TypeScript
 *
 * Demonstrates a simple agent that uses both A2A and MCP protocols:
 * - A2A for communication with other agents
 * - MCP for accessing tools and resources
 * - Clean integration between both protocols
 *
 * Usage:
 *   ts-node examples/typescript-hybrid-agent.ts
 */

import * as dotenv from 'dotenv';

dotenv.config();

/**
 * Mock A2A Client (replace with actual SDK)
 */
class MockA2AClient {
  async registerAgent(card: any): Promise<void> {
    console.log(`✓ A2A: Registered agent ${card.id}`);
  }

  async *listen(): AsyncGenerator<any> {
    // Simulate receiving tasks
    const tasks = [
      { id: 'task-1', type: 'search', params: { query: 'blockchain trends' } },
      { id: 'task-2', type: 'analyze', params: { data: 'blockchain_data' } }
    ];

    for (const task of tasks) {
      yield task;
      await this.sleep(1000);
    }
  }

  async sendResult(taskId: string, result: any): Promise<void> {
    console.log(`✓ A2A: Sent result for task ${taskId}`);
  }

  private sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

/**
 * Mock MCP Client (replace with actual SDK)
 */
class MockMCPClient {
  async connect(): Promise<void> {
    console.log('✓ MCP: Connected to server');
  }

  async callTool(toolName: string, params: any): Promise<any> {
    console.log(`✓ MCP: Executing tool '${toolName}' with params`, params);

    // Simulate tool execution
    await new Promise(resolve => setTimeout(resolve, 500));

    return {
      status: 'success',
      data: `Result from ${toolName}`,
      timestamp: new Date().toISOString()
    };
  }

  async listTools(): Promise<string[]> {
    return ['web_search', 'data_analysis', 'database_write'];
  }
}

/**
 * Task interface
 */
interface Task {
  id: string;
  type: string;
  params: Record<string, any>;
}

/**
 * Agent Card interface
 */
interface AgentCard {
  id: string;
  name: string;
  version: string;
  capabilities: {
    a2a: { enabled: boolean };
    mcp: { enabled: boolean };
    taskTypes: string[];
  };
}

/**
 * Hybrid Agent combining A2A and MCP
 */
class HybridAgent {
  private agentId: string;
  private a2aClient: MockA2AClient;
  private mcpClient: MockMCPClient;
  private taskToToolMapping: Map<string, string>;

  constructor(agentId: string) {
    this.agentId = agentId;

    // Initialize A2A client
    this.a2aClient = new MockA2AClient();
    // In production: this.a2aClient = new A2AClient({ apiKey: process.env.A2A_API_KEY });

    // Initialize MCP client
    this.mcpClient = new MockMCPClient();
    // In production: this.mcpClient = new MCPClient({ serverUrl: process.env.MCP_SERVER_URL });

    // Configure task-to-tool mapping
    this.taskToToolMapping = new Map([
      ['search', 'web_search'],
      ['analyze', 'data_analysis'],
      ['store', 'database_write']
    ]);
  }

  /**
   * Initialize the hybrid agent
   */
  async initialize(): Promise<void> {
    console.log(`\n=== Initializing Hybrid Agent ${this.agentId} ===\n`);

    // Create agent card
    const card: AgentCard = {
      id: this.agentId,
      name: `Hybrid Agent ${this.agentId}`,
      version: '1.0.0',
      capabilities: {
        a2a: { enabled: true },
        mcp: { enabled: true },
        taskTypes: Array.from(this.taskToToolMapping.keys())
      }
    };

    // Register with A2A network
    await this.a2aClient.registerAgent(card);

    // Connect to MCP server
    await this.mcpClient.connect();

    // List available MCP tools
    const tools = await this.mcpClient.listTools();
    console.log(`✓ MCP: Available tools: ${tools.join(', ')}`);

    console.log('\n✓ Agent initialized successfully\n');
  }

  /**
   * Execute a task received via A2A using MCP tools
   */
  async executeTask(task: Task): Promise<any> {
    console.log(`Processing task ${task.id} (type: ${task.type})`);

    // Map A2A task type to MCP tool name
    const toolName = this.taskToToolMapping.get(task.type);

    if (!toolName) {
      throw new Error(`Unknown task type: ${task.type}`);
    }

    // Execute via MCP
    const result = await this.mcpClient.callTool(toolName, task.params);

    console.log(`✓ Task ${task.id} completed\n`);

    return result;
  }

  /**
   * Main agent loop: listen for tasks and execute them
   */
  async run(): Promise<void> {
    console.log('=== Agent Running ===\n');
    console.log('Listening for tasks via A2A...\n');

    // Listen for incoming tasks via A2A
    for await (const task of this.a2aClient.listen()) {
      try {
        // Execute task using MCP tools
        const result = await this.executeTask(task);

        // Send result back via A2A
        await this.a2aClient.sendResult(task.id, result);

      } catch (error) {
        console.error(`✗ Error processing task ${task.id}:`, error);
      }
    }
  }
}

/**
 * Main function
 */
async function main() {
  console.log('╔════════════════════════════════════════════╗');
  console.log('║   Hybrid Agent Example (TypeScript)      ║');
  console.log('║   A2A + MCP Integration                   ║');
  console.log('╚════════════════════════════════════════════╝\n');

  // Create and initialize agent
  const agent = new HybridAgent('hybrid-ts-001');
  await agent.initialize();

  // Run agent (will process simulated tasks)
  await agent.run();

  console.log('\n=== Example Complete ===');
  console.log('\nThis example demonstrates:');
  console.log('  1. Agent registration via A2A');
  console.log('  2. MCP server connection and tool discovery');
  console.log('  3. Task reception via A2A protocol');
  console.log('  4. Tool execution via MCP protocol');
  console.log('  5. Result delivery back via A2A');
  console.log('\nIntegration Pattern:');
  console.log('  A2A Task → Task Mapping → MCP Tool → Result → A2A Response');
  console.log('\nNext steps:');
  console.log('  - Configure .env with actual API keys');
  console.log('  - Replace mock clients with real A2A and MCP SDKs');
  console.log('  - Customize task-to-tool mapping for your use case');
  console.log('  - Add comprehensive error handling');
  console.log('  - Implement logging and monitoring');
}

// Run if executed directly
if (require.main === module) {
  main().catch(console.error);
}

export { HybridAgent };
