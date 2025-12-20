/**
 * Layered Protocol Stack Pattern
 *
 * Architecture:
 * - MCP at base layer for tool and resource access
 * - A2A at orchestration layer for agent coordination
 * - Application logic at top layer
 * - Clean separation of concerns with well-defined interfaces
 *
 * Use Case: Enterprise systems requiring protocol isolation and modularity
 */

import { Client as A2AClient, AgentCard, Task, Message } from '@a2a/protocol';
import { Client as MCPClient, Tool, Resource } from '@modelcontextprotocol/sdk';
import * as dotenv from 'dotenv';

dotenv.config();

/**
 * Layer 1: MCP Base Layer - Tool and Resource Access
 */
class MCPLayer {
  private client: MCPClient;
  private connectedServers: Map<string, MCPClient> = new Map();

  constructor() {
    this.client = new MCPClient({
      serverUrl: process.env.MCP_SERVER_URL || 'http://localhost:3000'
    });
  }

  async initialize(): Promise<void> {
    await this.client.connect();
    console.log('[MCP Layer] Initialized');
  }

  async connectServer(name: string, url: string): Promise<void> {
    const server = new MCPClient({ serverUrl: url });
    await server.connect();
    this.connectedServers.set(name, server);
    console.log(`[MCP Layer] Connected to server: ${name}`);
  }

  async executeTool(toolName: string, params: any): Promise<any> {
    console.log(`[MCP Layer] Executing tool: ${toolName}`);
    return await this.client.callTool(toolName, params);
  }

  async readResource(uri: string): Promise<any> {
    console.log(`[MCP Layer] Reading resource: ${uri}`);
    return await this.client.readResource(uri);
  }

  async listAvailableTools(): Promise<Tool[]> {
    return await this.client.listTools();
  }

  async listAvailableResources(): Promise<Resource[]> {
    return await this.client.listResources();
  }
}

/**
 * Layer 2: A2A Orchestration Layer - Agent Coordination
 */
class A2ALayer {
  private client: A2AClient;
  private agentId: string;
  private registeredAgents: Map<string, AgentCard> = new Map();

  constructor(agentId: string) {
    this.agentId = agentId;
    this.client = new A2AClient({
      apiKey: process.env.A2A_API_KEY || '',
      baseUrl: process.env.A2A_BASE_URL || ''
    });
  }

  async initialize(capabilities: any): Promise<void> {
    const card: AgentCard = {
      id: this.agentId,
      name: `Layered Agent ${this.agentId}`,
      version: '1.0.0',
      capabilities
    };

    await this.client.registerAgent(card);
    console.log(`[A2A Layer] Agent ${this.agentId} registered`);
  }

  async discoverAgents(filter?: any): Promise<AgentCard[]> {
    console.log('[A2A Layer] Discovering agents...');
    const agents = await this.client.discoverAgents(filter);

    for (const agent of agents) {
      if (agent.id !== this.agentId) {
        this.registeredAgents.set(agent.id, agent);
        console.log(`[A2A Layer]   Found: ${agent.name}`);
      }
    }

    return agents;
  }

  async delegateTask(agentId: string, task: Task): Promise<any> {
    console.log(`[A2A Layer] Delegating task to ${agentId}`);
    const response = await this.client.sendTask(agentId, task);
    return response.result;
  }

  async sendMessage(agentId: string, message: Message): Promise<void> {
    console.log(`[A2A Layer] Sending message to ${agentId}`);
    await this.client.sendMessage(agentId, message);
  }

  async receiveMessages(handler: (message: Message) => Promise<void>): Promise<void> {
    console.log('[A2A Layer] Listening for messages...');

    for await (const message of this.client.listen()) {
      await handler(message);
    }
  }
}

/**
 * Layer 3: Application Layer - Business Logic
 */
class ApplicationLayer {
  private mcpLayer: MCPLayer;
  private a2aLayer: A2ALayer;
  private agentId: string;

  constructor(agentId: string, mcpLayer: MCPLayer, a2aLayer: A2ALayer) {
    this.agentId = agentId;
    this.mcpLayer = mcpLayer;
    this.a2aLayer = a2aLayer;
  }

  /**
   * High-level business logic: Process a research request
   */
  async processResearchRequest(topic: string): Promise<any> {
    console.log(`\n[Application] Processing research request: ${topic}`);

    // Step 1: Use MCP to search for information
    const searchResults = await this.mcpLayer.executeTool('web_search', {
      query: topic
    });

    console.log(`[Application] Search completed, found ${searchResults.length} results`);

    // Step 2: Delegate analysis to specialized agent via A2A
    const analysisTask: Task = {
      type: 'analyze_research',
      params: {
        data: searchResults,
        topic
      },
      requesterId: this.agentId
    };

    const analysisAgent = await this.findAgentByRole('analyzer');
    if (!analysisAgent) {
      throw new Error('No analysis agent available');
    }

    const analysis = await this.a2aLayer.delegateTask(analysisAgent.id, analysisTask);
    console.log(`[Application] Analysis completed`);

    // Step 3: Use MCP to store results
    await this.mcpLayer.executeTool('database_write', {
      collection: 'research_results',
      data: {
        topic,
        searchResults,
        analysis,
        timestamp: new Date().toISOString()
      }
    });

    console.log(`[Application] Results stored`);

    return {
      topic,
      resultsCount: searchResults.length,
      analysis
    };
  }

  /**
   * High-level business logic: Collaborative document creation
   */
  async createCollaborativeDocument(title: string, sections: string[]): Promise<any> {
    console.log(`\n[Application] Creating collaborative document: ${title}`);

    const documentParts: any[] = [];

    // Distribute sections to different agents via A2A
    for (const section of sections) {
      const writerTask: Task = {
        type: 'write_section',
        params: {
          title: section,
          context: title
        },
        requesterId: this.agentId
      };

      const writer = await this.findAgentByRole('writer');
      if (writer) {
        const content = await this.a2aLayer.delegateTask(writer.id, writerTask);
        documentParts.push({ section, content });
      }
    }

    console.log(`[Application] All sections written`);

    // Use MCP to compile document
    const document = await this.mcpLayer.executeTool('document_compile', {
      title,
      parts: documentParts
    });

    // Store via MCP
    await this.mcpLayer.executeTool('database_write', {
      collection: 'documents',
      data: document
    });

    console.log(`[Application] Document compiled and stored`);

    return document;
  }

  /**
   * Helper: Find agent by role using A2A layer
   */
  private async findAgentByRole(role: string): Promise<AgentCard | null> {
    const agents = await this.a2aLayer.discoverAgents({
      capabilities: { role }
    });

    return agents.length > 0 ? agents[0] : null;
  }

  /**
   * Helper: Get available capabilities from both layers
   */
  async getAvailableCapabilities(): Promise<any> {
    const mcpTools = await this.mcpLayer.listAvailableTools();
    const mcpResources = await this.mcpLayer.listAvailableResources();
    const a2aAgents = await this.a2aLayer.discoverAgents();

    return {
      mcp: {
        tools: mcpTools.map(t => t.name),
        resources: mcpResources.map(r => r.uri)
      },
      a2a: {
        agents: a2aAgents.map(a => ({
          id: a.id,
          name: a.name,
          capabilities: a.capabilities
        }))
      }
    };
  }
}

/**
 * Main: Layered Stack Integration
 */
class LayeredAgent {
  private mcpLayer: MCPLayer;
  private a2aLayer: A2ALayer;
  private appLayer: ApplicationLayer;

  constructor(agentId: string) {
    // Initialize layers
    this.mcpLayer = new MCPLayer();
    this.a2aLayer = new A2ALayer(agentId);
    this.appLayer = new ApplicationLayer(agentId, this.mcpLayer, this.a2aLayer);
  }

  async initialize(): Promise<void> {
    console.log('=== Initializing Layered Agent Stack ===\n');

    // Initialize Layer 1: MCP
    await this.mcpLayer.initialize();

    // Initialize Layer 2: A2A
    await this.a2aLayer.initialize({
      role: 'coordinator',
      layers: ['mcp', 'a2a', 'application']
    });

    // Discover network
    await this.a2aLayer.discoverAgents();

    console.log('\n=== Initialization Complete ===\n');
  }

  async run(): Promise<void> {
    // Example 1: Research workflow
    const researchResult = await this.appLayer.processResearchRequest(
      'Renewable Energy Innovation 2025'
    );

    console.log('\nResearch Result:', researchResult);

    // Example 2: Collaborative document
    const document = await this.appLayer.createCollaborativeDocument(
      'Renewable Energy Report',
      ['Introduction', 'Current Technologies', 'Future Trends', 'Conclusion']
    );

    console.log('\nDocument Created:', document);

    // Show available capabilities
    const capabilities = await this.appLayer.getAvailableCapabilities();
    console.log('\n=== Available Capabilities ===');
    console.log('MCP Tools:', capabilities.mcp.tools);
    console.log('A2A Agents:', capabilities.a2a.agents.length);
  }
}

/**
 * Example usage
 */
async function main() {
  const agent = new LayeredAgent('layered-coordinator-001');

  await agent.initialize();
  await agent.run();
}

if (require.main === module) {
  main().catch(console.error);
}

export { LayeredAgent, MCPLayer, A2ALayer, ApplicationLayer };
