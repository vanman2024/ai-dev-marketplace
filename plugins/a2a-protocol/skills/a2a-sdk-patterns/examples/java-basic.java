/**
 * A2A Protocol Java SDK - Basic Usage Example
 * Demonstrates basic client setup and API operations
 */

package com.example.a2a;

import com.a2a.protocol.A2AClient;
import com.a2a.protocol.models.Agent;
import com.a2a.protocol.models.Message;
import com.a2a.protocol.models.SendMessageRequest;
import com.a2a.protocol.exceptions.A2AException;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class BasicExample {

    public static void main(String[] args) {
        // Load API key from environment
        String apiKey = System.getenv("A2A_API_KEY");
        if (apiKey == null || apiKey.isEmpty()) {
            System.err.println("A2A_API_KEY environment variable is required");
            System.exit(1);
        }

        // Initialize client
        A2AClient client = A2AClient.builder()
                .apiKey(apiKey)
                .baseUrl(System.getenv().getOrDefault(
                    "A2A_BASE_URL",
                    "https://api.a2a.example.com"
                ))
                .timeout(30)
                .retryAttempts(3)
                .build();

        try {
            // Example: Send a message to another agent
            Map<String, Object> messageData = new HashMap<>();
            messageData.put("type", "request");
            messageData.put("action", "process_data");

            Map<String, Object> data = new HashMap<>();
            data.put("input", "sample data");
            messageData.put("data", data);

            SendMessageRequest request = SendMessageRequest.builder()
                    .recipientId("agent-123")
                    .message(messageData)
                    .build();

            Message response = client.sendMessage(request);
            System.out.println("Message sent successfully!");
            System.out.println("Response: " + response);

            // Example: Get agent status
            Agent agent = client.getAgentStatus("agent-123");
            System.out.println("\nAgent status: " + agent);

            // Example: List available agents
            List<Agent> agents = client.listAgents(10, 0);
            System.out.println("\nAvailable agents:");
            for (Agent a : agents) {
                System.out.printf("  - %s: %s (%s)%n",
                    a.getId(), a.getName(), a.getStatus());
            }

        } catch (A2AException e) {
            System.err.println("A2A Error: " + e.getMessage());
            System.err.println("Error code: " + e.getErrorCode());
            System.exit(1);
        } finally {
            // Clean up resources
            client.close();
        }
    }
}
