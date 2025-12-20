/**
 * Peer-to-Peer Tool Sharing Pattern with A2A and MCP
 *
 * Architecture:
 * - Agents communicate as peers via A2A
 * - Each agent exposes its own MCP server
 * - Agents can request tools from each other
 * - Distributed tool access across agent network
 *
 * Use Case: Decentralized systems where agents have different capabilities
 */

import { Client as A2AClient, AgentCard, Task } from '@a2a/protocol';
import { Client as MCPClient, Server as MCPServer, Tool } from '@modelcontextprotocol/sdk';
import * as dotenv from 'dotenv';

dotenv.config();

interface PeerAgent {
  id: string;
  card: AgentCard;
  mcpEndpoint?: string;
}

class HybridPeerAgent {
  private a2aClient: A2AClient;
  private mcpServer: MCPServer;
  private mcpClient: MCPClient;
  private agentId: string;
  private peers: Map<string, PeerAgent> = new Map();
  private localTools: Map<string, Tool> = new Map();

  constructor(agentId: string) {
    this.agentId = agentId;

    // Initialize A2A client for peer communication
    this.a2aClient = new A2AClient({
      apiKey: process.env.A2A_API_KEY || '',
      baseUrl: process.env.A2A_BASE_URL || ''
    });

    // Initialize MCP server to expose local tools
    this.mcpServer = new MCPServer({
      name: `${agentId}-tools`,
      version: '1.0.0'
    });

    // Initialize MCP client for accessing peer tools
    this.mcpClient = new MCPClient();
  }

  /**
   * Register this agent and its tools with the A2A network
   */
  async register(): Promise<void> {
    // Start MCP server to expose local tools
    const mcpPort = await this.mcpServer.listen(0); // Dynamic port

    // Create agent card with MCP endpoint
    const card: AgentCard = {
      id: this.agentId,
      name: `Peer Agent ${this.agentId}`,
      version: '1.0.0',
      capabilities: {
        a2a: {
          enabled: true,
          protocols: ['peer_communication', 'tool_sharing']
        },
        mcp: {
          enabled: true,
          endpoint: `http://localhost:${mcpPort}`,
          tools: Array.from(this.localTools.keys())
        }
      }
    };

    // Register with A2A network
    await this.a2aClient.registerAgent(card);
    console.log(`Agent ${this.agentId} registered with MCP endpoint on port ${mcpPort}`);
  }

  /**
   * Discover peer agents in the network
   */
  async discoverPeers(): Promise<void> {
    console.log(`Discovering peer agents...`);

    const agents = await this.a2aClient.discoverAgents({
      capabilities: { mcp: { enabled: true } }
    });

    for (const agent of agents) {
      if (agent.id !== this.agentId) {
        this.peers.set(agent.id, {
          id: agent.id,
          card: agent,
          mcpEndpoint: agent.capabilities.mcp?.endpoint
        });
        console.log(`  Found peer: ${agent.name} with ${agent.capabilities.mcp?.tools?.length || 0} tools`);
      }
    }
  }

  /**
   * Add a local tool to this agent's MCP server
   */
  addLocalTool(name: string, description: string, handler: (params: any) => Promise<any>): void {
    const tool: Tool = {
      name,
      description,
      inputSchema: {
        type: 'object',
        properties: {}
      }
    };

    this.localTools.set(name, tool);
    this.mcpServer.registerTool(tool, handler);
    console.log(`Added local tool: ${name}`);
  }

  /**
   * Request a tool execution from a peer agent
   */
  async requestPeerTool(peerId: string, toolName: string, params: any): Promise<any> {
    const peer = this.peers.get(peerId);
    if (!peer) {
      throw new Error(`Peer not found: ${peerId}`);
    }

    console.log(`Requesting tool '${toolName}' from peer ${peerId}...`);

    // Send tool request via A2A
    const task: Task = {
      type: 'tool_execution',
      params: {
        tool: toolName,
        arguments: params
      },
      requesterId: this.agentId
    };

    const response = await this.a2aClient.sendTask(peerId, task);
    console.log(`  Tool result received from peer ${peerId}`);

    return response.result;
  }

  /**
   * Execute a local tool via MCP
   */
  async executeLocalTool(toolName: string, params: any): Promise<any> {
    if (!this.localTools.has(toolName)) {
      throw new Error(`Tool not found: ${toolName}`);
    }

    console.log(`Executing local tool: ${toolName}`);
    const result = await this.mcpServer.executeTool(toolName, params);
    return result;
  }

  /**
   * Find which peer has a specific tool
   */
  findPeerWithTool(toolName: string): PeerAgent | null {
    for (const peer of this.peers.values()) {
      const tools = peer.card.capabilities.mcp?.tools || [];
      if (tools.includes(toolName)) {
        return peer;
      }
    }
    return null;
  }

  /**
   * Execute a tool, whether local or from a peer
   */
  async executeTool(toolName: string, params: any): Promise<any> {
    // Try local tool first
    if (this.localTools.has(toolName)) {
      return await this.executeLocalTool(toolName, params);
    }

    // Find peer with the tool
    const peer = this.findPeerWithTool(toolName);
    if (!peer) {
      throw new Error(`Tool not available: ${toolName}`);
    }

    // Request from peer
    return await this.requestPeerTool(peer.id, toolName, params);
  }

  /**
   * Listen for incoming tool requests from peers
   */
  async listen(): Promise<void> {
    console.log(`Agent ${this.agentId} listening for peer requests...`);

    for await (const task of this.a2aClient.listen()) {
      try {
        if (task.type === 'tool_execution') {
          const { tool, arguments: args } = task.params;

          // Execute local tool
          const result = await this.executeLocalTool(tool, args);

          // Send result back via A2A
          await this.a2aClient.sendResult(task.id, result);
        }
      } catch (error) {
        await this.a2aClient.sendError(task.id, (error as Error).message);
      }
    }
  }
}

/**
 * Example usage: Peer-to-peer tool sharing network
 */
async function main() {
  // Create three peer agents
  const agent1 = new HybridPeerAgent('agent-search');
  const agent2 = new HybridPeerAgent('agent-analyze');
  const agent3 = new HybridPeerAgent('agent-storage');

  // Configure agent1 with search tools
  agent1.addLocalTool('web_search', 'Search the web', async (params) => {
    return { results: [`Searching for: ${params.query}`] };
  });

  // Configure agent2 with analysis tools
  agent2.addLocalTool('data_analysis', 'Analyze data', async (params) => {
    return { analysis: `Analyzed ${params.dataset}` };
  });

  // Configure agent3 with storage tools
  agent3.addLocalTool('save_data', 'Save data to storage', async (params) => {
    return { saved: true, id: '12345' };
  });

  // Register all agents
  await Promise.all([
    agent1.register(),
    agent2.register(),
    agent3.register()
  ]);

  // Discover peers
  await Promise.all([
    agent1.discoverPeers(),
    agent2.discoverPeers(),
    agent3.discoverPeers()
  ]);

  // Example: agent1 uses tools from all agents
  console.log('\n=== Example Workflow ===');

  // Agent1 uses its own search tool
  const searchResult = await agent1.executeTool('web_search', {
    query: 'renewable energy'
  });
  console.log('Search result:', searchResult);

  // Agent1 uses agent2's analysis tool
  const analysisResult = await agent1.executeTool('data_analysis', {
    dataset: 'renewable_energy_data'
  });
  console.log('Analysis result:', analysisResult);

  // Agent1 uses agent3's storage tool
  const storageResult = await agent1.executeTool('save_data', {
    data: analysisResult
  });
  console.log('Storage result:', storageResult);

  console.log('\n=== Workflow Complete ===');
}

if (require.main === module) {
  main().catch(console.error);
}

export { HybridPeerAgent };
