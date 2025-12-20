/**
 * A2A WebSocket Server
 * Provides WebSocket transport for bidirectional real-time Agent-to-Agent communication.
 */

import express from 'express';
import { WebSocketServer, WebSocket } from 'ws';
import cors from 'cors';
import dotenv from 'dotenv';

dotenv.config();

// SECURITY: NEVER hardcode API keys - always use environment variables
const API_KEY = process.env.ANTHROPIC_API_KEY || 'your_anthropic_key_here';

const app = express();

// Middleware
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
  credentials: true
}));

// Types
interface WebSocketMessage {
  type: string;
  content?: string;
  agent_id?: string;
  [key: string]: any;
}

class ConnectionManager {
  private connections: Map<string, WebSocket> = new Map();

  connect(agentId: string, ws: WebSocket): void {
    this.connections.set(agentId, ws);
  }

  disconnect(agentId: string): void {
    this.connections.delete(agentId);
  }

  sendMessage(agentId: string, message: any): void {
    const ws = this.connections.get(agentId);
    if (ws && ws.readyState === WebSocket.OPEN) {
      ws.send(JSON.stringify(message));
    }
  }

  broadcast(message: any, exclude?: string): void {
    this.connections.forEach((ws, agentId) => {
      if (agentId !== exclude && ws.readyState === WebSocket.OPEN) {
        ws.send(JSON.stringify(message));
      }
    });
  }

  get count(): number {
    return this.connections.size;
  }
}

const manager = new ConnectionManager();

// HTTP Routes
app.get('/', (req, res) => {
  res.json({
    status: 'ok',
    server: 'A2A WebSocket Server',
    active_connections: manager.count
  });
});

// Start HTTP server
const PORT = parseInt(process.env.PORT || '8000');
const HOST = process.env.HOST || '0.0.0.0';

const server = app.listen(PORT, () => {
  console.log(`A2A HTTP Server running on http://${HOST}:${PORT}`);
});

// WebSocket server
const wss = new WebSocketServer({ server });

wss.on('connection', (ws: WebSocket, req) => {
  /**
   * WebSocket endpoint for bidirectional communication
   *
   * Client usage:
   *   const ws = new WebSocket('ws://localhost:8000/ws/agent-1');
   *   ws.onmessage = (event) => {
   *     const data = JSON.parse(event.data);
   *     console.log('Received:', data);
   *   };
   *   ws.send(JSON.stringify({type: 'message', content: 'Hello'}));
   */

  // Extract agent ID from URL path
  const urlPath = req.url || '';
  const match = urlPath.match(/\/ws\/([^/]+)/);
  const agentId = match ? match[1] : `agent-${Date.now()}`;

  // Register connection
  manager.connect(agentId, ws);

  // Send welcome message
  ws.send(JSON.stringify({
    type: 'connected',
    agent_id: agentId,
    message: `Connected as ${agentId}`
  }));

  // Handle incoming messages
  ws.on('message', (data: Buffer) => {
    try {
      const message: WebSocketMessage = JSON.parse(data.toString());
      const msgType = message.type || 'message';

      if (msgType === 'message') {
        // Process agent message
        const content = message.content || '';

        // Your agent logic here
        const response = {
          type: 'response',
          from: 'server',
          to: agentId,
          content: `Received: ${content}`
        };

        ws.send(JSON.stringify(response));

      } else if (msgType === 'broadcast') {
        // Broadcast to all other agents
        const broadcastMsg = {
          type: 'broadcast',
          from: agentId,
          content: message.content || ''
        };
        manager.broadcast(broadcastMsg, agentId);

      } else if (msgType === 'ping') {
        // Respond to ping
        ws.send(JSON.stringify({ type: 'pong' }));
      }

    } catch (error) {
      console.error('Error handling message:', error);
    }
  });

  // Handle disconnection
  ws.on('close', () => {
    manager.disconnect(agentId);

    // Notify other agents
    manager.broadcast({
      type: 'agent_disconnected',
      agent_id: agentId
    });

    console.log(`Agent ${agentId} disconnected`);
  });

  ws.on('error', (error) => {
    console.error('WebSocket error:', error);
  });
});

console.log(`A2A WebSocket Server running on ws://${HOST}:${PORT}/ws/{agent_id}`);
