/**
 * A2A SSE (Server-Sent Events) Server
 * Provides SSE transport for real-time streaming Agent-to-Agent communication.
 */

import express, { Request, Response } from 'express';
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

// Routes
app.get('/', (req: Request, res: Response) => {
  res.json({
    status: 'ok',
    server: 'A2A SSE Server'
  });
});

app.get('/events', (req: Request, res: Response) => {
  /**
   * SSE endpoint for streaming events
   *
   * Client usage:
   *   const eventSource = new EventSource('http://localhost:8000/events');
   *   eventSource.onmessage = (event) => {
   *     console.log('Received:', event.data);
   *   };
   */

  // Set SSE headers
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');

  let counter = 0;

  const sendEvent = () => {
    counter++;

    // Your agent logic here - this is a simple counter example
    const data = {
      counter,
      message: `Agent update #${counter}`,
      timestamp: new Date().toISOString()
    };

    // Send SSE event
    res.write(`id: ${counter}\n`);
    res.write(`event: message\n`);
    res.write(`data: ${JSON.stringify(data)}\n\n`);

    // Stop after 10 events (remove this in production)
    if (counter >= 10) {
      res.write('event: complete\n');
      res.write('data: Stream completed\n\n');
      res.end();
      clearInterval(interval);
    }
  };

  // Send events every 2 seconds
  const interval = setInterval(sendEvent, 2000);

  // Clean up on client disconnect
  req.on('close', () => {
    clearInterval(interval);
    console.log('Client disconnected');
  });
});

app.get('/stream/:agent_id', (req: Request, res: Response) => {
  /**
   * Agent-specific event stream
   *
   * Example: GET /stream/agent-1
   */
  const agentId = req.params.agent_id;

  // Set SSE headers
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');

  let counter = 0;

  const sendEvent = () => {
    counter++;

    const data = {
      agent_id: agentId,
      counter,
      message: `Update from ${agentId}: ${counter}`
    };

    res.write(`id: ${agentId}-${counter}\n`);
    res.write(`event: agent_message\n`);
    res.write(`data: ${JSON.stringify(data)}\n\n`);

    if (counter >= 5) {
      res.end();
      clearInterval(interval);
    }
  };

  const interval = setInterval(sendEvent, 1000);

  req.on('close', () => {
    clearInterval(interval);
  });
});

// Start server
const PORT = process.env.PORT || 8000;
const HOST = process.env.HOST || '0.0.0.0';

app.listen(PORT, () => {
  console.log(`A2A SSE Server running on http://${HOST}:${PORT}`);
});
