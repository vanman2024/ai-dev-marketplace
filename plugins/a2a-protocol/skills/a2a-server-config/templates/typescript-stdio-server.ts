/**
 * A2A STDIO Server
 * Provides STDIO transport for local Agent-to-Agent communication following MCP standards.
 */

import * as readline from 'readline';
import dotenv from 'dotenv';

dotenv.config();

// SECURITY: NEVER hardcode API keys - always use environment variables
const API_KEY = process.env.ANTHROPIC_API_KEY || 'your_anthropic_key_here';

// Types
interface JsonRpcRequest {
  jsonrpc: string;
  method: string;
  params?: Record<string, any>;
  id: number | string;
}

interface JsonRpcResponse {
  jsonrpc: string;
  result?: any;
  error?: {
    code: number;
    message: string;
  };
  id: number | string;
}

class StdioServer {
  private running: boolean = true;

  handleMessage(message: JsonRpcRequest): JsonRpcResponse {
    /**
     * Handle incoming A2A message
     *
     * Expected format (JSON-RPC):
     * {
     *   "jsonrpc": "2.0",
     *   "method": "message",
     *   "params": {
     *     "content": "Hello",
     *     "agent_id": "agent-1"
     *   },
     *   "id": 1
     * }
     */
    const { method, params, id } = message;

    if (method === 'message') {
      // Process the message
      const content = params?.content || '';
      const agent_id = params?.agent_id || 'unknown';

      // Your agent logic here
      const responseContent = `Received from ${agent_id}: ${content}`;

      return {
        jsonrpc: '2.0',
        result: {
          content: responseContent,
          status: 'success'
        },
        id
      };
    }

    if (method === 'ping') {
      return {
        jsonrpc: '2.0',
        result: { pong: true },
        id
      };
    }

    return {
      jsonrpc: '2.0',
      error: {
        code: -32601,
        message: `Method not found: ${method}`
      },
      id
    };
  }

  run(): void {
    /**
     * Main STDIO loop - reads from stdin, writes to stdout
     */
    console.error('A2A STDIO Server started');

    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout,
      terminal: false
    });

    rl.on('line', (line: string) => {
      try {
        // Parse JSON-RPC request
        const request: JsonRpcRequest = JSON.parse(line);

        // Handle request
        const response = this.handleMessage(request);

        // Write JSON-RPC response to stdout
        console.log(JSON.stringify(response));

      } catch (error) {
        if (error instanceof SyntaxError) {
          console.error(`Invalid JSON: ${error.message}`);
        } else {
          console.error(`Error: ${error}`);
        }
      }
    });

    rl.on('close', () => {
      console.error('Server stopped');
      this.running = false;
    });
  }
}

// Start server
const server = new StdioServer();
server.run();
