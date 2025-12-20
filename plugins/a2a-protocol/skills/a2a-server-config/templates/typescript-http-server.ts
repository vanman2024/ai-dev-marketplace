/**
 * A2A HTTP Server with Express
 * Provides HTTP transport for Agent-to-Agent communication following MCP standards.
 */

import express, { Request, Response } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';

dotenv.config();

// SECURITY: NEVER hardcode API keys - always use environment variables
const API_KEY = process.env.ANTHROPIC_API_KEY || 'your_anthropic_key_here';

const app = express();

// Middleware
app.use(express.json());
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
  credentials: true
}));

// Types
interface MessageRequest {
  content: string;
  agent_id?: string;
  context?: Record<string, any>;
}

interface MessageResponse {
  content: string;
  agent_id: string;
  status: string;
}

// Routes
app.get('/', (req: Request, res: Response) => {
  res.json({
    status: 'ok',
    server: 'A2A HTTP Server'
  });
});

app.get('/health', (req: Request, res: Response) => {
  res.json({
    status: 'healthy',
    transport: 'http',
    version: '1.0.0'
  });
});

app.post('/message', (req: Request, res: Response) => {
  /**
   * Handle A2A message exchange
   *
   * Example request:
   * {
   *   "content": "Hello from agent",
   *   "agent_id": "agent-1",
   *   "context": {"task": "greeting"}
   * }
   */
  const request: MessageRequest = req.body;

  // Process message here
  // This is where you'd integrate with your agent logic

  const response: MessageResponse = {
    content: `Received: ${request.content}`,
    agent_id: request.agent_id || 'server',
    status: 'success'
  };

  res.json(response);
});

// Start server
const PORT = process.env.PORT || 8000;
const HOST = process.env.HOST || '0.0.0.0';

app.listen(PORT, () => {
  console.log(`A2A HTTP Server running on http://${HOST}:${PORT}`);
});
