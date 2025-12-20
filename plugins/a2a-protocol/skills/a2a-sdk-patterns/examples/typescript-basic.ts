#!/usr/bin/env node
/**
 * A2A Protocol TypeScript SDK - Basic Usage Example
 * Demonstrates basic client setup and API operations
 */

import { A2AClient, A2AError } from '@a2a/protocol';

async function main(): Promise<number> {
    // Load API key from environment
    const apiKey = process.env.A2A_API_KEY;
    if (!apiKey) {
        throw new Error('A2A_API_KEY environment variable is required');
    }

    // Initialize client
    const client = new A2AClient({
        apiKey,
        baseUrl: process.env.A2A_BASE_URL || 'https://api.a2a.example.com',
        timeout: 30000,
        retryAttempts: 3,
    });

    try {
        // Example: Send a message to another agent
        const response = await client.sendMessage({
            recipientId: 'agent-123',
            message: {
                type: 'request',
                action: 'process_data',
                data: {
                    input: 'sample data',
                },
            },
        });

        console.log('Message sent successfully!');
        console.log('Response:', response);

        // Example: Get agent status
        const status = await client.getAgentStatus('agent-123');
        console.log('\nAgent status:', status);

        // Example: List available agents
        const agents = await client.listAgents({ limit: 10 });
        console.log('\nAvailable agents:');
        for (const agent of agents) {
            console.log(`  - ${agent.id}: ${agent.name} (${agent.status})`);
        }

        return 0;
    } catch (error) {
        if (error instanceof A2AError) {
            console.error('A2A Error:', error.message);
            console.error('Error code:', error.code);
        } else {
            console.error('Unexpected error:', error);
        }
        return 1;
    }
}

// Run the example
main()
    .then((exitCode) => process.exit(exitCode))
    .catch((error) => {
        console.error('Fatal error:', error);
        process.exit(1);
    });
